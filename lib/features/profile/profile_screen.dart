import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Tài Khoản Doanh Nghiệp',
        showBack: false,
      ),
      body: SingleChildScrollView(
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
                          user?.fullName ?? 'Khách hàng Hoàng Gia',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.companyName ?? 'Tập đoàn B2B Mooncake',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.phoneNumber ?? '0901234567',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    onPressed: () => context.push('/edit-profile'),
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
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(value: '3', label: 'Đơn hàng'),
                  _StatItem(value: '2', label: 'Yêu cầu RFQ'),
                  _StatItem(value: '650', label: 'Hộp đã đặt'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Menu
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
                border: Border.all(color: AppColors.border),
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
                    icon: Icons.campaign_outlined,
                    title: 'Cài đặt Thông báo',
                    subtitle: 'Thông báo báo giá và đơn hàng',
                    onTap: () => context.push('/notification-settings'),
                  ),
                  const Divider(height: 1, indent: 50, color: AppColors.border),
                  _MenuItem(
                    icon: Icons.widgets_outlined,
                    title: 'UI Showcase AntD & Lucian',
                    subtitle: 'Kho component thiết kế Hoàng Gia',
                    onTap: () => context.push('/ui-catalog'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            CustomButton(
              title: authState.isAuthenticated ? 'Đăng xuất tài khoản' : 'Đăng nhập',
              variant: ButtonVariant.outline,
              width: double.infinity,
              onPress: () {
                if (authState.isAuthenticated) {
                  ref.read(authProvider.notifier).logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đăng xuất.')),
                  );
                } else {
                  context.push('/login');
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
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
