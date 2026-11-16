import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/app_product_card.dart';
import '../../shared_widgets/common/app_skeleton.dart';
import '../../shared_widgets/common/app_empty_state.dart';
import '../../shared_widgets/common/app_error_state.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.initialCategory,
    this.initialQuery,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  List<Category> _categories = [];
  String? _selectedCategoryId;

  // Filters & Sorting
  double? _minPrice;
  double? _maxPrice;
  String _sort = 'relevance';
  bool _customPackagingOnly = false;

  // Pagination & Data
  List<Product> _products = [];
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  static const List<String> _popularSuggestions = [
    'Hộp quà Trăng Rằm',
    'Bánh nướng thập cẩm',
    'Bánh Lava trứng chảy',
    'Hộp quà doanh nghiệp',
    'In logo doanh nghiệp',
    'Bánh dẻo hạt sen',
  ];

  static const Map<String, String> _sortOptions = {
    'relevance': 'Phù hợp nhất',
    'newest': 'Mới nhất',
    'bestSelling': 'Bán chạy nhất',
    'priceAsc': 'Giá: Thấp đến cao',
    'priceDesc': 'Giá: Cao đến thấp',
    'rating': 'Đánh giá cao',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadInitialData() async {
    final catalogRepo = ref.read(catalogRepositoryProvider);
    try {
      final fetchedCategories = await catalogRepo.getCategories();
      if (mounted) {
        setState(() {
          _categories = fetchedCategories;
          if (widget.initialCategory != null) {
            final match = fetchedCategories.where((c) => c.name == widget.initialCategory).firstOrNull;
            if (match != null) {
              _selectedCategoryId = match.id;
            }
          }
        });
      }
    } catch (_) {
      // Best effort for category tags
    }

    await _loadProducts(isRefresh: true);
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final catalogRepo = ref.read(catalogRepositoryProvider);
    final queryText = _searchController.text.trim();

    try {
      final items = await catalogRepo.getProducts(
        page: _currentPage,
        pageSize: _pageSize,
        search: queryText.isNotEmpty ? queryText : null,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        customPackagingOnly: _customPackagingOnly ? true : null,
        sort: _sort,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _products = items;
          } else {
            _products.addAll(items);
          }
          _hasMore = items.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Chưa tải được danh sách bánh, bạn thử lại sau nhé.';
        });
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    final catalogRepo = ref.read(catalogRepositoryProvider);
    final nextPage = _currentPage + 1;
    final queryText = _searchController.text.trim();

    try {
      final items = await catalogRepo.getProducts(
        page: nextPage,
        pageSize: _pageSize,
        search: queryText.isNotEmpty ? queryText : null,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        customPackagingOnly: _customPackagingOnly ? true : null,
        sort: _sort,
      );

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _products.addAll(items);
          _hasMore = items.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadProducts(isRefresh: true);
    });
    setState(() {});
  }

  void _resetAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoryId = null;
      _minPrice = null;
      _maxPrice = null;
      _sort = 'relevance';
      _customPackagingOnly = false;
    });
    _loadProducts(isRefresh: true);
  }

  void _openFilterBottomSheet() {
    double? tempMinPrice = _minPrice;
    double? tempMaxPrice = _maxPrice;
    String tempSort = _sort;
    bool tempCustomPackaging = _customPackagingOnly;

    final minPriceController = TextEditingController(
      text: _minPrice != null ? _minPrice!.toInt().toString() : '',
    );
    final maxPriceController = TextEditingController(
      text: _maxPrice != null ? _maxPrice!.toInt().toString() : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: AppTokens.spaceLG,
                right: AppTokens.spaceLG,
                top: AppTokens.spaceLG,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc tìm kiếm',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppTokens.minTapTarget,
                            minWidth: AppTokens.minTapTarget,
                          ),
                          child: TextButton(
                            onPressed: () {
                              setSheetState(() {
                                tempMinPrice = null;
                                tempMaxPrice = null;
                                tempSort = 'relevance';
                                tempCustomPackaging = false;
                                minPriceController.clear();
                                maxPriceController.clear();
                              });
                            },
                            child: const Text(
                              'Thiết lập lại',
                              style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppTokens.spaceMD),

                    // Sắp xếp
                    const Text(
                      'Sắp xếp theo',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceSM),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sortOptions.entries.map((entry) {
                        final isSelected = tempSort == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          selectedColor: AppColors.primaryTint,
                          backgroundColor: AppColors.surfaceHover,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          labelStyle: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          ),
                          onSelected: (_) {
                            setSheetState(() => tempSort = entry.key);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTokens.spaceLG),

                    // Khoảng giá
                    const Text(
                      'Khoảng giá (VNĐ)',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceSM),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Từ',
                              suffixText: '₫',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            onChanged: (val) {
                              tempMinPrice = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('-', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Đến',
                              suffixText: '₫',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                            ),
                            onChanged: (val) {
                              tempMaxPrice = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceSM + 2),
                    // Preset price chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildPresetPriceChip('< 500k', null, 500000, setSheetState, minPriceController, maxPriceController, (min, max) {
                          tempMinPrice = min;
                          tempMaxPrice = max;
                        }),
                        _buildPresetPriceChip('500k - 1tr', 500000, 1000000, setSheetState, minPriceController, maxPriceController, (min, max) {
                          tempMinPrice = min;
                          tempMaxPrice = max;
                        }),
                        _buildPresetPriceChip('1tr - 2tr', 1000000, 2000000, setSheetState, minPriceController, maxPriceController, (min, max) {
                          tempMinPrice = min;
                          tempMaxPrice = max;
                        }),
                        _buildPresetPriceChip('> 2tr', 2000000, null, setSheetState, minPriceController, maxPriceController, (min, max) {
                          tempMinPrice = min;
                          tempMaxPrice = max;
                        }),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceLG),

                    // In logo / Hộp quà tùy chỉnh
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHover,
                        borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_fix_high, size: 18, color: AppColors.accent),
                              SizedBox(width: 8),
                              Text(
                                'Chỉ hiện sản phẩm hỗ trợ in logo',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: tempCustomPackaging,
                            activeThumbColor: AppColors.accent,
                            onChanged: (val) {
                              setSheetState(() => tempCustomPackaging = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2XL),

                    // Apply Button (min height 48px)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTokens.radiusDefault),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _minPrice = tempMinPrice;
                            _maxPrice = tempMaxPrice;
                            _sort = tempSort;
                            _customPackagingOnly = tempCustomPackaging;
                          });
                          _loadProducts(isRefresh: true);
                        },
                        child: const Text(
                          'Áp dụng bộ lọc',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceXL),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetPriceChip(
    String label,
    double? min,
    double? max,
    void Function(void Function()) setSheetState,
    TextEditingController minCtrl,
    TextEditingController maxCtrl,
    void Function(double?, double?) onApply,
  ) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      backgroundColor: AppColors.surfaceHover,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      onPressed: () {
        setSheetState(() {
          minCtrl.text = min != null ? min.toInt().toString() : '';
          maxCtrl.text = max != null ? max.toInt().toString() : '';
          onApply(min, max);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = _minPrice != null ||
        _maxPrice != null ||
        _sort != 'relevance' ||
        _customPackagingOnly;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Danh mục sản phẩm',
        showBack: false,
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceLG,
              vertical: AppTokens.spaceSM,
            ),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm bánh trung thu, xưởng bánh...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: AppTokens.minTapTarget,
                                minHeight: AppTokens.minTapTarget,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadProducts(isRefresh: true);
                                },
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _loadProducts(isRefresh: true),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSM),
                // Filter Button (tap target >= 44px)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openFilterBottomSheet,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppTokens.minTapTarget,
                        minHeight: AppTokens.minTapTarget,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: hasActiveFilter ? AppColors.primaryTint : AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          border: Border.all(
                            color: hasActiveFilter ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.tune,
                              size: 20,
                              color: hasActiveFilter ? AppColors.primary : AppColors.textSecondary,
                            ),
                            if (hasActiveFilter)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Categories Horizontal Chips
          Container(
            height: 48,
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLG, vertical: 6),
              children: [
                // "Tất cả" chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedCategoryId == null,
                    selectedColor: AppColors.primaryTint,
                    backgroundColor: AppColors.surfaceHover,
                    side: BorderSide(
                      color: _selectedCategoryId == null ? AppColors.primary : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                    labelStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                      color: _selectedCategoryId == null ? AppColors.primary : AppColors.textSecondary,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategoryId = null;
                      });
                      _loadProducts(isRefresh: true);
                    },
                  ),
                ),
                ..._categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: AppColors.primaryTint,
                      backgroundColor: AppColors.surfaceHover,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                      ),
                      labelStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                        _loadProducts(isRefresh: true);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Search Suggestions if search bar is empty
          if (_searchController.text.isEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceLG,
                AppTokens.spaceXS + 2,
                AppTokens.spaceLG,
                AppTokens.spaceSM,
              ),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Text(
                    'Gợi ý: ',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _popularSuggestions.map((term) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                _searchController.text = term;
                                _loadProducts(isRefresh: true);
                              },
                              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHover,
                                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  term,
                                  style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Results / Empty / Skeleton Body
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _loadProducts(isRefresh: true),
              child: _buildResultBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBody() {
    if (_isLoading && _products.isEmpty) {
      return _buildSkeletonGrid();
    }

    if (_errorMessage != null && _products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: AppErrorState(
              title: 'Chưa tải được danh sách bánh',
              message: _errorMessage,
              onRetry: () => _loadProducts(isRefresh: true),
            ),
          ),
        ],
      );
    }

    if (_products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: AppEmptyState(
              icon: Icons.search_off_outlined,
              title: 'Chưa tìm thấy bánh phù hợp',
              message: 'Bạn thử đổi từ khoá tìm kiếm hoặc đặt lại bộ lọc nhé.',
              actionLabel: 'Đặt lại bộ lọc',
              onAction: _resetAllFilters,
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppTokens.spaceLG),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppTokens.spaceMD,
            crossAxisSpacing: AppTokens.spaceMD,
            childCount: _products.length,
            itemBuilder: (context, index) {
              return AppProductCard(
                product: _products[index],
                onPress: (p) => context.push('/product-detail', extra: p),
              );
            },
          ),
        ),
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
          ),
        if (!_hasMore && _products.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Đã hiển thị tất cả',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spaceLG),
      child: MasonryGridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppTokens.spaceMD,
        crossAxisSpacing: AppTokens.spaceMD,
        itemCount: 6,
        itemBuilder: (context, index) {
          return AppSkeleton.productCard();
        },
      ),
    );
  }
}
