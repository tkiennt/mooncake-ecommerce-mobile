import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/product.dart';
import '../../data/models/wishlist_item.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../providers/cart_provider.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/custom_button.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  List<WishlistItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ref.read(wishlistRepositoryProvider).getWishlist();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(WishlistItem item) async {
    final originalItems = List<WishlistItem>.from(_items);
    setState(() {
      _items.removeWhere((i) => i.productId == item.productId);
    });

    try {
      await ref.read(wishlistRepositoryProvider).toggleWishlist(item.productId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã bỏ "${item.productName}" khỏi danh sách yêu thích'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = originalItems;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật yêu thích: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###', 'vi_VN').format(price)} ₫';
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceHover,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 36),
      );
    }

    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 80,
            height: 80,
            color: AppColors.surfaceHover,
            child: const Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 36),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 80,
          height: 80,
          color: AppColors.surfaceHover,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 80,
          height: 80,
          color: AppColors.surfaceHover,
          child: const Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        title: 'Sản phẩm yêu thích',
        subtitle: _items.isNotEmpty ? '${_items.length} sản phẩm đã lưu' : null,
        showBack: true,
        onBack: () => context.pop(),
        rightIcon: Icons.shopping_cart_outlined,
        onRightPress: () => context.push('/cart'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWishlist,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang tải danh sách yêu thích...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Không thể tải danh sách yêu thích',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              CustomButton(
                title: 'Thử lại',
                variant: ButtonVariant.primary,
                size: ButtonSize.small,
                onPress: _loadWishlist,
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.accentGoldBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_border, size: 40, color: AppColors.accent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Danh sách yêu thích trống',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn chưa lưu mẫu bánh nào. Hãy khám phá danh mục và bấm nút trái tim để lưu lại các mẫu bánh ưng ý!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              CustomButton(
                title: 'Khám phá sản phẩm',
                icon: const Icon(Icons.search, color: Colors.white, size: 16),
                onPress: () => context.go('/search'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _items[index];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              GestureDetector(
                onTap: () => _openProductDetail(item),
                child: _buildProductThumbnail(item.imageUrl),
              ),
              const SizedBox(width: 12),

              // Info & Actions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.shopName != null && item.shopName!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.shopName!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _openProductDetail(item),
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(item.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.add_shopping_cart, size: 13, color: AppColors.primary),
                          label: const Text(
                            'Thêm giỏ',
                            style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            final dummyProduct = Product(
                              id: item.productId,
                              name: item.productName,
                              basePrice: item.price,
                              shopName: item.shopName ?? 'Xưởng sản xuất B2B',
                              coverImage: item.imageUrl,
                              minOrderQty: 1,
                            );
                            ref.read(cartProvider.notifier).addToCart(dummyProduct, null, 1);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm "${item.productName}" vào giỏ hàng!'),
                                action: SnackBarAction(
                                  label: 'Xem giỏ',
                                  onPressed: () => context.push('/cart'),
                                ),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.favorite, color: AppColors.error, size: 22),
                          tooltip: 'Bỏ lưu yêu thích',
                          onPressed: () => _removeItem(item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openProductDetail(WishlistItem item) {
    final p = Product(
      id: item.productId,
      name: item.productName,
      basePrice: item.price,
      shopName: item.shopName ?? 'Xưởng sản xuất B2B',
      coverImage: item.imageUrl,
      minOrderQty: 1,
    );
    context.push('/product-detail', extra: p);
  }
}
