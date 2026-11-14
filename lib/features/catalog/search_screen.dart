import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_colors.dart';
import '../../shared_widgets/common/app_header.dart';
import '../../shared_widgets/common/product_grid_card.dart';
import '../../providers/catalog_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  static const List<String> categories = [
    'Tất cả',
    'Hộp quà cao cấp',
    'Bánh nướng truyền thống',
    'Bánh dẻo truyền thống',
    'Bánh dinh dưỡng & hạt',
  ];

  static const List<String> recentSearches = [
    'Hộp Hoàng Triều VIP',
    'In ép kim logo công ty',
    'Bánh Lava trứng chảy',
    'Chiết khấu 35%',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final filtered = catalogState.filteredProducts;

    return Scaffold(
      appBar: const AppHeader(
        title: 'Khám Phá Danh Mục',
        showBack: false,
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bánh, xưởng, vị bánh...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(catalogProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                ref.read(catalogProvider.notifier).setSearchQuery(val);
                setState(() {});
              },
            ),
          ),

          // Categories Horizontal Chips
          Container(
            height: 48,
            color: AppColors.surface,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = (catalogState.selectedCategory ?? 'Tất cả') == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.primaryTint,
                  backgroundColor: AppColors.surfaceHover,
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (_) => ref.read(catalogProvider.notifier).setCategory(cat),
                );
              },
            ),
          ),

          // Recent Searches if search query is empty
          if (_searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Gợi ý: ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: recentSearches.map((term) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () {
                                _searchController.text = term;
                                ref.read(catalogProvider.notifier).setSearchQuery(term);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(term, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

          // Product Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy sản phẩm phù hợp',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            ref.read(catalogProvider.notifier).setSearchQuery('');
                            ref.read(catalogProvider.notifier).setCategory('Tất cả');
                          },
                          child: const Text('Xem tất cả sản phẩm'),
                        ),
                      ],
                    ),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return ProductGridCard(
                        product: filtered[index],
                        onPress: (p) => context.push('/product-detail', extra: p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
