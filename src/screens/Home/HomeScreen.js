import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import ProductCard from '../../components/common/ProductCard';
import { MOCK_PRODUCTS } from '../../api/apiClient';
import { useAuth } from '../../context/AuthContext';
import AnnouncementPill from '../../components/lucian/AnnouncementPill';
import TrustSecurityBadges from '../../components/lucian/TrustSecurityBadges';

export default function HomeScreen({ navigation }) {
  const { user } = useAuth();
  const [selectedCategory, setSelectedCategory] = useState('Tất cả');

  const categories = [
    { label: 'Tất cả', count: 6 },
    { label: 'Hộp Quà Cao Cấp', count: 3 },
    { label: 'Set Doanh Nghiệp', count: 2 },
    { label: 'Bánh Dẻo Nghệ Nhân', count: 1 },
    { label: 'Lava Trứng Muối', count: 2 },
  ];

  const filteredProducts = selectedCategory === 'Tất cả'
    ? MOCK_PRODUCTS
    : MOCK_PRODUCTS.filter((p) => p.category === selectedCategory);

  return (
    <View style={styles.container}>
      <AppHeader
        title="NGUYỆT PHỐ B2B"
        subtitle={user?.companyName || 'Sàn Quà Tặng Trung Thu Hoàng Gia'}
        rightIcon="notifications-outline"
        onRightPress={() => navigation.navigate('Notification')}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* 1. Lucian Announcement Pill */}
        <AnnouncementPill />

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

        {/* AI Assistant Quick Pill */}
        <TouchableOpacity
          style={styles.aiPill}
          activeOpacity={0.85}
          onPress={() => navigation.navigate('AiAssistant')}
        >
          <View style={styles.aiPillLeft}>
            <Ionicons name="sparkles" size={16} color={COLORS.accent} />
            <Text style={styles.aiPillTitle}>Trợ Lý AI Nguyệt Phố:</Text>
            <Text style={styles.aiPillSub} numberOfLines={1}>Tư vấn quà tặng theo ngân sách & văn hóa</Text>
          </View>
          <Ionicons name="chevron-forward" size={14} color={COLORS.primary} />
        </TouchableOpacity>

        {/* Hero Banner Luxury */}
        <View style={styles.heroBanner}>
          <View style={styles.heroOverlay}>
            <View style={styles.tagBadge}>
              <Text style={styles.tagBadgeText}>MÙA TRĂNG 2026</Text>
            </View>
            <Text style={styles.heroTitle}>Đấu Thầu & Đặt Hàng Doanh Nghiệp</Text>
            <Text style={styles.heroDesc}>
              Chiết khấu đến 35% cho đơn hàng doanh nghiệp từ 20 đến 500+ hộp. Miễn phí in logo ép kim & giao hàng xe lạnh PoD.
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

        {/* 2. Lucian Trust Security Badges */}
        <TrustSecurityBadges />

        {/* 3. Ant Design Segmented Categories */}
        <View style={styles.sectionHeader}>
          <View style={styles.titleWrap}>
            <Ionicons name="apps-outline" size={18} color={COLORS.primary} />
            <Text style={styles.sectionTitle}>Danh Mục Tuyển Chọn</Text>
          </View>
        </View>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categoryScroll}
        >
          {categories.map((cat) => {
            const isActive = selectedCategory === cat.label;
            return (
              <TouchableOpacity
                key={cat.label}
                style={[
                  styles.categoryChip,
                  isActive && styles.categoryChipActive,
                ]}
                onPress={() => setSelectedCategory(cat.label)}
              >
                <Text
                  style={[
                    styles.categoryText,
                    isActive && styles.categoryTextActive,
                  ]}
                >
                  {cat.label}
                </Text>
                <View style={[styles.badgeCount, isActive && styles.badgeCountActive]}>
                  <Text style={[styles.badgeCountText, isActive && styles.badgeCountTextActive]}>
                    {cat.count}
                  </Text>
                </View>
              </TouchableOpacity>
            );
          })}
        </ScrollView>

        {/* Product List */}
        <View style={styles.sectionHeader}>
          <View style={styles.titleWrap}>
            <Ionicons name="ribbon-outline" size={18} color={COLORS.primary} />
            <Text style={styles.sectionTitle}>Bánh Nghệ Nhân Đang Mở Đặt</Text>
          </View>
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
          <View style={styles.rfqIconWrap}>
            <Ionicons name="briefcase-outline" size={26} color={COLORS.accent} />
          </View>
          <View style={styles.rfqContent}>
            <Text style={styles.rfqTitle}>Cần đặt trên 500 hộp theo yêu cầu?</Text>
            <Text style={styles.rfqSub}>
              Mở thầu RFQ để nhận bảng giá cạnh tranh và mẫu thử nguyên seal từ hơn 50 xưởng bánh đối tác.
            </Text>
          </View>
          <TouchableOpacity
            style={styles.rfqButton}
            onPress={() => navigation.navigate('CreateRfq')}
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
    paddingVertical: 10,
    paddingBottom: 60,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    paddingHorizontal: 14,
    paddingVertical: 11,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginHorizontal: 16,
    marginVertical: 8,
  },
  searchPlaceholder: {
    flex: 1,
    fontSize: 13,
    color: COLORS.textMuted,
    marginLeft: 10,
  },
  aiPill: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginHorizontal: 16,
    marginBottom: 12,
  },
  aiPillLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    gap: 6,
  },
  aiPillTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.accent,
  },
  aiPillSub: {
    fontSize: 11,
    color: COLORS.textSecondary,
    flex: 1,
  },
  heroBanner: {
    borderRadius: 14,
    overflow: 'hidden',
    backgroundColor: COLORS.primaryDark,
    marginHorizontal: 16,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: 'rgba(212, 136, 6, 0.4)',
    shadowColor: COLORS.primaryDark,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 3,
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
    fontSize: 18,
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
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginHorizontal: 16,
    marginTop: 14,
    marginBottom: 10,
  },
  titleWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  seeAllText: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.primary,
  },
  categoryScroll: {
    paddingHorizontal: 16,
    paddingBottom: 6,
    gap: 8,
  },
  categoryChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 8,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.border,
    gap: 6,
  },
  categoryChipActive: {
    backgroundColor: '#FFF1F0',
    borderColor: COLORS.primary,
    borderWidth: 1.5,
  },
  categoryText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textSecondary,
  },
  categoryTextActive: {
    color: COLORS.primary,
    fontWeight: '800',
  },
  badgeCount: {
    backgroundColor: COLORS.background,
    borderRadius: 10,
    paddingHorizontal: 6,
    paddingVertical: 1,
  },
  badgeCountActive: {
    backgroundColor: COLORS.primary,
  },
  badgeCountText: {
    fontSize: 10,
    fontWeight: '700',
    color: COLORS.textMuted,
  },
  badgeCountTextActive: {
    color: '#FFF',
  },
  rfqCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E8D2A3',
    padding: 14,
    marginHorizontal: 16,
    marginTop: 16,
    marginBottom: 20,
    shadowColor: COLORS.accent,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 2,
  },
  rfqIconWrap: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: COLORS.accentGoldBg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  rfqContent: {
    flex: 1,
  },
  rfqTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 3,
  },
  rfqSub: {
    fontSize: 11,
    color: COLORS.textSecondary,
    lineHeight: 16,
  },
  rfqButton: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
    marginLeft: 8,
  },
  rfqBtnText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '700',
  },
});
