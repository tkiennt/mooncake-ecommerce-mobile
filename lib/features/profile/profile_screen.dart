import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/rfq_repository.dart';
import '../../providers/auth_provider.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/custom_button.dart';

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
          _statsError = 'Chưa tải được số liệu';
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
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          title: const Row(
            children: [
              Icon(Icons.storefront_outlined, color: AppColors.primary, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đăng ký xưởng bánh',
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
                'Để đảm bảo chất lượng và an toàn thực phẩm, quy trình đăng ký xưởng bánh đối tác được thực hiện trực tiếp trên website Nguyệt Phố.',
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
                            content: Text('Đã sao chép liên kết đăng ký xưởng bánh!'),
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

  Widget _buildStatsWidget() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceLG, horizontal: AppTokens.spaceMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppColors.border),
        ),
        child: AppSkeleton.shimmer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  AppSkeleton.text(width: 36, height: 18),
                  const SizedBox(height: 6),
                  AppSkeleton.text(width: 60, height: 12),
                ],
              ),
              Column(
                children: [
                  AppSkeleton.text(width: 36, height: 18),
                  const SizedBox(height: 6),
                  AppSkeleton.text(width: 70, height: 12),
                ],
              ),
              Column(
                children: [
                  AppSkeleton.text(width: 36, height: 18),
                  const SizedBox(height: 6),
                  AppSkeleton.text(width: 65, height: 12),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTokens.shadowSubtle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '$_orderCount',
            label: 'Đơn hàng',
            hasError: _statsError != null,
          ),
          _StatItem(
            value: '$_rfqCount',
            label: 'Yêu cầu báo giá',
            hasError: _statsError != null,
          ),
          _StatItem(
            value: '$_boxCount',
            label: 'Hộp đã đặt',
            hasError: _statsError != null,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Tài khoản',
        showBack: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
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
                    const SizedBox(width: AppTokens.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? (authState.isAuthenticated ? 'Khách hàng thân thiết' : 'Khách vãng lai'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.companyName ?? (authState.isAuthenticated ? 'Khách hàng doanh nghiệp' : 'Chưa đăng nhập'),
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.phoneNumber ?? user?.email ?? 'Chưa cập nhật liên hệ',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (authState.isAuthenticated)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                        tooltip: 'Chỉnh sửa hồ sơ',
                        constraints: const BoxConstraints(
                          minWidth: AppTokens.minTapTarget,
                          minHeight: AppTokens.minTapTarget,
                        ),
                        onPressed: () => context.push('/edit-profile').then((_) => _loadStats()),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spaceMD),

              // Metrics Row
              _buildStatsWidget(),
              if (_statsError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '$_statsError. Kéo xuống để tải lại.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),

              // NHÓM 1: Đơn hàng & Giao dịch
              _buildGroupTitle('Đơn hàng & Giao dịch'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Đơn Hàng Doanh Nghiệp',
                      subtitle: 'Lịch sử đặt mua và theo dõi tiến độ',
                      onTap: () => context.push('/orders'),
                    ),
                    const Divider(height: 1, indent: 52, color: AppColors.border),
                    _MenuItem(
                      icon: Icons.assignment_outlined,
                      title: 'Hợp đồng mua bán',
                      subtitle: 'Xem hợp đồng và các đợt thanh toán',
                      onTap: () => context.push('/contracts'),
                    ),
                    const Divider(height: 1, indent: 52, color: AppColors.border),
                    _MenuItem(
                      icon: Icons.local_shipping_outlined,
                      title: 'Theo dõi giao hàng',
                      subtitle: 'Theo dõi vận chuyển và nhận hàng',
                      onTap: () => context.push('/delivery-pod'),
                    ),
                  ],
                ),
              ),

              // NHÓM 2: Thông tin & Đối tác
              _buildGroupTitle('Thông tin & Đối tác'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.business_outlined,
                      title: 'Thông tin tài khoản',
                      subtitle: 'Cập nhật họ tên, công ty, số điện thoại',
                      onTap: () => context.push('/edit-profile').then((_) => _loadStats()),
                    ),
                    const Divider(height: 1, indent: 52, color: AppColors.border),
                    _MenuItem(
                      icon: Icons.storefront_outlined,
                      title: 'Đăng ký xưởng bánh đối tác',
                      subtitle: 'Đăng ký bán bánh trên hệ thống Nguyệt Phố',
                      onTap: () => _showSupplierRegistrationDialog(context),
                    ),
                  ],
                ),
              ),

              // NHÓM 3: Cài đặt
              _buildGroupTitle('Cài đặt'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.campaign_outlined,
                      title: 'Cài đặt thông báo',
                      subtitle: 'Nhận thông báo đơn hàng và báo giá',
                      onTap: () => context.push('/notification-settings'),
                    ),
                    if (kDebugMode) ...[
                      const Divider(height: 1, indent: 52, color: AppColors.border),
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
              const SizedBox(height: AppTokens.space2XL),

              // Logout / Login Button
              CustomButton(
                title: authState.isAuthenticated ? 'Đăng xuất' : 'Đăng nhập',
                variant: ButtonVariant.outline,
                width: double.infinity,
                size: ButtonSize.large,
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
              const SizedBox(height: AppTokens.space2XL),
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
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: 2,
        ),
        minLeadingWidth: 24,
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
