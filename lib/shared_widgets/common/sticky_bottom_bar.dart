import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'app_price_tag.dart';
import 'custom_button.dart';

class StickyBottomBar extends StatelessWidget {
  final Widget? child;
  final String? totalLabel;
  final double? totalAmount;
  final String? subtitle;
  final String? primaryButtonTitle;
  final VoidCallback? onPrimaryPressed;
  final bool primaryButtonLoading;
  final bool primaryButtonDisabled;
  final Widget? primaryButtonIcon;
  final String? secondaryButtonTitle;
  final VoidCallback? onSecondaryPressed;
  final bool secondaryButtonLoading;
  final bool secondaryButtonDisabled;
  final Widget? secondaryButtonIcon;
  final ButtonVariant secondaryButtonVariant;
  final Widget? leading;
  final EdgeInsets padding;
  final Color backgroundColor;

  const StickyBottomBar({
    super.key,
    this.child,
    this.totalLabel,
    this.totalAmount,
    this.subtitle,
    this.primaryButtonTitle,
    this.onPrimaryPressed,
    this.primaryButtonLoading = false,
    this.primaryButtonDisabled = false,
    this.primaryButtonIcon,
    this.secondaryButtonTitle,
    this.onSecondaryPressed,
    this.secondaryButtonLoading = false,
    this.secondaryButtonDisabled = false,
    this.secondaryButtonIcon,
    this.secondaryButtonVariant = ButtonVariant.outline,
    this.leading,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTokens.spaceLG,
      vertical: AppTokens.spaceMD,
    ),
    this.backgroundColor = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
        boxShadow: AppTokens.elevationSticky,
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: padding,
          child: child ?? _buildDefaultContent(),
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    // Mode 1: Price Summary + Primary Button (và optional Secondary Button)
    if (totalAmount != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTokens.spaceSM),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalLabel ?? 'Tổng thanh toán',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                AppPriceTag(
                  price: totalAmount!,
                  size: AppPriceTagSize.medium,
                  isBold: true,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.spaceMD),
          if (primaryButtonTitle != null)
            CustomButton(
              title: primaryButtonTitle!,
              icon: primaryButtonIcon,
              onPress: onPrimaryPressed,
              loading: primaryButtonLoading,
              disabled: primaryButtonDisabled,
              size: ButtonSize.medium,
              variant: ButtonVariant.primary,
            ),
        ],
      );
    }

    // Mode 2: Two Buttons side-by-side (hoặc 1 nút chiếm full-width)
    if (secondaryButtonTitle != null && primaryButtonTitle != null) {
      return Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTokens.spaceSM),
          ],
          Expanded(
            flex: 1,
            child: CustomButton(
              title: secondaryButtonTitle!,
              icon: secondaryButtonIcon,
              onPress: onSecondaryPressed,
              loading: secondaryButtonLoading,
              disabled: secondaryButtonDisabled,
              size: ButtonSize.medium,
              variant: secondaryButtonVariant,
            ),
          ),
          const SizedBox(width: AppTokens.spaceMD),
          Expanded(
            flex: 1,
            child: CustomButton(
              title: primaryButtonTitle!,
              icon: primaryButtonIcon,
              onPress: onPrimaryPressed,
              loading: primaryButtonLoading,
              disabled: primaryButtonDisabled,
              size: ButtonSize.medium,
              variant: ButtonVariant.primary,
            ),
          ),
        ],
      );
    }

    // Mode 3: Single Primary Button (full width)
    if (primaryButtonTitle != null) {
      return Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTokens.spaceSM),
          ],
          Expanded(
            child: CustomButton(
              title: primaryButtonTitle!,
              icon: primaryButtonIcon,
              onPress: onPrimaryPressed,
              loading: primaryButtonLoading,
              disabled: primaryButtonDisabled,
              size: ButtonSize.medium,
              variant: ButtonVariant.primary,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
