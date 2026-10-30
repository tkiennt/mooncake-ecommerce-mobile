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
    { id: 'nuong', label: 'Bánh nướng' },
    { id: 'deo', label: 'Bánh dẻo' },
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
      return item.variants.some((v) => v.crustType.includes('nướng'));
    }
    if (filterType === 'deo') {
      return item.variants.some((v) => v.crustType.includes('dẻo'));
    }
    return true;
  });

  return (
    <View style={styles.container}>
      <AppHeader
        title="Tìm Kiếm & Khám Phá"
        subtitle="Catalog bánh trung thu & xưởng sản xuất"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <View style={styles.searchHeader}>
        <View style={styles.searchInputWrapper}>
          <Ionicons name="search" size={18} color={COLORS.textMuted} />
          <TextInput
            style={styles.searchInput}
            placeholder="Tìm theo tên bánh, nhân vị, xưởng..."
            value={keyword}
            onChangeText={setKeyword}
            autoFocus={false}
          />
          {keyword ? (
            <TouchableOpacity onPress={() => setKeyword('')}>
              <Ionicons name="close-circle" size={18} color={COLORS.textMuted} />
            </TouchableOpacity>
          ) : null}
        </View>

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          style={styles.filterScroll}
          contentContainerStyle={styles.filterContainer}
        >
          {filterOptions.map((opt) => (
            <TouchableOpacity
              key={opt.id}
              style={[
                styles.filterChip,
                filterType === opt.id && styles.filterChipActive,
              ]}
              onPress={() => setFilterType(opt.id)}
            >
              <Text
                style={[
                  styles.filterChipText,
                  filterType === opt.id && styles.filterChipTextActive,
                ]}
              >
                {opt.label}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      <ScrollView contentContainerStyle={styles.listArea}>
        <Text style={styles.countText}>
          Tìm thấy <Text style={styles.bold}>{filtered.length}</Text> bộ sưu tập phù hợp
        </Text>

        {filtered.length > 0 ? (
          filtered.map((product) => (
            <ProductCard
              key={product.id}
              product={product}
              onPress={(p) => navigation.navigate('ProductDetail', { product: p })}
            />
          ))
        ) : (
          <View style={styles.emptyBox}>
            <Ionicons name="search-outline" size={48} color={COLORS.textMuted} />
            <Text style={styles.emptyTitle}>Không tìm thấy sản phẩm</Text>
            <Text style={styles.emptySub}>Thử tìm kiếm với từ khóa khác hoặc điều chỉnh bộ lọc.</Text>
          </View>
        )}
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
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  searchInputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F5F3EF',
    borderRadius: 8,
    paddingHorizontal: 12,
    height: 44,
  },
  searchInput: {
    flex: 1,
    marginLeft: 8,
    fontSize: 14,
    color: COLORS.textPrimary,
  },
  filterScroll: {
    marginTop: 10,
    marginBottom: 4,
  },
  filterContainer: {
    paddingRight: 16,
  },
  filterChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginRight: 8,
    backgroundColor: '#FFF',
  },
  filterChipActive: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  filterChipText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontWeight: '500',
  },
  filterChipTextActive: {
    color: '#FFF',
    fontWeight: '700',
  },
  listArea: {
    padding: 16,
    paddingBottom: 40,
  },
  countText: {
    fontSize: 13,
    color: COLORS.textSecondary,
    marginBottom: 12,
  },
  bold: {
    fontWeight: '700',
    color: COLORS.primary,
  },
  emptyBox: {
    alignItems: 'center',
    marginTop: 60,
    paddingHorizontal: 20,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: 12,
  },
  emptySub: {
    fontSize: 13,
    color: COLORS.textMuted,
    textAlign: 'center',
    marginTop: 6,
  },
});
