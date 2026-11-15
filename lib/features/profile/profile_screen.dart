import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/rfq_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoadingStats = true;
  String? _statsError;
  int _orderCount = 0;
  int _rfqCount = 0;
  int _boxCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _orderCount = 0;
          _rfqCount = 0;
          _boxCount = 0;
          _statsError = null;
        });
      }
      return;
    }

    setState(() {
      _isLoadingStats = true;
      _statsError = null;
    });

    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final rfqRepo = ref.read(rfqRepositoryProvider);

      final results = await Future.wait([
        orderRepo.getMyOrders(),
        rfqRepo.getMyRfqs(),
      ]);

      final orders = results[0] as List<dynamic>;
      final rfqs = results[1] as List<dynamic>;

      int calculatedBoxes = 0;
      for (final o in orders) {
        final items = (o as dynamic).items as List<dynamic>? ?? [];
        for (final it in items) {
          calculatedBoxes += (it.quantity as num?)?.toInt() ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          _orderCount = orders.length;
          _rfqCount = rfqs.length;
          _boxCount = calculatedBoxes;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          _statsError = 'Không thể nạp số liệu thống kê';
        });
      }
    }
  }

  void _showSupplierRegistrationDialog(BuildContext context) {
    const supplierUrl = 'https://nguyetpho.vn/supplier/register';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          title: const Row(
            children: [
              Icon(Icons.storefront_outlined, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đăng Ký Nhà Cung Cấp',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Để đảm bảo tiêu chuẩn ATTP (HACCP/ISO) và năng lực sản xuất sỉ của Nguyệt Phố Hoàng Gia, quy trình đăng ký xưởng bánh & thẩm định năng lực được thực hiện trực tiếp trên cổng thông tin đối tác Website B2B.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                  border: Border.all(color: AppColors.border),
                ),
                child: const SelectableText(
                  supplierUrl,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      title: 'Sao chép liên kết',
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.textWhite),
                      size: ButtonSize.medium,
                      onPress: () {
                        Clipboard.setData(const ClipboardData(text: supplierUrl));
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép liên kết đăng ký nhà cung cấp!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Tài Khoản Doanh Nghiệp',
        showBack: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowCard,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? (authState.isAuthenticated ? 'Khách hàng Hoàng Gia' : 'Khách vãng lai'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.companyName ?? (authState.isAuthenticated ? 'Doanh nghiệp B2B' : 'Chưa đăng nhập'),
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.phoneNumber ?? user?.email ?? 'Chưa cập nhật liên hệ',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (authState.isAuthenticated)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                        tooltip: 'Chỉnh sửa hồ sơ',
                        onPressed: () => context.push('/edit-profile').then((_) => _loadStats()),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Metrics Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: _isLoadingStats
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            value: '$_orderCount',
                            label: 'Đơn hàng',
                            hasError: _statsError != null,
                          ),
                          _StatItem(
                            value: '$_rfqCount',
                            label: 'Yêu cầu RFQ',
                            hasError: _statsError != null,
                          ),
                          _StatItem(
                            value: '$_boxCount',
                            label: 'Hộp đã đặt',
                            hasError: _statsError != null,
                          ),
                        ],
                      ),
              ),
              if (_statsError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '$_statsError. Kéo xuống để tải lại.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 16),

              // Navigation Menu
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.assignment_outlined,
                      title: 'Quản lý Hợp đồng B2B',
                      subtitle: 'Hợp đồng điện tử & Ký quỹ',
                      onTap: () => context.push('/contracts'),
                    ),
                    const Divider(height: 1, indent: 50, color: AppColors.border),
                    _MenuItem(
                      icon: Icons.local_shipping_outlined,
                      title: 'Giao hàng & ColdChain',
                      subtitle: 'Theo dõi nhiệt độ và PoD',
                      onTap: () => context.push('/delivery-pod'),
                    ),
                    const Divider(height: 1, indent: 50, color: AppColors.border),
                    _MenuItem(
                      icon: Icons.storefront_outlined,
                      title: 'Đăng Ký Nhà Cung Cấp B2B',
                      subtitle: 'Mở xưởng bán sỉ trên cổng đối tác Web',
                      onTap: () => _showSupplierRegistrationDialog(context),
                    ),
                    const Divider(height: 1, indent: 50, color: AppColors.border),
                    _MenuItem(
                      icon: Icons.campaign_outlined,
                      title: 'Cài đặt Thông báo',
                      subtitle: 'Thông báo báo giá và đơn hàng',
                      onTap: () => context.push('/notification-settings'),
                    ),
                    // Only show UI Showcase in Debug Mode (D12)
                    if (kDebugMode) ...[
                      const Divider(height: 1, indent: 50, color: AppColors.border),
                      _MenuItem(
                        icon: Icons.widgets_outlined,
                        title: 'UI Showcase AntD & Lucian',
                        subtitle: 'Kho component thiết kế Hoàng Gia (Dev Only)',
                        onTap: () => context.push('/ui-catalog'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout / Login Button
              CustomButton(
                title: authState.isAuthenticated ? 'Đăng xuất tài khoản' : 'Đăng nhập tài khoản',
                variant: ButtonVariant.outline,
                width: double.infinity,
                onPress: () {
                  if (authState.isAuthenticated) {
                    ref.read(authProvider.notifier).logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã đăng xuất.')),
                    );
                    _loadStats();
                  } else {
                    context.push('/login');
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool hasError;

  const _StatItem({
    required this.value,
    required this.label,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          hasError ? '-' : value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
