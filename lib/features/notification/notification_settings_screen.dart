import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/notification_repository.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';

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
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Cài đặt thông báo', showBack: true),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeleton();
    }

    if (_errorMessage != null) {
      return Center(
        child: AppErrorState(
          title: 'Chưa tải được cài đặt thông báo',
          message: _errorMessage,
          retryLabel: 'Thử lại',
          onRetry: _loadSettings,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.spaceMD),
          child: Text(
            'Tuỳ chọn nhận thông báo',
            style: AppTokens.titleMd.copyWith(
              color: AppColors.primaryDark,
              fontSize: 14,
            ),
          ),
        ),

        // Settings Card with proper Material surface (no DecoratedBox warning)
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            side: const BorderSide(color: AppColors.border, width: 0.8),
          ),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SwitchListTile(
                value: _rfqBids,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceLG,
                  vertical: AppTokens.spaceXS,
                ),
                title: const Text(
                  'Báo giá mới từ xưởng',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Nhận thông báo khi có xưởng gửi báo giá',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: (val) => _updateSetting(rfqBids: val),
              ),
              const Divider(height: 1, color: AppColors.border),
              SwitchListTile(
                value: _contractUpdates,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceLG,
                  vertical: AppTokens.spaceXS,
                ),
                title: const Text(
                  'Hợp đồng & đặt cọc',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Thông báo ký hợp đồng và các đợt thanh toán',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: (val) => _updateSetting(contractUpdates: val),
              ),
              const Divider(height: 1, color: AppColors.border),
              SwitchListTile(
                value: _deliveryAlerts,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceLG,
                  vertical: AppTokens.spaceXS,
                ),
                title: const Text(
                  'Tiến độ giao hàng',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Cập nhật tình trạng giao nhận đơn hàng',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: (val) => _updateSetting(deliveryAlerts: val),
              ),
              const Divider(height: 1, color: AppColors.border),
              SwitchListTile(
                value: _promotions,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primaryLight.withValues(alpha: 0.35),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceLG,
                  vertical: AppTokens.spaceXS,
                ),
                title: const Text(
                  'Ưu đãi mùa vụ 2026',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  'Chương trình chiết khấu thêm theo đợt đặt hàng sớm',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onChanged: (val) => _updateSetting(promotions: val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return AppSkeleton.shimmer(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSkeleton(width: 220, height: 16),
            const SizedBox(height: AppTokens.spaceLG),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: List.generate(
                  4,
                  (index) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppTokens.spaceLG),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSkeleton(width: 160, height: 14),
                                  SizedBox(height: AppTokens.spaceSM),
                                  AppSkeleton(width: 220, height: 12),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTokens.spaceMD),
                            const AppSkeleton(
                              width: 44,
                              height: 24,
                              borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusPill)),
                            ),
                          ],
                        ),
                      ),
                      if (index < 3) const Divider(height: 1, color: AppColors.border),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
