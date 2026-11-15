import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/models/review.dart';
import '../../data/models/shop.dart';
import '../../data/repositories/shop_repository.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/custom_button.dart';
import '../../shared_widgets/common/product_grid_card.dart';

class PublicShopScreen extends ConsumerStatefulWidget {
  final String slug;

  const PublicShopScreen({super.key, required this.slug});

  @override
  ConsumerState<PublicShopScreen> createState() => _PublicShopScreenState();
}

class _PublicShopScreenState extends ConsumerState<PublicShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ShopModel? _shop;
  List<Product> _products = [];
  List<Category> _categories = [];
  List<ReviewModel> _reviews = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchShopData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchShopData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(shopRepositoryProvider);
      final shop = await repo.getShop(widget.slug);
      final productsFuture = repo.getShopProducts(widget.slug);
      final categoriesFuture = repo.getShopCategories(widget.slug);
      final reviewsFuture = repo.getShopReviews(widget.slug);

      final results = await Future.wait([
        productsFuture,
        categoriesFuture,
        reviewsFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _shop = shop;
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
        _reviews = results[2] as List<ReviewModel>;
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

  Future<void> _filterByCategory(String? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _isLoading = true;
    });

    try {
      final repo = ref.read(shopRepositoryProvider);
      final filtered = await repo.getShopProducts(
        widget.slug,
        categoryId: categoryId,
      );
      if (!mounted) return;
      setState(() {
        _products = filtered;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh mục: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _shop == null) {
      return Scaffold(
        appBar: const AppHeader(
          title: 'Gian Hàng Doanh Nghiệp',
          showBack: true,
        ),
        body: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            AppSkeleton.shimmer(
              child: Container(
                height: 140,
                color: AppColors.shimmerBase,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceLG),
              child: AppSkeleton.listTile(),
            ),
            AppSkeleton.productGrid(count: 4),
          ],
        ),
      );
    }

    if (_errorMessage != null && _shop == null) {
      return Scaffold(
        appBar: const AppHeader(
          title: 'Gian Hàng Doanh Nghiệp',
          showBack: true,
        ),
        body: AppErrorState(
          icon: Icons.storefront_outlined,
          title: 'Không tìm thấy gian hàng',
          message: _errorMessage,
          retryLabel: 'Thử lại',
          onRetry: _fetchShopData,
        ),
      );
    }

    final shop = _shop!;

    return Scaffold(
      appBar: AppHeader(
        title: shop.name,
        showBack: true,
        onBack: () => context.pop(),
        rightIcon: Icons.share_outlined,
        onRightPress: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã sao chép liên kết gian hàng chính thức!')),
          );
        },
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildShopHeader(shop),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                  tabs: [
                    Tab(text: 'Sản phẩm (${_products.length})'),
                    const Tab(text: 'Chứng nhận & ATTP'),
                    Tab(text: 'Đánh giá (${_reviews.length})'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(),
            _buildCertificationsTab(shop),
            _buildReviewsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildShopHeader(ShopModel shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cover Banner chuẩn hóa chiều cao 140px theo chuẩn Shopee Official Store (Benchmark mục 5)
        SizedBox(
          height: 140,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              shop.bannerUrl != null && shop.bannerUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: shop.bannerUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildFallbackBanner(),
                    )
                  : _buildFallbackBanner(),
              // Gradient che phủ tạo độ tương phản
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              // Huy hiệu Official Store Hoàng Gia
              Positioned(
                left: AppTokens.spaceLG,
                bottom: AppTokens.spaceSM,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    boxShadow: AppTokens.shadowSubtle,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: AppColors.accentGoldLight),
                      SizedBox(width: 6),
                      Text(
                        'OFFICIAL STORE • XƯỞNG BÁNH CHÍNH THỨC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Shop Profile Details
        Container(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.accentGoldBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: shop.logoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.storefront,
                              color: AppColors.accent,
                              size: 28,
                            ),
                          )
                        : const Icon(
                            Icons.storefront,
                            color: AppColors.accent,
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: AppTokens.spaceMD),

                  // Name & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shop.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            if (shop.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 18, color: AppColors.primary),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount} đánh giá)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentGoldBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Điểm uy tín ${shop.reputationScore.toStringAsFixed(0)}/100',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (shop.address != null && shop.address!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shop.address!,
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spaceSM),

              if (shop.description != null && shop.description!.isNotEmpty)
                Text(
                  shop.description!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                ),
              const SizedBox(height: AppTokens.spaceMD),

              // Chat and B2B Action Buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      title: 'Nhắn tin với xưởng',
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                      size: ButtonSize.medium,
                      onPress: () {
                        context.push(
                          '/chat?shopId=${shop.id}&shopName=${Uri.encodeComponent(shop.name)}',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceSM),
      ],
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.storefront,
          size: 54,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Column(
      children: [
        // Category horizontal scroll
        if (_categories.isNotEmpty)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _selectedCategoryId == null,
                      selectedColor: AppColors.primaryTint,
                      backgroundColor: AppColors.surfaceHover,
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == null ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => _filterByCategory(null),
                    ),
                  ),
                  ..._categories.map((c) {
                    final isSelected = _selectedCategoryId == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTint,
                        backgroundColor: AppColors.surfaceHover,
                        labelStyle: TextStyle(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => _filterByCategory(c.id),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // Products Grid
        Expanded(
          child: _products.isEmpty
              ? AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Chưa có sản phẩm',
                  message: _selectedCategoryId != null
                      ? 'Xưởng chưa đăng sản phẩm nào trong danh mục này.'
                      : 'Xưởng hiện đang cập nhật danh mục sản phẩm bánh trung thu mới.',
                  actionLabel: _selectedCategoryId != null ? 'Xem tất cả sản phẩm' : null,
                  onAction: _selectedCategoryId != null ? () => _filterByCategory(null) : null,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppTokens.spaceLG),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductGridCard(
                      product: product,
                      onPress: (p) => context.push('/product-detail', extra: p),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCertificationsTab(ShopModel shop) {
    return ListView(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      children: [
        // ATTP Certification Card
        Container(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.shadowSubtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: AppColors.success, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chứng nhận An toàn Thực phẩm (ATTP)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Cơ sở sản xuất đã được thẩm định đạt tiêu chuẩn Quốc Gia về điều kiện vệ sinh ATTP số ATTP-2026/HN-0899 do Cục ATTP cấp.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge(Icons.check_circle_outline, 'Đạt chuẩn ISO 22000:2018'),
                  _buildBadge(Icons.ac_unit, 'Kiểm soát Cold-Chain 18-22°C'),
                  _buildBadge(Icons.verified_user_outlined, 'Quy trình chuẩn HACCP'),
                  _buildBadge(Icons.assignment_turned_in_outlined, 'Hóa đơn VAT & Hợp đồng B2B'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceMD),

        // Workshop Capability Card
        Container(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.shadowSubtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Năng lực sản xuất & Thu mua sỉ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoRow('Công suất cung ứng:', 'Lên đến 15.000 hộp quà/mùa vụ'),
              _buildInfoRow('Dịch vụ in Logo:', 'In lụa, ép kim hộp cứng từ 50 hộp'),
              _buildInfoRow('Khu vực xưởng:', shop.regionCode ?? 'Miền Bắc & Miền Nam'),
              _buildInfoRow('Địa chỉ cơ sở:', shop.address ?? 'Khu Công Nghiệp Bánh Mứt Kẹo'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentGoldBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return const AppEmptyState(
        icon: Icons.rate_review_outlined,
        title: 'Chưa có đánh giá',
        message: 'Gian hàng chưa nhận được đánh giá nào từ khách hàng.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _reviews[index];
        final formattedDate = DateFormat('dd/MM/yyyy').format(r.createdAt);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTokens.shadowSubtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryTint,
                        child: Text(
                          r.authorName.isNotEmpty ? r.authorName[0] : 'K',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r.authorName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (star) {
                  return Icon(
                    star < r.rating ? Icons.star : Icons.star_border,
                    size: 15,
                    color: AppColors.accent,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                r.comment.isNotEmpty ? r.comment : 'Khách hàng không để lại nhận xét.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
              ),
              if (r.reply != null && r.reply!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                    border: const Border(
                      left: BorderSide(color: AppColors.accent, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phản hồi từ gian hàng:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.reply!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _TabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
