import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/product_grid_card.dart';
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
    'Hộp Hoàng Triều VIP',
    'Bánh nướng thập cẩm',
    'Bánh Lava trứng chảy',
    'Hộp quà doanh nghiệp',
    'In ép kim logo',
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
          _errorMessage = 'Không thể tải danh sách sản phẩm. Vui lòng thử lại sau.';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
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
                          'Bộ Lọc Tìm Kiếm',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
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
                            style: TextStyle(color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),

                    // Sắp xếp
                    const Text(
                      'Sắp xếp theo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                          onSelected: (_) {
                            setSheetState(() => tempSort = entry.key);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Khoảng giá
                    const Text(
                      'Khoảng giá (VNĐ)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Từ',
                              suffixText: '₫',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    const SizedBox(height: 10),
                    // Preset price chips
                    Wrap(
                      spacing: 8,
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
                    const SizedBox(height: 18),

                    // In logo / Hộp quà tùy chỉnh
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
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
                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
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
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
        title: 'Khám Phá Danh Mục',
        showBack: false,
      ),
      body: Column(
        children: [
          // Search & Filter Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm bánh, xưởng, vị bánh...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadProducts(isRefresh: true);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) => _loadProducts(isRefresh: true),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter Button
                InkWell(
                  onTap: _openFilterBottomSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasActiveFilter ? AppColors.primaryTint : AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasActiveFilter ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Stack(
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
                              width: 7,
                              height: 7,
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
              ],
            ),
          ),

          // Categories Horizontal Chips
          Container(
            height: 48,
            color: AppColors.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    labelStyle: TextStyle(
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
                      labelStyle: TextStyle(
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
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Text('Gợi ý: ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceHover,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  term,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 52, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _loadProducts(isRefresh: true),
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
            ),
          ),
        ],
      );
    }

    if (_products.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: _products.length,
            itemBuilder: (context, index) {
              return ProductGridCard(
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
                  'Đã hiển thị tất cả sản phẩm',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        const Icon(Icons.search_off_outlined, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text(
          'Không tìm thấy sản phẩm phù hợp',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hãy thử điều chỉnh từ khoá, mức giá hoặc loại bỏ các tiêu chí lọc.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton.icon(
            onPressed: _resetAllFilters,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Xoá tất cả bộ lọc'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Gợi ý tìm kiếm phổ biến:',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSuggestions.map((term) {
            return InkWell(
              onTap: () {
                _searchController.text = term;
                _loadProducts(isRefresh: true);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTokens.shadowSubtle,
                ),
                child: Text(
                  term,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MasonryGridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 6,
        itemBuilder: (context, index) {
          final height = index % 2 == 0 ? 220.0 : 250.0;
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
      ),
    );
  }
}
