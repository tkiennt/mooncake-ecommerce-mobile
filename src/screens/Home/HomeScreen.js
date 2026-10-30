import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  ImageBackground,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import ProductCard from '../../components/common/ProductCard';
import { MOCK_PRODUCTS } from '../../api/apiClient';
import { useAuth } from '../../context/AuthContext';

export default function HomeScreen({ navigation }) {
  const { user } = useAuth();
  const [selectedCategory, setSelectedCategory] = useState('Tất cả');

  const categories = ['Tất cả', 'Hộp Quà Cao Cấp', 'Set Doanh Nghiệp', 'Bánh Dẻo Nghệ Nhân', 'Lava Trứng Muối'];

  const filteredProducts = selectedCategory === 'Tất cả'
    ? MOCK_PRODUCTS
    : MOCK_PRODUCTS.filter((p) => p.category === selectedCategory);

  return (
    <View style={styles.container}>
      <AppHeader
        title="NGUYỆT PHỐ B2B"
        subtitle={user?.companyName || 'Sàn Quà Tặng Trung Thu Hoàng Gia'}
        rightIcon="notifications-outline"
        onRightPress={() => {}}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Search Bar Tap */}
        <TouchableOpacity
          style={styles.searchBar}
          activeOpacity={0.8}
          onPress={() => navigation.navigate('Search')}
        >
          <Ionicons name="search-outline" size={20} color={COLORS.textMuted} />
          <Text style={styles.searchPlaceholder}>Tìm bánh theo vị, xưởng hoặc mức chiết khấu...</Text>
          <Ionicons name="options-outline" size={18} color={COLORS.primary} />
        </TouchableOpacity>

        {/* Hero Banner */}
        <View style={styles.heroBanner}>
          <View style={styles.heroOverlay}>
            <View style={styles.tagBadge}>
              <Text style={styles.tagBadgeText}>MÙA TRĂNG 2026</Text>
            </View>
            <Text style={styles.heroTitle}>Đấu Thầu & Đặt Hàng B2B</Text>
            <Text style={styles.heroDesc}>
              Chiết khấu đến 18% cho đơn hàng doanh nghiệp từ 50 hộp. Miễn phí thiết kế & in ép kim logo công ty.
            </Text>
            <TouchableOpacity
              style={styles.heroCta}
              onPress={() => navigation.navigate('Search')}
            >
              <Text style={styles.heroCtaText}>Khám phá bộ sưu tập</Text>
              <Ionicons name="arrow-forward" size={14} color="#FFF" />
            </TouchableOpacity>
          </View>
        </View>

        {/* Trust Badges */}
        <View style={styles.trustRow}>
          <View style={styles.trustItem}>
            <Ionicons name="shield-checkmark" size={18} color={COLORS.accent} />
            <Text style={styles.trustText}>Ký quỹ SafeTrade</Text>
          </View>
          <View style={styles.trustDivider} />
          <View style={styles.trustItem}>
            <Ionicons name="document-text" size={18} color={COLORS.accent} />
            <Text style={styles.trustText}>e-Contract OTP</Text>
          </View>
          <View style={styles.trustDivider} />
          <View style={styles.trustItem}>
            <Ionicons name="snow" size={18} color={COLORS.accent} />
            <Text style={styles.trustText}>Xe lạnh PoD</Text>
          </View>
        </View>

        {/* Categories Bar */}
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Danh Mục Tuyển Chọn</Text>
        </View>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categoryScroll}
        >
          {categories.map((cat) => (
            <TouchableOpacity
              key={cat}
              style={[
                styles.categoryChip,
                selectedCategory === cat && styles.categoryChipActive,
              ]}
              onPress={() => setSelectedCategory(cat)}
            >
              <Text
                style={[
                  styles.categoryText,
                  selectedCategory === cat && styles.categoryTextActive,
                ]}
              >
                {cat}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Product List */}
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Bánh Nghệ Nhân Đang Mở Đặt</Text>
          <TouchableOpacity onPress={() => navigation.navigate('Search')}>
            <Text style={styles.seeAllText}>Xem tất cả ({MOCK_PRODUCTS.length})</Text>
          </TouchableOpacity>
        </View>

        {filteredProducts.map((prod) => (
          <ProductCard
            key={prod.id}
            product={prod}
            onPress={(p) => navigation.navigate('ProductDetail', { product: p })}
          />
        ))}

        {/* RFQ CTA Card */}
        <View style={styles.rfqCard}>
          <Ionicons name="briefcase-outline" size={28} color={COLORS.accent} />
          <View style={styles.rfqContent}>
            <Text style={styles.rfqTitle}>Cần đặt trên 500 hộp theo yêu cầu?</Text>
            <Text style={styles.rfqSub}>
              Mở thầu RFQ để nhận bảng giá cạnh tranh từ hơn 50 xưởng bánh đối tác.
            </Text>
          </View>
          <TouchableOpacity
            style={styles.rfqButton}
            onPress={() => navigation.navigate('Search')}
          >
            <Text style={styles.rfqBtnText}>Tạo RFQ</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 16,
  },
  searchPlaceholder: {
    flex: 1,
    fontSize: 13,
    color: COLORS.textMuted,
    marginLeft: 10,
  },
  heroBanner: {
    borderRadius: 14,
    overflow: 'hidden',
    backgroundColor: COLORS.primaryDark,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: 'rgba(212, 136, 6, 0.4)',
  },
  heroOverlay: {
    padding: 18,
  },
  tagBadge: {
    alignSelf: 'flex-start',
    backgroundColor: COLORS.accent,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
    marginBottom: 8,
  },
  tagBadgeText: {
    color: '#FFF',
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  heroTitle: {
    fontSize: 19,
    fontWeight: '800',
    color: '#FFF',
    marginBottom: 6,
  },
  heroDesc: {
    fontSize: 12,
    color: '#E8E1D5',
    lineHeight: 18,
    marginBottom: 14,
  },
  heroCta: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    backgroundColor: COLORS.primary,
    paddingVertical: 8,
    paddingHorizontal: 14,
    borderRadius: 6,
  },
  heroCtaText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '700',
    marginRight: 6,
  },
  trustRow: {
    flexDirection: 'row',
    backgroundColor: COLORS.surface,
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  trustItem: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    justifyContent: 'center',
  },
  trustText: {
    fontSize: 11,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginLeft: 6,
  },
  trustDivider: {
    width: 1,
    height: 18,
    backgroundColor: COLORS.border,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  seeAllText: {
    fontSize: 13,
    color: COLORS.primary,
    fontWeight: '600',
  },
  categoryScroll: {
    marginBottom: 20,
  },
  categoryChip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginRight: 8,
  },
  categoryChipActive: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  categoryText: {
    fontSize: 13,
    color: COLORS.textSecondary,
    fontWeight: '500',
  },
  categoryTextActive: {
    color: '#FFF',
    fontWeight: '700',
  },
  rfqCard: {
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 12,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
    marginBottom: 20,
  },
  rfqContent: {
    flex: 1,
    marginLeft: 12,
    marginRight: 10,
  },
  rfqTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#873800',
  },
  rfqSub: {
    fontSize: 11,
    color: '#614700',
    marginTop: 2,
    lineHeight: 16,
  },
  rfqButton: {
    backgroundColor: COLORS.accent,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
  },
  rfqBtnText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '700',
  },
});
