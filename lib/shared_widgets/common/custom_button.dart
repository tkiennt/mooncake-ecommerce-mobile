import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum ButtonVariant { primary, secondary, outline }
enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPress;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool loading;
  final bool disabled;
  final Widget? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.title,
    this.onPress,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.loading = false,
    this.disabled = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color getBackgroundColor() {
      if (disabled) return AppColors.border;
      switch (variant) {
        case ButtonVariant.primary:
          return AppColors.primary;
        case ButtonVariant.secondary:
          return AppColors.accent;
        case ButtonVariant.outline:
          return Colors.transparent;
      }
    }

    Color getTextColor() {
      if (disabled) return AppColors.textMuted;
      switch (variant) {
        case ButtonVariant.outline:
          return AppColors.primary;
        case ButtonVariant.secondary:
        case ButtonVariant.primary:
          return AppColors.textWhite;
      }
    }

    EdgeInsets getPadding() {
      switch (size) {
        case ButtonSize.small:
          return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        case ButtonSize.medium:
          return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
        case ButtonSize.large:
          return const EdgeInsets.symmetric(horizontal: 24, vertical: 15);
      }
    }

    double getFontSize() {
      switch (size) {
        case ButtonSize.small:
          return 13;
        case ButtonSize.medium:
          return 15;
        case ButtonSize.large:
          return 16;
      }
    }

    final isClickable = !disabled && !loading;

    return SizedBox(
      width: width,
      child: Material(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
        child: InkWell(
          onTap: isClickable ? onPress : null,
          borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
          child: Container(
            padding: getPadding(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
              border: variant == ButtonVariant.outline
                  ? Border.all(color: disabled ? AppColors.border : AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Row(
              mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: getFontSize() + 2,
                    height: getFontSize() + 2,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      color: getTextColor(),
                      fontSize: getFontSize(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
