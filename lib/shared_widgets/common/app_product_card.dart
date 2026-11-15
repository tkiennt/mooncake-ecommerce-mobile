import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/product.dart';
import 'app_price_tag.dart';

class AppProductCard extends StatelessWidget {
  final Product product;
  final ValueChanged<Product>? onPress;
  final double imageRatio;

  const AppProductCard({
    super.key,
    required this.product,
    this.onPress,
    this.imageRatio = 1.0,
  });

  String _formatSold(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k+';
    }
    return '$count';
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  Widget _buildPlaceholder({IconData icon = Icons.cake_outlined}) {
    return Container(
      color: AppColors.surfaceHover,
      child: Center(
        child: Icon(icon, color: AppColors.textMuted, size: 36),
      ),
    );
  }

  Widget _buildProductImage() {
    final image = product.coverImage;
    if (image == null || image.isEmpty) {
      return _buildPlaceholder();
    }

    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
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
      errorWidget: (_, __, ___) => _buildPlaceholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tìm tier chiết khấu tốt nhất từ dữ liệu thật của BE
    TierPricing? bestTier;
    for (final tier in product.tierPricing) {
      if (tier.discountPercent > 0) {
        if (bestTier == null || tier.discountPercent > bestTier.discountPercent) {
          bestTier = tier;
        }
      }
    }

    final topDiscount = bestTier?.discountPercent ?? 0.0;
    final wholesaleUnitPrice = bestTier != null
        ? (product.basePrice * (1.0 - bestTier.discountPercent / 100.0)).roundToDouble()
        : null;

    final unitLabel = product.unit.isNotEmpty ? product.unit : 'hộp';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTokens.elevationCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onPress?.call(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frame ảnh sản phẩm 1:1
              AspectRatio(
                aspectRatio: imageRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildProductImage(),
                    // Badge giảm giá B2B nếu có
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
                              fontFamily: 'Roboto',
                              color: AppColors.textWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Badge hỗ trợ in logo / bao bì tuỳ biến
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
                                  fontFamily: 'Roboto',
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

              // Thân thẻ (Card Body)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag xưởng uy tín
                    if (product.rating >= 4.8 || product.shopVerified)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 11, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(
                              'Xưởng uy tín',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                color: AppColors.primaryLight,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Tên sản phẩm
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Hàng giá bán lẻ + Đã bán
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: AppPriceTag(
                            price: product.basePrice,
                            size: AppPriceTagSize.medium,
                            isBold: true,
                          ),
                        ),
                        if (product.soldCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            'Đã bán ${_formatSold(product.soldCount)}',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),

                    // Tag giá sỉ theo D15: CHỈ khi BE có tier pricing, không bịa số
                    if (bestTier != null && wholesaleUnitPrice != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBg,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'Sỉ từ ${_formatCurrency(wholesaleUnitPrice)} khi mua ≥ ${bestTier.minQty} $unitLabel',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Mức tối thiểu (MOQ)
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Từ ${product.minOrderQty} $unitLabel',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
