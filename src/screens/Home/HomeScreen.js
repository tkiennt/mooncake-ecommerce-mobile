import React from 'react';
import {
  View,
  Text,
  Image,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  StatusBar,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import ProductGridCard from '../../components/common/ProductGridCard';
import { useCatalogProducts } from '../../hooks/useCatalogProducts';
import { useCart } from '../../context/CartContext';

const PROMO_BANNER = require('../../../assets/products/promo-banner.jpg');

const SHORTCUTS = [
  { key: 'catalog', label: 'Danh mục', icon: 'grid-outline', screen: 'Search' },
  { key: 'rfq', label: 'Báo giá', icon: 'document-text-outline', screen: 'CreateRfq' },
  { key: 'ai', label: 'Trợ lý AI', icon: 'sparkles-outline', screen: 'AiAssistant' },
  { key: 'contracts', label: 'Hợp đồng', icon: 'reader-outline', screen: 'Contracts' },
  { key: 'delivery', label: 'Giao hàng', icon: 'car-outline', screen: 'DeliveryPoD' },
];

// Taller and shorter images alternate so the two columns stagger like a feed, not a table.
const IMAGE_RATIOS = [0.82, 1, 1, 0.82];

export default function HomeScreen({ navigation }) {
  const insets = useSafeAreaInsets();
  const { getCartTotals } = useCart();
  const { totalItems } = getCartTotals();

  const catalog = useCatalogProducts({ pageSize: 20 });
  const openProduct = (product) => navigation.navigate('ProductDetail', { product });

  // Feed tiles: the promo banner leads the left column, the RFQ prompt sits in the right column.
  const tiles = [
    { type: 'promo', key: 'promo' },
    ...catalog.products.map((product, index) => ({ type: 'product', key: product.id, product, ratio: IMAGE_RATIOS[index % IMAGE_RATIOS.length] })),
    { type: 'rfq', key: 'rfq' },
  ];
  const columns = [[], []];
  const heights = [0, 0];
  tiles.forEach((tile) => {
    const estimate = tile.type === 'promo' ? 1.45 : tile.type === 'rfq' ? 0.9 : 1 / tile.ratio + 0.55;
    const col = heights[0] <= heights[1] ? 0 : 1;
    columns[col].push(tile);
    heights[col] += estimate;
  });

  const renderTile = (tile) => {
    if (tile.type === 'promo') {
      return (
        <TouchableOpacity key={tile.key} style={styles.promo} activeOpacity={0.9} onPress={() => navigation.navigate('Search')}>
          <Image source={PROMO_BANNER} style={styles.promoImage} resizeMode="cover" />
          <View style={styles.promoShade} />
          <View style={styles.promoContent}>
            <Text style={styles.promoEyebrow}>Mùa trăng 2026</Text>
            <Text style={styles.promoTitle}>Quà Trung thu cho doanh nghiệp</Text>
            <Text style={styles.promoSub}>Chiết khấu đến 35% · in logo miễn phí</Text>
            <View style={styles.promoCta}>
              <Text style={styles.promoCtaText}>Xem bộ sưu tập</Text>
              <Ionicons name="chevron-forward" size={12} color={COLORS.primaryDark} />
            </View>
          </View>
        </TouchableOpacity>
      );
    }
    if (tile.type === 'rfq') {
      return (
        <TouchableOpacity key={tile.key} style={styles.rfq} activeOpacity={0.9} onPress={() => navigation.navigate('CreateRfq')}>
          <View style={styles.rfqIcon}>
            <Ionicons name="briefcase-outline" size={20} color={COLORS.primary} />
          </View>
          <Text style={styles.rfqTitle}>Đặt trên 500 hộp?</Text>
          <Text style={styles.rfqSub}>Gửi một yêu cầu, nhận báo giá từ nhiều xưởng đã xác minh.</Text>
          <Text style={styles.rfqLink}>Tạo yêu cầu báo giá</Text>
        </TouchableOpacity>
      );
    }
    return <ProductGridCard key={tile.key} product={tile.product} imageRatio={tile.ratio} onPress={openProduct} />;
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={COLORS.primary} />

      {/* Header: search first, like a marketplace home, instead of a large title bar */}
      <View style={[styles.header, { paddingTop: insets.top + 10 }]}>
        <TouchableOpacity style={styles.search} activeOpacity={0.85} onPress={() => navigation.navigate('Search')}>
          <Ionicons name="search-outline" size={18} color={COLORS.textMuted} />
          <Text style={styles.searchText} numberOfLines={1}>Hộp quà Trung thu doanh nghiệp</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.headerIcon} onPress={() => navigation.navigate('CartTab')} accessibilityLabel="Giỏ hàng">
          <Ionicons name="cart-outline" size={24} color={COLORS.textWhite} />
          {totalItems > 0 && (
            <View style={styles.headerBadge}>
              <Text style={styles.headerBadgeText}>{totalItems > 99 ? '99+' : totalItems}</Text>
            </View>
          )}
        </TouchableOpacity>
        <TouchableOpacity style={styles.headerIcon} onPress={() => navigation.navigate('Notification')} accessibilityLabel="Thông báo">
          <Ionicons name="notifications-outline" size={23} color={COLORS.textWhite} />
          <View style={styles.headerDot} />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Shortcuts */}
        <View style={styles.shortcuts}>
          {SHORTCUTS.map((item) => (
            <TouchableOpacity key={item.key} style={styles.shortcut} onPress={() => navigation.navigate(item.screen)}>
              <View style={styles.shortcutIcon}>
                <Ionicons name={item.icon} size={20} color={COLORS.primary} />
              </View>
              <Text style={styles.shortcutLabel} numberOfLines={2}>{item.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* One quiet trust line instead of four badge cards */}
        <View style={styles.trust}>
          <Ionicons name="shield-checkmark-outline" size={14} color={COLORS.success} />
          <Text style={styles.trustText} numberOfLines={1}>Hóa đơn VAT · Ký quỹ an toàn · Giao xe lạnh</Text>
        </View>

        <Text style={styles.feedTitle}>Gợi ý hôm nay</Text>

        <View style={styles.feed}>
          {columns.map((column, index) => (
            <View key={index} style={styles.column}>
              {column.map(renderTile)}
            </View>
          ))}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4F1EC',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingBottom: 10,
    backgroundColor: COLORS.primary,
  },
  search: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    height: 40,
    paddingHorizontal: 12,
    borderRadius: 6,
    backgroundColor: COLORS.surface,
  },
  searchText: {
    flex: 1,
    color: COLORS.primary,
    fontSize: 14,
  },
  headerIcon: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerBadge: {
    position: 'absolute',
    top: 2,
    right: 0,
    minWidth: 18,
    height: 18,
    paddingHorizontal: 4,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: COLORS.surface,
  },
  headerBadgeText: {
    color: COLORS.primary,
    fontSize: 10,
    fontWeight: '700',
  },
  headerDot: {
    position: 'absolute',
    top: 8,
    right: 9,
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: COLORS.accentGoldLight,
  },
  scroll: {
    paddingBottom: 16,
  },
  shortcuts: {
    flexDirection: 'row',
    paddingHorizontal: 8,
    paddingTop: 14,
    paddingBottom: 10,
    backgroundColor: COLORS.surface,
  },
  shortcut: {
    flex: 1,
    alignItems: 'center',
    gap: 6,
  },
  shortcutIcon: {
    width: 44,
    height: 44,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FBF0EE',
  },
  shortcutLabel: {
    color: COLORS.textPrimary,
    fontSize: 11,
    lineHeight: 14,
    textAlign: 'center',
  },
  trust: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 14,
    paddingVertical: 8,
    backgroundColor: COLORS.surface,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: COLORS.border,
  },
  trustText: {
    flex: 1,
    color: COLORS.textSecondary,
    fontSize: 12,
  },
  feedTitle: {
    marginTop: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: COLORS.primary,
    fontSize: 14,
    fontWeight: '700',
    textAlign: 'center',
    backgroundColor: COLORS.surface,
    borderBottomWidth: 2,
    borderBottomColor: COLORS.primary,
  },
  feed: {
    flexDirection: 'row',
    gap: 8,
    paddingHorizontal: 8,
    paddingTop: 8,
  },
  column: {
    flex: 1,
  },
  promo: {
    height: 300,
    marginBottom: 8,
    borderRadius: 6,
    overflow: 'hidden',
    backgroundColor: COLORS.primaryDark,
  },
  promoImage: {
    ...StyleSheet.absoluteFillObject,
    width: '100%',
    height: '100%',
  },
  promoShade: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(40, 6, 12, 0.35)',
  },
  promoContent: {
    flex: 1,
    justifyContent: 'flex-end',
    padding: 12,
    gap: 4,
  },
  promoEyebrow: {
    alignSelf: 'flex-start',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 3,
    backgroundColor: COLORS.accent,
    color: COLORS.textWhite,
    fontSize: 10,
    fontWeight: '700',
  },
  promoTitle: {
    color: COLORS.textWhite,
    fontSize: 18,
    fontWeight: '700',
    lineHeight: 23,
  },
  promoSub: {
    color: '#F3E3D3',
    fontSize: 12,
  },
  promoCta: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 2,
    marginTop: 6,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 14,
    backgroundColor: '#F6D99B',
  },
  promoCtaText: {
    color: COLORS.primaryDark,
    fontSize: 12,
    fontWeight: '700',
  },
  rfq: {
    marginBottom: 8,
    padding: 12,
    gap: 6,
    borderRadius: 6,
    backgroundColor: COLORS.surface,
  },
  rfqIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FBF0EE',
  },
  rfqTitle: {
    color: COLORS.textPrimary,
    fontSize: 14,
    fontWeight: '700',
  },
  rfqSub: {
    color: COLORS.textSecondary,
    fontSize: 12,
    lineHeight: 17,
  },
  rfqLink: {
    color: COLORS.primary,
    fontSize: 12,
    fontWeight: '700',
  },
});
