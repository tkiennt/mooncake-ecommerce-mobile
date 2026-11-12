import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import ProductCard from '../../components/common/ProductCard';
import { MOCK_PRODUCTS } from '../../api/apiClient';
import { useCatalogProducts } from '../../hooks/useCatalogProducts';

const INITIAL_RECENT_SEARCHES = [
  'Hộp Hoàng Triều VIP',
  'In ép kim logo công ty',
  'Bánh Lava trứng chảy',
  'Chiết khấu 35%',
];

export default function SearchScreen({ navigation }) {
  const [keyword, setKeyword] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [recentSearches, setRecentSearches] = useState(INITIAL_RECENT_SEARCHES);
  const [isFilterModalOpen, setIsFilterModalOpen] = useState(false);

  // Advanced Filter state
  const [priceRange, setPriceRange] = useState('all'); // all | under_500 | 500_800 | above_800
  const [isoOnly, setIsoOnly] = useState(false);

  const filterOptions = [
    { id: 'all', label: 'Tất cả' },
    { id: 'custom_pkg', label: 'Hỗ trợ In Logo' },
    { id: 'high_discount', label: 'Chiết khấu ≥ 15%' },
    { id: 'nuong', label: 'Bánh nướng nghệ nhân' },
    { id: 'deo', label: 'Bánh dẻo truyền thống' },
  ];

  const handleSelectRecent = (term) => {
    setKeyword(term);
  };

  const handleRemoveRecent = (term) => {
    setRecentSearches((prev) => prev.filter((t) => t !== term));
  };

  // Keyword goes to the API; quick filters below still refine the returned page locally.
  const catalog = useCatalogProducts({ q: keyword });
  const filtered = catalog.products.filter((item) => {
    const matchesKeyword =
      catalog.source === 'api' ||
      item.name.toLowerCase().includes(keyword.toLowerCase()) ||
      item.shopName.toLowerCase().includes(keyword.toLowerCase()) ||
      item.category.toLowerCase().includes(keyword.toLowerCase());

    if (!matchesKeyword) return false;

    // Quick tag filter
    if (filterType === 'custom_pkg' && !item.isCustomPackagingSupported) return false;
    if (filterType === 'high_discount') {
      const maxD = Math.max(...(item.tierPricing?.map((t) => t.discountPercent) || [0]));
      if (maxD < 15) return false;
    }
    if (filterType === 'nuong') {
      if (!(item.variants || []).some((v) => (v.crustType || '').toLowerCase().includes('nướng'))) return false;
    }
    if (filterType === 'deo') {
      if (!(item.variants || []).some((v) => (v.crustType || '').toLowerCase().includes('dẻo'))) return false;
    }

    // Advanced price range filter
    if (priceRange === 'under_500' && item.basePrice >= 500000) return false;
    if (priceRange === '500_800' && (item.basePrice < 500000 || item.basePrice > 800000)) return false;
    if (priceRange === 'above_800' && item.basePrice <= 800000) return false;

    return true;
  });

  return (
    <View style={styles.container}>
      <AppHeader
        title="Tìm Kiếm & Khám Phá"
        subtitle="Catalog bánh trung thu & xưởng đối tác"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <View style={styles.searchHeader}>
        {/* Search Input Box with Filter Button (Checklist Design Standard) */}
        <View style={styles.searchRow}>
          <View style={styles.searchInputWrapper}>
            <Ionicons name="search" size={18} color={COLORS.primary} />
            <TextInput
              style={styles.searchInput}
              placeholder="Tìm theo tên bánh, nhân vị, xưởng..."
              placeholderTextColor={COLORS.textMuted}
              value={keyword}
              onChangeText={setKeyword}
              autoFocus={false}
            />
            {keyword ? (
              <TouchableOpacity onPress={() => setKeyword('')} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                <Ionicons name="close-circle" size={18} color={COLORS.textMuted} />
              </TouchableOpacity>
            ) : null}
          </View>

          {/* Filter Bottom Sheet Trigger Button */}
          <TouchableOpacity
            style={[styles.filterSheetBtn, (priceRange !== 'all' || isoOnly) && styles.filterSheetBtnActive]}
            onPress={() => setIsFilterModalOpen(true)}
          >
            <Ionicons
              name="options-outline"
              size={18}
              color={priceRange !== 'all' || isoOnly ? '#FFFFFF' : COLORS.primary}
            />
          </TouchableOpacity>
        </View>

        {/* Ant Design Segmented Filter Scroll */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          style={styles.filterScroll}
          contentContainerStyle={styles.filterContainer}
        >
          {filterOptions.map((opt) => {
            const isActive = filterType === opt.id;
            return (
              <TouchableOpacity
                key={opt.id}
                style={[
                  styles.filterChip,
                  isActive && styles.filterChipActive,
                ]}
                onPress={() => setFilterType(opt.id)}
              >
                {isActive && (
                  <Ionicons name="checkmark-sharp" size={13} color={COLORS.primary} />
                )}
                <Text
                  style={[
                    styles.filterChipText,
                    isActive && styles.filterChipTextActive,
                  ]}
                >
                  {opt.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* RF-01: Recent Searches Bar (Khi chưa nhập gì và có lịch sử) */}
      {!keyword && recentSearches.length > 0 && (
        <View style={styles.recentSection}>
          <View style={styles.recentHeader}>
            <View style={styles.recentTitleWrap}>
              <Ionicons name="time-outline" size={14} color={COLORS.accent} />
              <Text style={styles.recentTitle}>Tìm kiếm gần đây</Text>
            </View>
            <TouchableOpacity onPress={() => setRecentSearches([])}>
              <Text style={styles.recentClearText}>Xóa tất cả</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.recentTagsWrap}>
            {recentSearches.map((term, idx) => (
              <View key={idx} style={styles.recentTag}>
                <TouchableOpacity onPress={() => handleSelectRecent(term)}>
                  <Text style={styles.recentTagText}>{term}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  onPress={() => handleRemoveRecent(term)}
                  hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}
                >
                  <Ionicons name="close" size={12} color={COLORS.textMuted} />
                </TouchableOpacity>
              </View>
            ))}
          </View>
        </View>
      )}

      {/* Results Count & Current Filter Summary */}
      <View style={styles.resultBar}>
        <Text style={styles.resultCount}>
          Tìm thấy <Text style={styles.resultCountHighlight}>{filtered.length}</Text> bộ quà tặng B2B
        </Text>
        {(keyword || filterType !== 'all' || priceRange !== 'all') && (
          <TouchableOpacity
            style={styles.resetBtn}
            onPress={() => {
              setKeyword('');
              setFilterType('all');
              setPriceRange('all');
            }}
          >
            <Ionicons name="refresh" size={12} color={COLORS.primary} />
            <Text style={styles.resetText}>Xóa bộ lọc</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Product List */}
      <ScrollView
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      >
        {filtered.length === 0 ? (
          /* RF-05: Polish Empty State theo chuẩn hoàng gia */
          <View style={styles.emptyContainer}>
            <View style={styles.moonIllustration}>
              <Ionicons name="moon" size={44} color={COLORS.accent} />
              <View style={styles.sparkleDot} />
            </View>
            <Text style={styles.emptyTitle}>Chưa tìm thấy hộp quà phù hợp</Text>
            <Text style={styles.emptyDesc}>
              Quý doanh nghiệp có thể thử từ khóa vị bánh khác hoặc gửi trực tiếp yêu cầu để 50+ xưởng nộp báo giá may đo riêng.
            </Text>
            <View style={styles.emptyActionsRow}>
              <TouchableOpacity
                style={styles.emptyResetBtn}
                onPress={() => {
                  setKeyword('');
                  setFilterType('all');
                  setPriceRange('all');
                }}
              >
                <Text style={styles.emptyResetText}>Xóa bộ lọc</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.emptyRfqBtn}
                onPress={() => navigation.navigate('CreateRfq')}
              >
                <Text style={styles.emptyRfqBtnText}>Mở thầu RFQ ngay</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          filtered.map((item) => (
            <ProductCard
              key={item.id}
              product={item}
              onPress={(p) => navigation.navigate('ProductDetail', { product: p })}
            />
          ))
        )}
        <View style={{ height: 40 }} />
      </ScrollView>

      {/* RF-01: Filter Bottom Sheet Modal */}
      <Modal
        visible={isFilterModalOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setIsFilterModalOpen(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.bottomSheet}>
            <View style={styles.sheetHandle} />

            <View style={styles.sheetHeader}>
              <Text style={styles.sheetTitle}>Bộ Lọc B2B Đa Chiều</Text>
              <TouchableOpacity onPress={() => setIsFilterModalOpen(false)}>
                <Ionicons name="close-circle-outline" size={24} color={COLORS.textSecondary} />
              </TouchableOpacity>
            </View>

            {/* Price Range Filter */}
            <Text style={styles.sheetSectionTitle}>Khoảng ngân sách dự toán:</Text>
            <View style={styles.sheetChipGroup}>
              {[
                { id: 'all', label: 'Mọi mức giá' },
                { id: 'under_500', label: '< 500.000 ₫' },
                { id: '500_800', label: '500k - 800k ₫' },
                { id: 'above_800', label: '> 800.000 ₫' },
              ].map((p) => {
                const isSelected = priceRange === p.id;
                return (
                  <TouchableOpacity
                    key={p.id}
                    style={[styles.sheetChip, isSelected && styles.sheetChipSelected]}
                    onPress={() => setPriceRange(p.id)}
                  >
                    <Text style={[styles.sheetChipText, isSelected && styles.sheetChipTextSelected]}>
                      {p.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            {/* Certification requirement */}
            <Text style={styles.sheetSectionTitle}>Tiêu chuẩn xưởng đối tác:</Text>
            <TouchableOpacity
              style={styles.sheetCheckRow}
              activeOpacity={0.8}
              onPress={() => setIsoOnly(!isoOnly)}
            >
              <Ionicons
                name={isoOnly ? 'checkbox' : 'square-outline'}
                size={20}
                color={COLORS.primary}
              />
              <Text style={styles.sheetCheckLabel}>
                Chỉ hiện xưởng đạt chứng nhận ISO 22000 & SafeTrade
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.sheetApplyBtn}
              onPress={() => setIsFilterModalOpen(false)}
            >
              <Text style={styles.sheetApplyText}>Áp dụng bộ lọc</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  searchHeader: {
    backgroundColor: COLORS.surface,
    paddingTop: 12,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  searchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 16,
    gap: 8,
  },
  searchInputWrapper: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.background,
    paddingHorizontal: 12,
    paddingVertical: 9,
    borderRadius: 8,
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
    gap: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 13,
    color: COLORS.textPrimary,
    padding: 0,
  },
  filterSheetBtn: {
    width: 40,
    height: 40,
    borderRadius: 8,
    backgroundColor: COLORS.background,
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
    alignItems: 'center',
    justifyContent: 'center',
  },
  filterSheetBtnActive: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  filterScroll: {
    marginTop: 10,
  },
  filterContainer: {
    paddingHorizontal: 16,
    gap: 8,
    paddingBottom: 4,
  },
  filterChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
    gap: 4,
  },
  filterChipActive: {
    backgroundColor: '#FFF1F0',
    borderColor: COLORS.primary,
    borderWidth: 1.5,
  },
  filterChipText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontWeight: '500',
  },
  filterChipTextActive: {
    color: COLORS.primary,
    fontWeight: '700',
  },

  // Recent Searches
  recentSection: {
    backgroundColor: COLORS.surface,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F5F0E6',
  },
  recentHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  recentTitleWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  recentTitle: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.accent,
  },
  recentClearText: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  recentTagsWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  recentTag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 4,
    gap: 6,
  },
  recentTagText: {
    fontSize: 11,
    color: COLORS.textPrimary,
  },

  resultBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  resultCount: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  resultCountHighlight: {
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  resetBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  resetText: {
    fontSize: 12,
    color: COLORS.primary,
    fontWeight: '600',
  },
  listContent: {
    paddingHorizontal: 16,
    paddingTop: 4,
  },

  // Empty state polish
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 45,
    paddingHorizontal: 32,
  },
  moonIllustration: {
    width: 76,
    height: 76,
    borderRadius: 38,
    backgroundColor: COLORS.accentGoldBg,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    borderColor: '#E8D2A3',
    position: 'relative',
    marginBottom: 14,
  },
  sparkleDot: {
    position: 'absolute',
    top: 14,
    right: 14,
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: COLORS.accent,
  },
  emptyTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 6,
    textAlign: 'center',
  },
  emptyDesc: {
    fontSize: 12,
    color: COLORS.textSecondary,
    textAlign: 'center',
    lineHeight: 18,
    marginBottom: 16,
  },
  emptyActionsRow: {
    flexDirection: 'row',
    gap: 10,
  },
  emptyResetBtn: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    backgroundColor: COLORS.surface,
  },
  emptyResetText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  emptyRfqBtn: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
  },
  emptyRfqBtnText: {
    color: COLORS.textWhite,
    fontSize: 12,
    fontWeight: '700',
  },

  // Modal Bottom Sheet
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  bottomSheet: {
    backgroundColor: COLORS.surface,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    padding: 20,
    borderTopWidth: 1.5,
    borderTopColor: COLORS.accent,
  },
  sheetHandle: {
    width: 36,
    height: 4,
    backgroundColor: '#D1C8B8',
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: 14,
  },
  sheetHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sheetTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  sheetSectionTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 8,
    marginTop: 4,
  },
  sheetChipGroup: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },
  sheetChip: {
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 8,
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  sheetChipSelected: {
    backgroundColor: '#FFF1F0',
    borderColor: COLORS.primary,
    borderWidth: 1.5,
  },
  sheetChipText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontWeight: '500',
  },
  sheetChipTextSelected: {
    color: COLORS.primary,
    fontWeight: '800',
  },
  sheetCheckRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 20,
  },
  sheetCheckLabel: {
    fontSize: 12,
    color: COLORS.textPrimary,
  },
  sheetApplyBtn: {
    backgroundColor: COLORS.primary,
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  sheetApplyText: {
    color: COLORS.textWhite,
    fontSize: 14,
    fontWeight: '700',
  },
});
