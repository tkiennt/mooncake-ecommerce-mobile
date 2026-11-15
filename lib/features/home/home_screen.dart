import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/product_grid_card.dart';
import '../../shared_widgets/lucian/announcement_pill.dart';
import '../../shared_widgets/lucian/recent_order_toast.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/category.dart';
import '../../data/repositories/catalog_repository.dart';

final homeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final catalogRepo = ref.watch(catalogRepositoryProvider);
  return catalogRepo.getCategories();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const List<double> imageRatios = [0.82, 1.0, 1.0, 0.82];

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

              // Recent Order Notification Toast
              const SliverToBoxAdapter(
                child: RecentOrderToast(
                  companyName: 'FPT Software',
                  boxCount: 350,
                  timeAgo: '12 phút trước',
                ),
              ),

              // Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bánh Trung Thu Mùa Vụ 2026',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      InkWell(
                        onTap: () => context.push('/search'),
                        child: const Row(
                          children: [
                            Text(
                              'Xem tất cả',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                            Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Products Feed or Skeleton or Error
              if (catalogState.isLoading && catalogState.products.isEmpty)
                _buildSkeletonFeed(context)
              else if (catalogState.errorMessage != null && catalogState.products.isEmpty)
                _buildErrorFeed(context, ref, catalogState.errorMessage!)
              else
                _buildProductsFeed(context, catalogState),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int cartCount, int notifCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          // Search Input Bar
          Expanded(
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tìm bánh trung thu, xưởng...',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Notification Bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: AppColors.primary, size: 24),
                onPressed: () => context.push('/notifications'),
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

          // Cart Icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 24),
                onPressed: () => context.push('/cart'),
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
      {'label': 'Báo giá RFQ', 'icon': Icons.description_outlined, 'route': '/create-rfq'},
      {'label': 'Tư vấn quà', 'icon': Icons.chat_bubble_outline, 'route': '/ai-assistant'},
      {'label': 'Hợp đồng', 'icon': Icons.assignment_outlined, 'route': '/contracts'},
      {'label': 'Giao hàng', 'icon': Icons.local_shipping_outlined, 'route': '/delivery-pod'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: shortcuts.map((s) {
          return InkWell(
            onTap: () => context.push(s['route'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.8),
                    boxShadow: AppTokens.shadowSubtle,
                  ),
                  child: Icon(s['icon'] as IconData, color: AppColors.primary, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  s['label'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Danh Mục Nổi Bật',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/search'),
                      child: const Text(
                        'Tất cả',
                        style: TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return ActionChip(
                      label: Text(cat.name),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border, width: 0.8),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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

  Widget _buildProductsFeed(BuildContext context, CatalogState catalogState) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemBuilder: (context, index) {
          // Index 0: Promo banner
          if (index == 0) {
            return _buildPromoBanner(context);
          }
          // Index 1: RFQ tile
          if (index == 1) {
            return _buildRfqTile(context);
          }

          // Products
          final productIndex = index - 2;
          if (productIndex < catalogState.products.length) {
            final product = catalogState.products[productIndex];
            final ratio = imageRatios[productIndex % imageRatios.length];
            return ProductGridCard(
              product: product,
              imageRatio: ratio,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildPromoBanner(context);
          }
          if (index == 1) {
            return _buildRfqTile(context);
          }

          final height = index % 2 == 0 ? 210.0 : 240.0;
          return Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.lucianRadiusLg)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: 6,
      ),
    );
  }

  Widget _buildErrorFeed(BuildContext context, WidgetRef ref, String error) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(homeCategoriesProvider);
                ref.read(catalogProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
        boxShadow: AppTokens.shadowCard,
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
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Mùa trăng 2026',
                    style: TextStyle(color: AppColors.textWhite, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quà Doanh Nghiệp',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Chiết khấu tới 35% · In logo',
                  style: TextStyle(color: AppColors.accentGoldLight, fontSize: 11),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentGoldBg,
        borderRadius: BorderRadius.circular(AppTokens.lucianRadiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1),
        boxShadow: AppTokens.shadowSubtle,
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
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gửi yêu cầu nhận ngay báo giá từ 10+ xưởng uy tín',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.push('/create-rfq'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Tạo RFQ ngay', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
