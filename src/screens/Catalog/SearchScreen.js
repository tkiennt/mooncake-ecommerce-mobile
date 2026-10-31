import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import ProductCard from '../../components/common/ProductCard';
import { MOCK_PRODUCTS } from '../../api/apiClient';

export default function SearchScreen({ navigation }) {
  const [keyword, setKeyword] = useState('');
  const [filterType, setFilterType] = useState('all');

  const filterOptions = [
    { id: 'all', label: 'Tất cả' },
    { id: 'custom_pkg', label: 'Hỗ trợ In Logo' },
    { id: 'high_discount', label: 'Chiết khấu ≥ 15%' },
    { id: 'nuong', label: 'Bánh nướng nghệ nhân' },
    { id: 'deo', label: 'Bánh dẻo truyền thống' },
  ];

  const filtered = MOCK_PRODUCTS.filter((item) => {
    const matchesKeyword =
      item.name.toLowerCase().includes(keyword.toLowerCase()) ||
      item.shopName.toLowerCase().includes(keyword.toLowerCase()) ||
      item.category.toLowerCase().includes(keyword.toLowerCase());

    if (!matchesKeyword) return false;

    if (filterType === 'custom_pkg') return item.isCustomPackagingSupported;
    if (filterType === 'high_discount') {
      const maxD = Math.max(...(item.tierPricing?.map((t) => t.discountPercent) || [0]));
      return maxD >= 15;
    }
    if (filterType === 'nuong') {
      return item.variants.some((v) => v.crustType.toLowerCase().includes('nướng'));
    }
    if (filterType === 'deo') {
      return item.variants.some((v) => v.crustType.toLowerCase().includes('dẻo'));
    }
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
        {/* Search Input Box with Ant Design Style */}
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

      {/* Results Count & Current Filter Summary */}
      <View style={styles.resultBar}>
        <Text style={styles.resultCount}>
          Tìm thấy <Text style={styles.resultCountHighlight}>{filtered.length}</Text> bộ quà tặng B2B
        </Text>
        {(keyword || filterType !== 'all') && (
          <TouchableOpacity
            style={styles.resetBtn}
            onPress={() => {
              setKeyword('');
              setFilterType('all');
            }}
          >
            <Ionicons name="refresh" size={12} color={COLORS.primary} />
            <Text style={styles.resetText}>Xóa lọc</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* Product List */}
      <ScrollView
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      >
        {filtered.length === 0 ? (
          <View style={styles.emptyContainer}>
            <Ionicons name="search-outline" size={48} color={COLORS.borderDark} />
            <Text style={styles.emptyTitle}>Không tìm thấy sản phẩm phù hợp</Text>
            <Text style={styles.emptyDesc}>
              Vui lòng thử từ khóa khác hoặc bấm nút "Tạo RFQ" để đặt bánh may đo theo yêu cầu doanh nghiệp.
            </Text>
            <TouchableOpacity
              style={styles.emptyRfqBtn}
              onPress={() => navigation.navigate('CreateRfq')}
            >
              <Text style={styles.emptyRfqBtnText}>Mở thầu RFQ ngay</Text>
            </TouchableOpacity>
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
  searchInputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.background,
    marginHorizontal: 16,
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
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
    paddingHorizontal: 32,
  },
  emptyTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: 14,
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
  emptyRfqBtn: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
  },
  emptyRfqBtnText: {
    color: COLORS.textWhite,
    fontSize: 13,
    fontWeight: '700',
  },
});
