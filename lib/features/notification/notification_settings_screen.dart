import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../data/repositories/notification_repository.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  bool _rfqBids = true;
  bool _contractUpdates = true;
  bool _deliveryAlerts = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      bool rfq = prefs.getBool('notif_rfq_bids') ?? true;
      bool contracts = prefs.getBool('notif_contract_updates') ?? true;
      bool delivery = prefs.getBool('notif_delivery_alerts') ?? true;
      bool promo = prefs.getBool('notif_promotions') ?? false;

      // Try syncing from backend preferences if available
      try {
        final notifRepo = ref.read(notificationRepositoryProvider);
        final remotePrefs = await notifRepo.getPreferences();
        if (remotePrefs.isNotEmpty) {
          if (remotePrefs.containsKey('rfqBids')) rfq = remotePrefs['rfqBids'] == true;
          if (remotePrefs.containsKey('contractUpdates')) contracts = remotePrefs['contractUpdates'] == true;
          if (remotePrefs.containsKey('deliveryAlerts')) delivery = remotePrefs['deliveryAlerts'] == true;
          if (remotePrefs.containsKey('promotions')) promo = remotePrefs['promotions'] == true;
        }
      } catch (_) {
        // Fall back gracefully to local preferences
      }

      if (mounted) {
        setState(() {
          _rfqBids = rfq;
          _contractUpdates = contracts;
          _deliveryAlerts = delivery;
          _promotions = promo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _updateSetting({
    bool? rfqBids,
    bool? contractUpdates,
    bool? deliveryAlerts,
    bool? promotions,
  }) async {
    final newRfq = rfqBids ?? _rfqBids;
    final newContracts = contractUpdates ?? _contractUpdates;
    final newDelivery = deliveryAlerts ?? _deliveryAlerts;
    final newPromotions = promotions ?? _promotions;

    setState(() {
      _rfqBids = newRfq;
      _contractUpdates = newContracts;
      _deliveryAlerts = newDelivery;
      _promotions = newPromotions;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_rfq_bids', newRfq);
      await prefs.setBool('notif_contract_updates', newContracts);
      await prefs.setBool('notif_delivery_alerts', newDelivery);
      await prefs.setBool('notif_promotions', newPromotions);

      // Fire & forget remote preference update
      try {
        final notifRepo = ref.read(notificationRepositoryProvider);
        await notifRepo.updatePreferences({
          'rfqBids': newRfq,
          'contractUpdates': newContracts,
          'deliveryAlerts': newDelivery,
          'promotions': newPromotions,
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật cài đặt thông báo.'),
            duration: Duration(milliseconds: 1500),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu cài đặt: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Cài Đặt Thông Báo', showBack: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang tải cấu hình thông báo...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                'Không thể tải cài đặt thông báo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              CustomButton(
                title: 'Thử lại',
                variant: ButtonVariant.primary,
                size: ButtonSize.medium,
                onPress: _loadSettings,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.shadowSubtle,
          ),
          child: Column(
            children: [
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  value: _rfqBids,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('Báo giá mới từ xưởng sản xuất', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Nhận thông báo khi có xưởng nộp hồ sơ đấu thầu RFQ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => _updateSetting(rfqBids: val),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  value: _contractUpdates,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('Hợp đồng & Đặt cọc ký quỹ', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Thông báo ký số và tiến độ giải ngân ký quỹ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => _updateSetting(contractUpdates: val),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  value: _deliveryAlerts,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('Hành trình xe lạnh & PoD', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Cảnh báo nhiệt độ và chuẩn bị nhận hàng', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => _updateSetting(deliveryAlerts: val),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  value: _promotions,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  title: const Text('Ưu đãi mùa vụ 2026', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Các chương trình chiết khấu thêm theo đợt đặt hàng sớm', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  onChanged: (val) => _updateSetting(promotions: val),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
