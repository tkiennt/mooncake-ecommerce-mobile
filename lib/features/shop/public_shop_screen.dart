import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/category.dart';
import '../../data/models/product.dart';
import '../../data/models/review.dart';
import '../../data/models/shop.dart';
import '../../data/repositories/shop_repository.dart';
import '../../shared_widgets/common/app_header.dart';
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
    return Scaffold(
      appBar: AppHeader(
        title: _shop?.name ?? 'Gian hàng B2B',
        showBack: true,
        onBack: () => context.pop(),
        rightIcon: Icons.share_outlined,
        onRightPress: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã sao chép liên kết gian hàng')),
          );
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _shop == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang tải thông tin xưởng sản xuất...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _shop == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_outlined, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy gian hàng',
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
                size: ButtonSize.small,
                onPress: _fetchShopData,
              ),
            ],
          ),
        ),
      );
    }

    final shop = _shop!;

    return NestedScrollView(
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
    );
  }

  Widget _buildShopHeader(ShopModel shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner Image
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 2.4,
              child: shop.bannerUrl != null && shop.bannerUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: shop.bannerUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildFallbackBanner(),
                    )
                  : _buildFallbackBanner(),
            ),
            Positioned(
              left: 16,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.accent),
                    SizedBox(width: 4),
                    Text(
                      'Xưởng Bánh Trung Thu Chính Thức',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Shop Profile Details
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accentGoldBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: shop.logoUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.storefront,
                              color: AppColors.accent,
                              size: 32,
                            ),
                          )
                        : const Icon(
                            Icons.storefront,
                            color: AppColors.accent,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: 14),

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
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount} đánh giá)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            const Text('·', style: TextStyle(color: AppColors.border)),
                            const SizedBox(width: 8),
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
              const SizedBox(height: 12),

              if (shop.description != null && shop.description!.isNotEmpty)
                Text(
                  shop.description!,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                ),
              const SizedBox(height: 14),

              // Chat action button
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      title: 'Nhắn tin với xưởng',
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
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
        const SizedBox(height: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategoryId == null,
                    selectedColor: AppColors.primaryTint,
                    backgroundColor: AppColors.surfaceHover,
                    onSelected: (_) => _filterByCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map((c) {
                    final isSelected = _selectedCategoryId == c.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: isSelected,
                        selectedColor: AppColors.primaryTint,
                        backgroundColor: AppColors.surfaceHover,
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
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Xưởng chưa đăng sản phẩm thuộc mục này',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
      children: [
        // ATTP Certification Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.security, color: AppColors.success, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Chứng nhận An toàn Vệ sinh Thực phẩm (ATTP)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Cơ sở sản xuất đã được thẩm định đạt tiêu chuẩn Quốc Gia về điều kiện vệ sinh ATTP số ATTP-2026/HN-0899 do Cục ATTP cấp.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge(Icons.check_circle_outline, 'Đạt chuẩn ISO 22000:2018'),
                  _buildBadge(Icons.ac_unit, 'Quy trình kiểm soát Cold-Chain 18-22°C'),
                  _buildBadge(Icons.verified_user_outlined, 'HACCP Codified Process'),
                  _buildBadge(Icons.assignment_turned_in_outlined, 'Xuất hóa đơn VAT & Hợp đồng B2B'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Workshop Capability Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'Chưa có đánh giá nào cho gian hàng này',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = _reviews[index];
        final formattedDate = DateFormat('dd/MM/yyyy').format(r.createdAt);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
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
                    borderRadius: BorderRadius.circular(8),
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
