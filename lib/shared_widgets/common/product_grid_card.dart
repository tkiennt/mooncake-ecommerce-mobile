import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/product.dart';

class ProductGridCard extends StatelessWidget {
  final Product product;
  final ValueChanged<Product>? onPress;
  final double imageRatio;

  const ProductGridCard({
    super.key,
    required this.product,
    this.onPress,
    this.imageRatio = 1.0,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} ₫';
  }

  String _formatSold(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k+';
    }
    return '$count';
  }

  Widget _buildProductImage() {
    final image = product.coverImage;
    if (image == null || image.isEmpty) {
      return Image.asset(
        'assets/products/banh-nuong.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceHover,
          child: const Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 36),
        ),
      );
    }

    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceHover,
          child: const Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 36),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: AppColors.surfaceHover,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Image.asset('assets/products/banh-nuong.jpg', fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topDiscount = product.tierPricing.isEmpty
        ? 0.0
        : product.tierPricing
            .map((t) => t.discountPercent)
            .reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTokens.shadowCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPress?.call(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Frame
              AspectRatio(
                aspectRatio: imageRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildProductImage(),
                    if (topDiscount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                          ),
                          child: Text(
                            '-${topDiscount.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (product.isCustomPackagingSupported)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBg,
                            borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                            border: Border.all(color: AppColors.accent, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_fix_high, size: 10, color: AppColors.accent),
                              SizedBox(width: 3),
                              Text(
                                'In logo',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Card Body
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.rating >= 4.8)
                      Padding(
                        padding: const EdgeInsets.bottom: 4.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 11, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(
                              'Xưởng uy tín',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            _formatCurrency(product.basePrice),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.soldCount > 0)
                          Text(
                            'Đã bán ${_formatSold(product.soldCount)}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Từ ${product.minOrderQty} ${product.unit}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
