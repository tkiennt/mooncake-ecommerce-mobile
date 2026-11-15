import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/product.dart';
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
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
    _quantity = widget.product.minOrderQty;
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    try {
      final map = await ref.read(wishlistRepositoryProvider).checkWishlist([widget.product.id]);
      if (mounted && map.containsKey(widget.product.id)) {
        setState(() {
          _isWishlisted = map[widget.product.id] == true;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    try {
      final isSaved = await ref.read(wishlistRepositoryProvider).toggleWishlist(widget.product.id);
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
    return widget.product.basePrice + (_selectedVariant?.priceAdjustment ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
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
                  child: Image.asset(
                    p.coverImage ?? 'assets/products/banh-nuong.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceHover,
                      child: const Icon(Icons.cake_outlined, size: 64, color: AppColors.textMuted),
                    ),
                  ),
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
              ],
            ),

            // Main Details Card
            Container(
              padding: const EdgeInsets.all(16),
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/${p.unit}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      if (p.isCustomPackagingSupported)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 12, color: AppColors.accent),
                              SizedBox(width: 4),
                              Text(
                                'Hỗ trợ in Logo',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        ' (${p.reviewCount} đánh giá) · Đã bán ${p.soldCount} hộp',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Workshop / Shop Link Card
            Container(
              padding: const EdgeInsets.all(14),
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
                  const SizedBox(width: 12),
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
                          'Xưởng sản xuất đối tác chính thức',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.store, size: 14, color: AppColors.primary),
                    label: const Text(
                      'Xem Shop',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final slug = p.shopSlug ?? (p.shopId != null && p.shopId!.isNotEmpty ? p.shopId! : 'nguyet-pho');
                      context.push('/shop/$slug');
                    },
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                    tooltip: 'Nhắn tin với xưởng',
                    onPressed: () {
                      context.push(
                        '/chat?shopId=${p.shopId ?? ''}&shopName=${Uri.encodeComponent(p.shopName)}',
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Variant Selector
            if (p.variants.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn Hương Vị / Biến Thể:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                          labelStyle: TextStyle(
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
            const SizedBox(height: 8),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mô Tả Sản Phẩm',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.description.isNotEmpty ? p.description : 'Bánh trung thu truyền thống thượng hạng của Nguyệt Phố.',
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),

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
                  SnackBar(content: Text('Đã chọn mua ${result.quantity} hộp với chiết khấu ${result.effectiveDiscount.toInt()}%')),
                );
              },
            ),

            // Trust badges
            _buildTrustBadges(),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // Bottom Add to Cart & Buy Now Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity stepper
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                    onPressed: () {
                      if (_quantity > p.minOrderQty) {
                        setState(() => _quantity--);
                      }
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
              const SizedBox(width: 8),

              // Add to Cart
              Expanded(
                child: CustomButton(
                  title: 'Thêm giỏ',
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
              const SizedBox(width: 8),

              // Buy Now / RFQ
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

  Widget _buildTrustBadges() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: AppTokens.shadowSubtle,
      ),
      child: const Wrap(
        alignment: WrapAlignment.spaceAround,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          _TrustBadgeItem(
            icon: Icons.verified_user_outlined,
            title: 'Ký quỹ an toàn',
            subtitle: 'Bảo vệ nguồn tiền',
          ),
          _TrustBadgeItem(
            icon: Icons.ac_unit,
            title: 'Giao xe lạnh',
            subtitle: 'Chuẩn 20-25°C',
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
