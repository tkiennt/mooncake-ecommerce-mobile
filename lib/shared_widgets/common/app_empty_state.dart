import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'custom_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? customIllustration;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final EdgeInsets padding;

  const AppEmptyState({
    super.key,
    this.icon,
    this.customIllustration,
    this.title = 'Chưa có dữ liệu',
    this.message = 'Hiện chưa có thông tin nào để hiển thị trong mục này.',
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.padding = const EdgeInsets.all(AppTokens.space2XL),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration / Icon container tông vàng ngà
            if (customIllustration != null)
              customIllustration!
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accentGoldBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon ?? Icons.inbox_outlined,
                    size: 38,
                    color: AppColors.accent,
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.spaceLG),
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            // Message
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spaceSM),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            // CTA Buttons (tap target >= 44px)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.spaceXL),
              CustomButton(
                title: actionLabel!,
                onPress: onAction,
                size: ButtonSize.medium,
                variant: ButtonVariant.primary,
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppTokens.spaceSM),
              CustomButton(
                title: secondaryActionLabel!,
                onPress: onSecondaryAction,
                size: ButtonSize.small,
                variant: ButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
