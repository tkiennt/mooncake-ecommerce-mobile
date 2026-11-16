import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../providers/cart_provider.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/lucian/b2b_price_calculator.dart';
import '../../shared_widgets/lucian/tear_off_coupon.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late Product _product;
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    if (_product.variants.isNotEmpty) {
      _selectedVariant = _product.variants.first;
    }
    _quantity = _product.minOrderQty;
    _checkWishlist();
    _fetchUpdatedDetails();
  }

  Future<void> _fetchUpdatedDetails() async {
    try {
      final updated = await ref.read(catalogRepositoryProvider).getProductDetails(_product.id);
      if (mounted) {
        setState(() {
          _product = updated;
          if (_selectedVariant != null && updated.variants.isNotEmpty) {
            final match = updated.variants.where((v) => v.id == _selectedVariant!.id).firstOrNull;
            _selectedVariant = match ?? updated.variants.first;
          }
        });
      }
    } catch (_) {
      // Use initialProduct if offline or cached
    }
  }

  Future<void> _checkWishlist() async {
    try {
      final map = await ref.read(wishlistRepositoryProvider).checkWishlist([_product.id]);
      if (mounted && map.containsKey(_product.id)) {
        setState(() {
          _isWishlisted = map[_product.id] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    try {
      final isSaved = await ref.read(wishlistRepositoryProvider).toggleWishlist(_product.id);
      if (!mounted) return;
      setState(() {
        _isWishlisted = isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved
                ? 'Đã thêm vào danh sách yêu thích'
                : 'Đã bỏ khỏi danh sách yêu thích',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫';
  }

  double get _currentUnitPrice {
    return _product.basePrice + (_selectedVariant?.priceAdjustment ?? 0);
  }

  Widget _buildProductHeroImage(Product p) {
    final image = p.coverImage;
    if (image == null || image.isEmpty) {
      return Container(
        color: AppColors.surfaceHover,
        child: const Center(
          child: Icon(Icons.cake_outlined, size: 64, color: AppColors.textMuted),
        ),
      );
    }
    if (image.startsWith('assets/')) {
      return Image.asset(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceHover,
          child: const Center(
            child: Icon(Icons.cake_outlined, size: 64, color: AppColors.textMuted),
          ),
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
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surfaceHover,
        child: const Center(
          child: Icon(Icons.cake_outlined, size: 64, color: AppColors.textMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: p.name,
        showBack: true,
        rightIcon: Icons.shopping_cart_outlined,
        onRightPress: () => context.push('/cart'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image Stack with Wishlist Button
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: _buildProductHeroImage(p),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppTokens.minTapTarget,
                        minHeight: AppTokens.minTapTarget,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: _isWishlisted ? AppColors.error : AppColors.textSecondary,
                          size: 24,
                        ),
                        tooltip: _isWishlisted ? 'Bỏ yêu thích' : 'Thêm yêu thích',
                        onPressed: _toggleWishlist,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Main Details Card
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatCurrency(_currentUnitPrice),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/${p.unit}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (p.isCustomPackagingSupported)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBg,
                            borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.palette_outlined, size: 12, color: AppColors.accent),
                              SizedBox(width: 4),
                              Text(
                                'In logo theo yêu cầu',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    p.name,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${p.rating}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' (${p.reviewCount} đánh giá) · Đã bán ${p.soldCount} hộp',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceSM),

            // Workshop / Shop Link Card
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceMD + 2),
              color: AppColors.surface,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentGoldBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: const Icon(Icons.storefront, color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: AppTokens.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.shopName,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.shopVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: AppColors.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Xưởng làm bánh uy tín',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: const Size(0, AppTokens.minTapTarget),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                        ),
                      ),
                      icon: const Icon(Icons.store, size: 15, color: AppColors.primary),
                      label: const Text(
                        'Xem xưởng',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        final slug = p.shopSlug ?? (p.shopId != null && p.shopId!.isNotEmpty ? p.shopId! : 'nguyet-pho');
                        context.push('/shop/$slug');
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppTokens.minTapTarget,
                      minHeight: AppTokens.minTapTarget,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 22),
                      tooltip: 'Nhắn tin với xưởng',
                      onPressed: () {
                        context.push(
                          '/chat?shopId=${p.shopId ?? ''}&shopName=${Uri.encodeComponent(p.shopName)}',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceSM),

            // Variant Selector
            if (p.variants.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceLG),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn hương vị:',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.variants.map((v) {
                        final isSelected = _selectedVariant?.id == v.id;
                        return ChoiceChip(
                          label: Text(
                            v.priceAdjustment > 0
                                ? '${v.name} (+${_formatCurrency(v.priceAdjustment)})'
                                : v.name,
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryTint,
                          backgroundColor: AppColors.surfaceHover,
                          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          ),
                          labelStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          onSelected: (_) => setState(() => _selectedVariant = v),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.spaceSM),

            // Description
            Container(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.description.isNotEmpty
                        ? p.description
                        : 'Bánh trung thu truyền thống chất lượng cao từ Nguyệt Phố.',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Bảng giá theo bậc (Tiered Pricing Table) theo D15, D16 & Mục 4 hàng #3
            if (p.tierPricing.isNotEmpty)
              _buildTieredPricingSection(p)
            else
              _buildRfqPromptSection(p),

            // Embedded Tear-Off Coupon
            const TearOffCoupon(),

            // Embedded B2B Wholesale Calculator
            B2BPriceCalculator(
              baseRetailPrice: p.basePrice,
              initialQuantity: p.minOrderQty > 20 ? p.minOrderQty : 50,
              onApplyTier: (result) {
                setState(() {
                  _quantity = result.quantity;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã chọn mua ${result.quantity} hộp với chiết khấu ${result.effectiveDiscount.toInt()}%',
                    ),
                  ),
                );
              },
            ),

            // Trust badges (Sửa tràn ngang 43px theo benchmark mục 4 #3)
            _buildTrustBadges(),
            const SizedBox(height: AppTokens.space2XL),
          ],
        ),
      ),

      // Bottom Add to Cart & Buy Now Bar (D16: thanh đáy giữ "Thêm vào giỏ")
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceLG,
          vertical: AppTokens.spaceSM + 2,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppTokens.elevationSticky,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity stepper (tap target >= 44px)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppTokens.minTapTarget,
                        minHeight: AppTokens.minTapTarget,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove, color: AppColors.primary, size: 18),
                        onPressed: () {
                          if (_quantity > p.minOrderQty) {
                            setState(() => _quantity--);
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppTokens.minTapTarget,
                        minHeight: AppTokens.minTapTarget,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),

              // Add to Cart Button (tap target >= 44px)
              Expanded(
                child: CustomButton(
                  title: 'Thêm vào giỏ',
                  variant: ButtonVariant.outline,
                  onPress: () {
                    ref.read(cartProvider.notifier).addToCart(p, _selectedVariant, _quantity);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm $_quantity hộp vào giỏ hàng!'),
                        action: SnackBarAction(
                          label: 'Xem giỏ',
                          onPressed: () => context.push('/cart'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTokens.spaceSM),

              // Buy Now / Thanh toán ngay
              Expanded(
                child: CustomButton(
                  title: 'Mua ngay',
                  variant: ButtonVariant.primary,
                  onPress: () {
                    ref.read(cartProvider.notifier).addToCart(p, _selectedVariant, _quantity);
                    context.push('/cart');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTieredPricingSection(Product p) {
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.spaceSM),
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.table_chart_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: AppTokens.spaceSM),
              Text(
                'Bảng giá sỉ theo số lượng',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Chiết khấu trực tiếp từ xưởng khi đặt số lượng lớn',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMD),

          // Bảng nấc giá
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  color: AppColors.surfaceHover,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Số lượng (hộp)',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Chiết khấu',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Đơn giá sỉ',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ...p.tierPricing.map((tier) {
                  final bool isCurrentTier = _quantity >= tier.minQty &&
                      (tier.maxQty == null || _quantity <= tier.maxQty!);
                  final wholesalePrice = (p.basePrice * (1.0 - tier.discountPercent / 100.0)).roundToDouble();

                  final qtyText = tier.maxQty != null
                      ? '${tier.minQty} - ${tier.maxQty}'
                      : '≥ ${tier.minQty}';

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _quantity = tier.minQty;
                      });
                    },
                    child: Container(
                      color: isCurrentTier ? AppColors.accentGoldBg : AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                if (isCurrentTier) ...[
                                  const Icon(Icons.check_circle, size: 14, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  qtyText,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12.5,
                                    fontWeight: isCurrentTier ? FontWeight.bold : FontWeight.w500,
                                    color: isCurrentTier ? AppColors.accent : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCurrentTier ? AppColors.accent : AppColors.primaryTint,
                                  borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                                ),
                                child: Text(
                                  '-${tier.discountPercent.toInt()}%',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentTier ? AppColors.textWhite : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _formatCurrency(wholesalePrice),
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12.5,
                                fontWeight: isCurrentTier ? FontWeight.bold : FontWeight.w600,
                                color: isCurrentTier ? AppColors.accent : AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spaceMD),

          // D16: nút viền vàng "Nhận báo giá sỉ / in logo" dưới bảng giá → mở tạo RFQ điền sẵn sản phẩm
          _buildRfqGoldButton(p),
        ],
      ),
    );
  }

  Widget _buildRfqPromptSection(Product p) {
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.spaceSM),
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_center_outlined, color: AppColors.accent, size: 20),
              SizedBox(width: AppTokens.spaceSM),
              Text(
                'Đặt bánh doanh nghiệp & in logo',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Nhận bảng giá ưu đãi và hỗ trợ thiết kế bao bì cho doanh nghiệp.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spaceMD),
          _buildRfqGoldButton(p),
        ],
      ),
    );
  }

  Widget _buildRfqGoldButton(Product p) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          backgroundColor: AppColors.accentGoldBg,
          side: const BorderSide(color: AppColors.accent, width: 1.4),
          minimumSize: const Size(double.infinity, AppTokens.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
          ),
        ),
        icon: const Icon(Icons.request_quote_outlined, size: 20, color: AppColors.accent),
        label: const Text(
          'Yêu cầu báo giá sỉ',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        ),
        onPressed: () {
          context.push(
            '/create-rfq?productId=${p.id}&productName=${Uri.encodeComponent(p.name)}&quantity=$_quantity',
            extra: {'product': p, 'quantity': _quantity},
          );
        },
      ),
    );
  }

  /// Sửa lỗi tràn ngang 43px tại TrustBadges (mục 4 hàng #3 benchmark)
  Widget _buildTrustBadges() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceSM,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMD,
        vertical: AppTokens.spaceMD,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTokens.elevationSubtle,
      ),
      child: const Wrap(
        alignment: WrapAlignment.spaceAround,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 10,
        children: [
          _TrustBadgeItem(
            icon: Icons.verified_user_outlined,
            title: 'Đặt hàng an toàn',
            subtitle: 'Đảm bảo chất lượng',
          ),
          _TrustBadgeItem(
            icon: Icons.ac_unit,
            title: 'Giao tận nơi',
            subtitle: 'Bảo quản tiêu chuẩn',
          ),
          _TrustBadgeItem(
            icon: Icons.receipt_long_outlined,
            title: 'Hóa đơn VAT',
            subtitle: 'Đầy đủ chứng từ',
          ),
        ],
      ),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustBadgeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 95),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
