import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_section_header.dart';
import '../../shared_widgets/common/app_product_card.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_price_tag.dart';
import '../../shared_widgets/lucian/announcement_pill.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/repositories/catalog_repository.dart';

final homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final catalogRepo = ref.watch(catalogRepositoryProvider);
  return catalogRepo.getCategories();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final cartTotals = ref.watch(cartProvider).totals;
    final unreadNotifCount = ref.watch(notificationProvider).unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(homeCategoriesProvider);
            await ref.read(catalogProvider.notifier).refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar / Search Header
              SliverToBoxAdapter(
                child: _buildHeader(context, cartTotals.totalItems, unreadNotifCount),
              ),

              // Announcement Pill
              const SliverToBoxAdapter(
                child: AnnouncementPill(),
              ),

              // Shortcuts Row (Khách hàng B2B)
              SliverToBoxAdapter(
                child: _buildShortcuts(context),
              ),

              // Real Categories Section
              SliverToBoxAdapter(
                child: _buildCategoriesSection(context, ref),
              ),

              // Gift Sets Carousel (Carousel set quà B2B theo mục 4 hàng #7)
              if (catalogState.products.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildGiftSetsCarousel(context, catalogState.products),
                ),

              // Main Products Section Header
              SliverToBoxAdapter(
                child: AppSectionHeader(
                  title: 'Bánh Trung Thu Mùa Vụ 2026',
                  subtitle: 'Chiết khấu sỉ trực tiếp từ xưởng sản xuất',
                  actionLabel: 'Xem tất cả',
                  onAction: () => context.push('/search'),
                ),
              ),

              // Products Feed or Skeleton or Error or Empty
              if (catalogState.isLoading && catalogState.products.isEmpty)
                _buildSkeletonFeed(context)
              else if (catalogState.errorMessage != null && catalogState.products.isEmpty)
                SliverToBoxAdapter(
                  child: AppErrorState(
                    title: 'Không thể tải danh sách sản phẩm',
                    message: catalogState.errorMessage,
                    onRetry: () {
                      ref.invalidate(homeCategoriesProvider);
                      ref.read(catalogProvider.notifier).refresh();
                    },
                  ),
                )
              else if (catalogState.products.isEmpty)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Chưa có sản phẩm',
                    message: 'Hiện chưa có sản phẩm nào cho mùa vụ này. Vui lòng quay lại sau.',
                    actionLabel: 'Tải lại',
                    onAction: () => ref.read(catalogProvider.notifier).refresh(),
                  ),
                )
              else
                _buildProductsFeed(context, catalogState),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppTokens.space2XL),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int cartCount, int notifCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceSM + 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          // Search Input Bar (min tap target >= 44px)
          Expanded(
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              child: Container(
                constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMD),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    SizedBox(width: AppTokens.spaceSM),
                    Expanded(
                      child: Text(
                        'Tìm bánh trung thu, xưởng...',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spaceSM),

          // Notification Bell (min tap target >= 44px)
          Stack(
            clipBehavior: Clip.none,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppTokens.minTapTarget,
                  minHeight: AppTokens.minTapTarget,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: 'Thông báo',
                  onPressed: () => context.push('/notifications'),
                ),
              ),
              if (notifCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                ),
            ],
          ),

          // Cart Icon (min tap target >= 44px)
          Stack(
            clipBehavior: Clip.none,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppTokens.minTapTarget,
                  minHeight: AppTokens.minTapTarget,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: 'Giỏ hàng',
                  onPressed: () => context.push('/cart'),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surface, width: 1.5),
                    ),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: AppColors.textWhite,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts(BuildContext context) {
    final shortcuts = [
      {'label': 'Danh mục', 'icon': Icons.grid_view_outlined, 'route': '/search'},
      {'label': 'Nhận báo giá', 'icon': Icons.description_outlined, 'route': '/create-rfq'},
      {'label': 'Tư vấn quà', 'icon': Icons.chat_bubble_outline, 'route': '/ai-assistant'},
      {'label': 'Hợp đồng', 'icon': Icons.assignment_outlined, 'route': '/contracts'},
      {'label': 'Giao hàng', 'icon': Icons.local_shipping_outlined, 'route': '/delivery-pod'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceLG,
        vertical: AppTokens.spaceMD,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: shortcuts.map((s) {
          return InkWell(
            onTap: () => context.push(s['route'] as String),
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppTokens.minTapTarget,
                minHeight: AppTokens.minTapTarget,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                      border: Border.all(color: AppColors.border, width: 0.8),
                      boxShadow: AppTokens.elevationSubtle,
                    ),
                    child: Icon(s['icon'] as IconData, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s['label'] as String,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.spaceSM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionHeader(
                title: 'Danh mục nổi bật',
                actionLabel: 'Tất cả',
                onAction: () => context.push('/search'),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppTokens.spaceSM),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return ActionChip(
                      label: Text(cat.name),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border, width: 0.8),
                      labelStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      onPressed: () => context.push('/search'),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildGiftSetsCarousel(BuildContext context, List<Product> products) {
    final giftSets = products.where((p) {
      final cat = p.category.toLowerCase();
      final name = p.name.toLowerCase();
      return p.isCustomPackagingSupported ||
          cat.contains('quà') ||
          cat.contains('hộp') ||
          name.contains('hộp') ||
          name.contains('set');
    }).toList();

    final displayGiftSets = giftSets.isNotEmpty ? giftSets : products.take(6).toList();
    if (displayGiftSets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Hộp quà doanh nghiệp',
          subtitle: 'In logo riêng & thiệp tri ân trang trọng',
          actionLabel: 'Xem thêm',
          onAction: () => context.push('/search'),
        ),
        SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG),
            itemCount: displayGiftSets.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppTokens.spaceMD),
            itemBuilder: (context, index) {
              final product = displayGiftSets[index];
              return _buildGiftSetCard(context, product);
            },
          ),
        ),
        const SizedBox(height: AppTokens.spaceMD),
      ],
    );
  }

  Widget _buildGiftSetCard(BuildContext context, Product product) {
    final hasCustomPackaging = product.isCustomPackagingSupported;

    TierPricing? bestTier;
    for (final tier in product.tierPricing) {
      if (tier.discountPercent > 0) {
        if (bestTier == null || tier.discountPercent > bestTier.discountPercent) {
          bestTier = tier;
        }
      }
    }

    return Container(
      width: 172,
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
          onTap: () => context.push('/product-detail', extra: product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              AspectRatio(
                aspectRatio: 1.15,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCardImage(product.coverImage),
                    if (hasCustomPackaging)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGoldBg,
                            borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                            border: Border.all(color: AppColors.accent, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_fix_high, size: 9, color: AppColors.accent),
                              SizedBox(width: 3),
                              Text(
                                'In logo',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTokens.spaceSM + 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AppPriceTag(
                      price: product.basePrice,
                      size: AppPriceTagSize.small,
                      isBold: true,
                    ),
                    const SizedBox(height: 4),
                    if (bestTier != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.accentGoldBg,
                          borderRadius: BorderRadius.circular(AppTokens.radiusSM),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          'Sỉ chiết khấu tới ${bestTier.discountPercent.toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Text(
                        'Từ ${product.minOrderQty} ${product.unit.isNotEmpty ? product.unit : 'hộp'}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
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

  Widget _buildCardImage(String? image) {
    if (image == null || image.isEmpty) {
      return Container(
        color: AppColors.surfaceHover,
        child: const Center(
          child: Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 28),
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
            child: Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 28),
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
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surfaceHover,
        child: const Center(
          child: Icon(Icons.cake_outlined, color: AppColors.textMuted, size: 28),
        ),
      ),
    );
  }

  Widget _buildProductsFeed(BuildContext context, CatalogState catalogState) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: AppTokens.spaceSM),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppTokens.spaceMD,
        crossAxisSpacing: AppTokens.spaceMD,
        itemBuilder: (context, index) {
          // Index 0: Promo banner
          if (index == 0) {
            return _buildPromoBanner(context);
          }
          // Index 1: RFQ tile
          if (index == 1) {
            return _buildRfqTile(context);
          }

          final productIndex = index - 2;
          if (productIndex < catalogState.products.length) {
            final product = catalogState.products[productIndex];
            return AppProductCard(
              product: product,
              onPress: (p) => context.push('/product-detail', extra: p),
            );
          }
          return const SizedBox.shrink();
        },
        childCount: catalogState.products.length + 2,
      ),
    );
  }

  Widget _buildSkeletonFeed(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: AppTokens.spaceSM),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppTokens.spaceMD,
        crossAxisSpacing: AppTokens.spaceMD,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildPromoBanner(context);
          }
          if (index == 1) {
            return _buildRfqTile(context);
          }
          return AppSkeleton.productCard();
        },
        childCount: 6,
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        boxShadow: AppTokens.elevationCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.asset(
            'assets/products/promo-banner.jpg',
            fit: BoxFit.cover,
            height: 190,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(height: 190, color: AppColors.primaryDark),
          ),
          Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppTokens.radiusXS),
                  ),
                  child: const Text(
                    'Mùa trăng 2026',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: AppColors.textWhite,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quà doanh nghiệp',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Chiết khấu tới 35% · In logo',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: AppColors.accentGoldLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRfqTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMD + 2),
      decoration: BoxDecoration(
        color: AppColors.accentGoldBg,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
        boxShadow: AppTokens.elevationSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business_center_outlined, color: AppColors.textWhite, size: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Đặt trên 500 hộp?',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gửi yêu cầu nhận ngay báo giá từ 10+ xưởng uy tín',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
            child: ElevatedButton(
              onPressed: () => context.push('/create-rfq'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                ),
              ),
              child: const Text('Nhận báo giá ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
