import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class RecentOrderToast extends StatelessWidget {
  final String companyName;
  final int boxCount;
  final String timeAgo;
  final VoidCallback? onDismiss;

  const RecentOrderToast({
    super.key,
    required this.companyName,
    required this.boxCount,
    this.timeAgo = 'vài phút trước',
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceSM,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMD,
        vertical: AppTokens.spaceSM,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTokens.elevationSubtle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.spaceXS + 2),
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppTokens.spaceSM),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: companyName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' vừa chốt đơn '),
                  TextSpan(
                    text: '$boxCount hộp',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: ' · $timeAgo',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onDismiss != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                child: const SizedBox(
                  width: AppTokens.minTapTarget,
                  height: AppTokens.minTapTarget,
                  child: Center(
                    child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
