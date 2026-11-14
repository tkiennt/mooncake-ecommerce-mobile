import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class TrustSecurityBadges extends StatelessWidget {
  const TrustSecurityBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTokens.shadowSubtle,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BadgeItem(
            icon: Icons.verified_user_outlined,
            title: 'Ký quỹ an toàn',
            subtitle: 'Bảo vệ nguồn tiền',
          ),
          _VerticalDivider(),
          _BadgeItem(
            icon: Icons.ac_unit,
            title: 'Giao xe lạnh',
            subtitle: 'Chuẩn 20-25°C',
          ),
          _VerticalDivider(),
          _BadgeItem(
            icon: Icons.receipt_long_outlined,
            title: 'Hóa đơn VAT',
            subtitle: 'Đầy đủ chứng từ',
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: AppColors.border,
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BadgeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
