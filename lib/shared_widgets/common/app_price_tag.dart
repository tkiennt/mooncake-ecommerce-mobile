import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

enum AppPriceTagSize { small, medium, large }

class AppPriceTag extends StatelessWidget {
  final double price;
  final double? maxPrice;
  final double? originalPrice;
  final String? suffix;
  final String? prefix;
  final Color? color;
  final AppPriceTagSize size;
  final bool isBold;
  final TextStyle? customStyle;
  final bool showCurrency;

  const AppPriceTag({
    super.key,
    required this.price,
    this.maxPrice,
    this.originalPrice,
    this.suffix,
    this.prefix,
    this.color,
    this.size = AppPriceTagSize.medium,
    this.isBold = true,
    this.customStyle,
    this.showCurrency = true,
  });

  String _formatNumber(double amount) {
    return NumberFormat('#,###', 'vi_VN').format(amount);
  }

  double _getFontSize() {
    switch (size) {
      case AppPriceTagSize.small:
        return 13.0;
      case AppPriceTagSize.medium:
        return 16.0;
      case AppPriceTagSize.large:
        return 20.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final fontSize = _getFontSize();
    final currencySymbol = showCurrency ? '₫' : '';

    String priceText;
    if (maxPrice != null && maxPrice! > price) {
      priceText = '${_formatNumber(price)} $currencySymbol - ${_formatNumber(maxPrice!)} $currencySymbol';
    } else {
      priceText = '${_formatNumber(price)} $currencySymbol';
    }

    final priceStyle = customStyle ??
        TextStyle(
          fontFamily: 'Roboto',
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          color: effectiveColor,
          letterSpacing: -0.2,
        );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppTokens.spaceXS,
      children: [
        if (prefix != null && prefix!.isNotEmpty)
          Text(
            prefix!,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize * 0.75,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        Text(
          priceText,
          style: priceStyle,
        ),
        if (originalPrice != null && originalPrice! > price)
          Text(
            '${_formatNumber(originalPrice!)} $currencySymbol',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize * 0.75,
              decoration: TextDecoration.lineThrough,
              color: AppColors.textMuted,
            ),
          ),
        if (suffix != null && suffix!.isNotEmpty)
          Text(
            suffix!,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize * 0.75,
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}
