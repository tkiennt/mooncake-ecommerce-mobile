import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  Image,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Modal,
  Share,
  StatusBar,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { useCart } from '../../context/CartContext';
import { MOCK_PRODUCTS } from '../../api/apiClient';
import B2BPriceCalculator from '../../components/lucian/B2BPriceCalculator';
import TearOffCoupon from '../../components/lucian/TearOffCoupon';
import { imageSource } from '../../utils/imageSource';
import { productService } from '../../services/api/productService';
import { toMobileProduct } from '../../api/mappers';

const formatVND = (value = 0) => `${Math.round(value).toLocaleString('vi-VN')} ₫`;
const formatCount = (count = 0) => (count >= 1000 ? `${(count / 1000).toFixed(1).replace('.0', '')}k+` : `${count}`);

const REVIEW_TOPICS = [
  { label: 'Bánh ngon', count: 32 },
  { label: 'Đóng gói đẹp', count: 18 },
  { label: 'Giao đúng hẹn', count: 12 },
];

/** Tappable row with a leading icon and a trailing chevron, separated by hairlines. */
function InfoRow({ icon, iconColor = COLORS.primary, title, highlight, subtitle, onPress, last }) {
  return (
    <TouchableOpacity style={[styles.infoRow, !last && styles.infoRowDivider]} onPress={onPress} disabled={!onPress} activeOpacity={0.7}>
      <Ionicons name={icon} size={20} color={iconColor} />
      <View style={styles.infoBody}>
        <Text style={styles.infoTitle}>
          {highlight ? <Text style={styles.infoHighlight}>{highlight} </Text> : null}
          {title}
        </Text>
        {subtitle ? <Text style={styles.infoSub}>{subtitle}</Text> : null}
      </View>
      {onPress && <Ionicons name="chevron-forward" size={18} color={COLORS.textMuted} />}
    </TouchableOpacity>
  );
}

export default function ProductDetailScreen({ route, navigation }) {
  const [product, setProduct] = useState(route?.params?.product || MOCK_PRODUCTS[0]);
  const insets = useSafeAreaInsets();
  const { addToCart, getCartTotals } = useCart();
  const { totalItems } = getCartTotals();

  const [selectedVariant, setSelectedVariant] = useState(product.variants?.[0] || null);

  // Search cards carry no variants/description: load the full public detail for API products.
  useEffect(() => {
    const id = route?.params?.product?.id || route?.params?.productId;
    if (!id || !(route?.params?.product?.isFromApi || route?.params?.productId)) return;
    let alive = true;
    productService.detail(id)
      .then((dto) => {
        if (!alive || !dto) return;
        const full = toMobileProduct(dto);
        setProduct(full);
        setSelectedVariant(full.variants?.[0] || null);
        setQuantity(full.minOrderQty || 1);
      })
      .catch(() => {});
    return () => { alive = false; };
  }, [route?.params?.product?.id, route?.params?.productId]);
  const [quantity, setQuantity] = useState(product.minOrderQty || 20);
  const [appliedCoupon, setAppliedCoupon] = useState(null);
  const [liked, setLiked] = useState(false);
  const [isAddedDrawerOpen, setIsAddedDrawerOpen] = useState(false);
  // Once the image scrolls away, the floating buttons get a solid bar so they never cover content.
  const [solidTopBar, setSolidTopBar] = useState(false);

  const unitPrice = product.basePrice + (selectedVariant ? selectedVariant.priceAdjustment : 0);
  const subtotal = unitPrice * quantity;

  // Tiered discount by quantity
  let activeDiscountPercent = 0;
  (product.tierPricing || []).forEach((tier) => {
    if (quantity >= tier.minQty && (!tier.maxQty || quantity <= tier.maxQty)) {
      activeDiscountPercent = Math.max(activeDiscountPercent, tier.discountPercent);
    }
  });
  const bestTier = (product.tierPricing || []).reduce((best, tier) => (!best || tier.discountPercent > best.discountPercent ? tier : best), null);

  const discountAmount = Math.round((subtotal * activeDiscountPercent) / 100);
  const couponDiscount = appliedCoupon ? 500000 : 0;
  const finalTotal = Math.max(0, subtotal - discountAmount - couponDiscount);

  const validate = () => {
    if (!selectedVariant) {
      Alert.alert('Chưa chọn loại bánh', 'Vui lòng chọn loại bánh và nhân.');
      return false;
    }
    if (quantity < (product.minOrderQty || 20)) {
      Alert.alert('Chưa đạt số lượng tối thiểu', `Số lượng tối thiểu là ${product.minOrderQty || 20} hộp.`);
      return false;
    }
    return true;
  };

  const handleAddToCart = () => {
    if (!validate()) return;
    addToCart(product, selectedVariant, quantity);
    setIsAddedDrawerOpen(true);
  };

  const handleBuyNow = () => {
    if (!validate()) return;
    addToCart(product, selectedVariant, quantity);
    navigation.navigate('Checkout');
  };

  const handleApplyCoupon = (code) => {
    setAppliedCoupon(code);
    Alert.alert('Đã áp dụng ưu đãi', `Mã ${code} giảm 500.000 ₫ cho đơn hàng này.`);
  };

  const handleShare = () => {
    Share.share({ message: `${product.name} · ${formatVND(product.basePrice)}/hộp trên Nguyệt Phố` }).catch(() => {});
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" translucent backgroundColor="transparent" />

      <ScrollView
        contentContainerStyle={styles.scroll}
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        onScroll={(event) => setSolidTopBar(event.nativeEvent.contentOffset.y > 220)}
      >
        {/* Full-bleed product image with floating controls */}
        <View style={styles.hero}>
          <Image source={imageSource(product.coverImage)} style={styles.heroImage} resizeMode="cover" />
          <View style={styles.ratingPill}>
            <Text style={styles.ratingPillScore}>{product.rating || '4.9'}</Text>
            <Ionicons name="star" size={12} color={COLORS.accent} />
            <Text style={styles.ratingPillText}>từ {formatCount(product.reviewCount || 128)} đánh giá</Text>
          </View>
          {activeDiscountPercent > 0 && (
            <View style={styles.heroTierPill}>
              <Ionicons name="trending-down" size={12} color={COLORS.primary} />
              <Text style={styles.heroTierText}>Đang giảm {activeDiscountPercent}%</Text>
            </View>
          )}
        </View>

        {/* Variants, price, name */}
        <View style={styles.section}>
          <Text style={styles.variantCount}>{product.variants?.length || 0} loại nhân có sẵn</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.variantRow}>
            {(product.variants || []).map((v) => {
              const active = selectedVariant?.id === v.id;
              return (
                <TouchableOpacity
                  key={v.id}
                  style={[styles.variantChip, active && styles.variantChipActive]}
                  onPress={() => setSelectedVariant(v)}
                  activeOpacity={0.8}
                >
                  <Text style={[styles.variantChipName, active && styles.variantChipNameActive]} numberOfLines={1}>{v.name}</Text>
                  <Text style={styles.variantChipMeta} numberOfLines={1}>
                    {v.crustType} · còn {v.stock}
                    {v.priceAdjustment ? ` · ${v.priceAdjustment > 0 ? '+' : '−'}${formatVND(Math.abs(v.priceAdjustment))}` : ''}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </ScrollView>

          <View style={styles.priceRow}>
            <Text style={styles.price}>
              {formatVND(unitPrice)}
              <Text style={styles.priceUnit}> /hộp</Text>
            </Text>
            <View style={styles.priceRight}>
              {product.soldCount > 0 && <Text style={styles.sold}>Đã bán {formatCount(product.soldCount)}</Text>}
              <TouchableOpacity onPress={() => setLiked((v) => !v)} accessibilityLabel="Yêu thích" hitSlop={8}>
                <Ionicons name={liked ? 'heart' : 'heart-outline'} size={22} color={liked ? COLORS.primary : COLORS.textSecondary} />
              </TouchableOpacity>
            </View>
          </View>

          {bestTier && (
            <View style={styles.tierNote}>
              <Ionicons name="pricetags-outline" size={14} color={COLORS.primary} />
              <Text style={styles.tierNoteText}>Giảm đến {bestTier.discountPercent}% khi đặt từ {bestTier.minQty} hộp</Text>
            </View>
          )}

          <Text style={styles.name}>
            {product.rating >= 4.8 ? <Text style={styles.nameTag}> Xưởng uy tín </Text> : null}
            {product.rating >= 4.8 ? ' ' : ''}
            {product.name}
          </Text>
        </View>

        {/* Service info rows */}
        <View style={[styles.section, styles.sectionFlush]}>
          <InfoRow
            icon="snow-outline"
            iconColor={COLORS.success}
            highlight="Giao xe lạnh 20–25°C"
            title="· dự kiến 3–5 ngày"
            subtitle="Theo dõi hành trình và nhận biên bản giao hàng (PoD)."
            onPress={() => navigation.navigate('DeliveryPoD')}
          />
          <InfoRow
            icon="shield-checkmark-outline"
            title="Hóa đơn VAT · tiền cọc giữ trong ký quỹ"
            subtitle="Chỉ giải ngân cho xưởng sau khi bạn nghiệm thu."
            onPress={() => navigation.navigate('Contracts')}
          />
          <InfoRow
            icon="cube-outline"
            title={`Tối thiểu ${product.minOrderQty || 20} hộp · tối đa ${product.maxOrderQty || 5000} hộp`}
            subtitle={product.isCustomPackagingSupported ? 'Hỗ trợ in logo doanh nghiệp lên hộp.' : undefined}
            last
          />
        </View>

        {/* Shop */}
        <View style={[styles.section, styles.shopRow]}>
          <View style={styles.shopAvatar}>
            <Ionicons name="storefront-outline" size={20} color={COLORS.primary} />
          </View>
          <View style={styles.infoBody}>
            <Text style={styles.shopName} numberOfLines={1}>{product.shopName}</Text>
            <Text style={styles.infoSub}>
              <Ionicons name="location-outline" size={11} color={COLORS.textMuted} /> {product.shopCity || 'Việt Nam'}
            </Text>
          </View>
          <TouchableOpacity style={styles.shopButton} onPress={() => navigation.navigate('Search')}>
            <Text style={styles.shopButtonText}>Xem xưởng</Text>
          </TouchableOpacity>
        </View>

        {/* Voucher + quantity estimate */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Ưu đãi cho doanh nghiệp</Text>
          <TearOffCoupon
            code="B2BMOON2026"
            discountText="Giảm 500.000₫"
            conditionText="Áp dụng cho đơn hàng từ 30 hộp"
            onApply={handleApplyCoupon}
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Ước tính theo số lượng</Text>
          <B2BPriceCalculator
            baseRetailPrice={unitPrice}
            initialQuantity={quantity}
            onApplyTier={(calc) => setQuantity(calc.quantity)}
          />
        </View>

        {/* Reviews */}
        <View style={styles.section}>
          <View style={styles.reviewHead}>
            <Text style={styles.reviewScore}>{product.rating || '4.9'}</Text>
            <Ionicons name="star" size={18} color={COLORS.accent} />
            <Text style={styles.reviewTitle}>Đánh giá sản phẩm ({formatCount(product.reviewCount || 128)})</Text>
            <TouchableOpacity style={styles.seeAll} onPress={() => navigation.navigate('ReviewForm')}>
              <Text style={styles.seeAllText}>Tất cả</Text>
              <Ionicons name="chevron-forward" size={14} color={COLORS.textSecondary} />
            </TouchableOpacity>
          </View>
          <View style={styles.topicRow}>
            {REVIEW_TOPICS.map((topic) => (
              <View key={topic.label} style={styles.topicChip}>
                <Text style={styles.topicText}>
                  {topic.label} <Text style={styles.topicCount}>({topic.count})</Text>
                </Text>
              </View>
            ))}
          </View>
        </View>

        {/* Description */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Mô tả sản phẩm</Text>
          <Text style={styles.description}>{product.description}</Text>
        </View>
      </ScrollView>

      {/* Floating controls over the image */}
      <View
        style={[styles.topBar, { paddingTop: insets.top + 8 }, solidTopBar && styles.topBarSolid]}
        pointerEvents="box-none"
      >
        <TouchableOpacity style={[styles.roundButton, solidTopBar && styles.roundButtonSolid]} onPress={() => navigation.goBack()} accessibilityLabel="Quay lại">
          <Ionicons name="arrow-back" size={22} color={solidTopBar ? COLORS.primary : COLORS.textWhite} />
        </TouchableOpacity>
        {solidTopBar && <Text style={styles.topBarTitle} numberOfLines={1}>{product.name}</Text>}
        <View style={styles.topBarRight}>
          <TouchableOpacity style={[styles.roundButton, solidTopBar && styles.roundButtonSolid]} onPress={handleShare} accessibilityLabel="Chia sẻ">
            <Ionicons name="share-social-outline" size={20} color={solidTopBar ? COLORS.primary : COLORS.textWhite} />
          </TouchableOpacity>
          <TouchableOpacity style={[styles.roundButton, solidTopBar && styles.roundButtonSolid]} onPress={() => navigation.navigate('MainTabs', { screen: 'CartTab' })} accessibilityLabel="Giỏ hàng">
            <Ionicons name="cart-outline" size={21} color={solidTopBar ? COLORS.primary : COLORS.textWhite} />
            {totalItems > 0 && (
              <View style={styles.cartBadge}>
                <Text style={styles.cartBadgeText}>{totalItems > 99 ? '99+' : totalItems}</Text>
              </View>
            )}
          </TouchableOpacity>
        </View>
      </View>

      {/* Bottom action bar */}
      <View style={[styles.bottomBar, { paddingBottom: insets.bottom }]}>
        <TouchableOpacity style={styles.bottomIcon} onPress={() => navigation.navigate('AiAssistant')} accessibilityLabel="Tư vấn">
          <Ionicons name="chatbubbles-outline" size={22} color={COLORS.primary} />
          <Text style={styles.bottomIconText}>Tư vấn</Text>
        </TouchableOpacity>
        <View style={styles.bottomDivider} />
        <TouchableOpacity style={styles.bottomIcon} onPress={handleAddToCart} accessibilityLabel="Thêm vào giỏ">
          <Ionicons name="cart-outline" size={22} color={COLORS.primary} />
          <Text style={styles.bottomIconText}>Thêm vào giỏ</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.buyNow} onPress={handleBuyNow} activeOpacity={0.85}>
          <Text style={styles.buyNowText}>Mua ngay</Text>
          <Text style={styles.buyNowSub} numberOfLines={1}>{quantity} hộp · {formatVND(finalTotal)}</Text>
        </TouchableOpacity>
      </View>

      {/* Added-to-cart sheet */}
      <Modal visible={isAddedDrawerOpen} transparent animationType="slide" onRequestClose={() => setIsAddedDrawerOpen(false)}>
        <View style={styles.drawerOverlay}>
          <View style={[styles.drawerCard, { paddingBottom: insets.bottom + 20 }]}>
            <View style={styles.drawerHandle} />
            <View style={styles.successRow}>
              <Ionicons name="checkmark-circle" size={28} color={COLORS.success} />
              <View style={styles.infoBody}>
                <Text style={styles.successTitle}>Đã thêm vào giỏ hàng</Text>
                <Text style={styles.infoSub}>Bạn có thể tạo đơn hoặc tiếp tục chọn bánh.</Text>
              </View>
            </View>

            <View style={styles.summaryCard}>
              <Text style={styles.summaryName} numberOfLines={2}>{product.name}</Text>
              <Text style={styles.infoSub}>{selectedVariant?.name}</Text>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>Số lượng</Text>
                <Text style={styles.summaryValue}>{quantity} hộp</Text>
              </View>
              {activeDiscountPercent > 0 && (
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryLabel}>Chiết khấu số lượng</Text>
                  <Text style={styles.summaryDiscount}>−{activeDiscountPercent}%</Text>
                </View>
              )}
              {appliedCoupon && (
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryLabel}>Voucher</Text>
                  <Text style={styles.summaryDiscount}>−{formatVND(couponDiscount)}</Text>
                </View>
              )}
              <View style={[styles.summaryRow, styles.summaryTotalRow]}>
                <Text style={styles.summaryTotalLabel}>Tạm tính</Text>
                <Text style={styles.summaryTotal}>{formatVND(finalTotal)}</Text>
              </View>
            </View>

            <View style={styles.drawerActions}>
              <TouchableOpacity style={styles.drawerSecondary} onPress={() => setIsAddedDrawerOpen(false)}>
                <Text style={styles.drawerSecondaryText}>Tiếp tục xem</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.drawerPrimary}
                onPress={() => {
                  setIsAddedDrawerOpen(false);
                  navigation.navigate('MainTabs', { screen: 'CartTab' });
                }}
              >
                <Text style={styles.drawerPrimaryText}>Xem giỏ hàng</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const TINT = '#FBEEEE';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4F1EC',
  },
  scroll: {
    paddingBottom: 16,
  },

  // Hero image
  hero: {
    width: '100%',
    aspectRatio: 1,
    backgroundColor: COLORS.surfaceHover,
  },
  heroImage: {
    ...StyleSheet.absoluteFillObject,
    width: '100%',
    height: '100%',
  },
  ratingPill: {
    position: 'absolute',
    left: 12,
    bottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    backgroundColor: 'rgba(255, 255, 255, 0.92)',
  },
  ratingPillScore: {
    color: COLORS.primary,
    fontSize: 13,
    fontWeight: '600',
  },
  ratingPillText: {
    color: COLORS.textPrimary,
    fontSize: 12,
  },
  heroTierPill: {
    position: 'absolute',
    right: 12,
    bottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 999,
    backgroundColor: 'rgba(255, 255, 255, 0.92)',
  },
  heroTierText: {
    color: COLORS.primary,
    fontSize: 12,
    fontWeight: '500',
  },

  // Floating top controls
  topBar: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 10,
    paddingHorizontal: 12,
    paddingBottom: 8,
  },
  topBarSolid: {
    backgroundColor: COLORS.surface,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: COLORS.border,
  },
  topBarTitle: {
    flex: 1,
    color: COLORS.textPrimary,
    fontSize: 15,
    fontWeight: '500',
  },
  topBarRight: {
    flexDirection: 'row',
    gap: 10,
  },
  roundButton: {
    width: 38,
    height: 38,
    borderRadius: 19,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(31, 20, 18, 0.38)',
  },
  roundButtonSolid: {
    backgroundColor: 'transparent',
  },
  cartBadge: {
    position: 'absolute',
    top: -4,
    right: -6,
    minWidth: 18,
    height: 18,
    paddingHorizontal: 4,
    borderRadius: 9,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: COLORS.primary,
    borderWidth: 1.5,
    borderColor: COLORS.surface,
  },
  cartBadgeText: {
    color: COLORS.textWhite,
    fontSize: 10,
    fontWeight: '700',
  },

  // Sections
  section: {
    marginBottom: 8,
    paddingHorizontal: 14,
    paddingVertical: 14,
    backgroundColor: COLORS.surface,
  },
  sectionFlush: {
    paddingVertical: 0,
  },
  sectionTitle: {
    marginBottom: 10,
    color: COLORS.textPrimary,
    fontSize: 15,
    fontWeight: '600',
  },

  // Variants
  variantCount: {
    color: COLORS.textSecondary,
    fontSize: 13,
  },
  variantRow: {
    gap: 8,
    paddingTop: 8,
    paddingBottom: 4,
  },
  variantChip: {
    maxWidth: 220,
    paddingHorizontal: 10,
    paddingVertical: 7,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    backgroundColor: COLORS.surface,
  },
  variantChipActive: {
    borderColor: COLORS.primary,
    backgroundColor: TINT,
  },
  variantChipName: {
    color: COLORS.textPrimary,
    fontSize: 13,
  },
  variantChipNameActive: {
    color: COLORS.primary,
    fontWeight: '600',
  },
  variantChipMeta: {
    marginTop: 2,
    color: COLORS.textMuted,
    fontSize: 11,
  },

  // Price & name
  priceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 12,
  },
  price: {
    color: COLORS.primary,
    fontSize: 26,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  priceUnit: {
    color: COLORS.textSecondary,
    fontSize: 13,
    fontWeight: '400',
  },
  priceRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  sold: {
    color: COLORS.textPrimary,
    fontSize: 13,
  },
  tierNote: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 5,
    marginTop: 8,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 999,
    backgroundColor: TINT,
  },
  tierNoteText: {
    color: COLORS.primary,
    fontSize: 12,
  },
  name: {
    marginTop: 10,
    color: COLORS.textPrimary,
    fontSize: 16,
    lineHeight: 23,
  },
  nameTag: {
    backgroundColor: TINT,
    color: COLORS.primary,
    fontSize: 12,
    fontWeight: '500',
  },

  // Info rows
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 14,
  },
  infoRowDivider: {
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: COLORS.border,
  },
  infoBody: {
    flex: 1,
    minWidth: 0,
  },
  infoTitle: {
    color: COLORS.textPrimary,
    fontSize: 14,
  },
  infoHighlight: {
    color: COLORS.success,
    fontWeight: '600',
  },
  infoSub: {
    marginTop: 2,
    color: COLORS.textSecondary,
    fontSize: 12,
    lineHeight: 17,
  },

  // Shop
  shopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  shopAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: TINT,
  },
  shopName: {
    color: COLORS.textPrimary,
    fontSize: 14,
    fontWeight: '600',
  },
  shopButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: COLORS.primary,
  },
  shopButtonText: {
    color: COLORS.primary,
    fontSize: 12,
    fontWeight: '500',
  },

  // Reviews
  reviewHead: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  reviewScore: {
    color: COLORS.textPrimary,
    fontSize: 22,
    fontWeight: '600',
  },
  reviewTitle: {
    flex: 1,
    color: COLORS.textPrimary,
    fontSize: 15,
    fontWeight: '500',
  },
  seeAll: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  seeAllText: {
    color: COLORS.textSecondary,
    fontSize: 13,
  },
  topicRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 12,
  },
  topicChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  topicText: {
    color: COLORS.textPrimary,
    fontSize: 13,
  },
  topicCount: {
    color: COLORS.textMuted,
  },
  description: {
    color: COLORS.textSecondary,
    fontSize: 14,
    lineHeight: 21,
  },

  // Bottom bar
  bottomBar: {
    flexDirection: 'row',
    alignItems: 'stretch',
    backgroundColor: TINT,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: COLORS.border,
  },
  bottomIcon: {
    width: 76,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
    paddingVertical: 8,
  },
  bottomIconText: {
    color: COLORS.primary,
    fontSize: 10,
  },
  bottomDivider: {
    width: StyleSheet.hairlineWidth,
    marginVertical: 12,
    backgroundColor: 'rgba(140, 21, 36, 0.25)',
  },
  buyNow: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
    paddingHorizontal: 10,
    backgroundColor: COLORS.primary,
  },
  buyNowText: {
    color: COLORS.textWhite,
    fontSize: 16,
    fontWeight: '600',
  },
  buyNowSub: {
    marginTop: 1,
    color: 'rgba(255, 255, 255, 0.8)',
    fontSize: 11,
  },

  // Added-to-cart sheet
  drawerOverlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
  },
  drawerCard: {
    paddingHorizontal: 18,
    paddingTop: 10,
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    backgroundColor: COLORS.surface,
  },
  drawerHandle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    marginBottom: 14,
    borderRadius: 2,
    backgroundColor: COLORS.border,
  },
  successRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    marginBottom: 14,
  },
  successTitle: {
    color: COLORS.textPrimary,
    fontSize: 16,
    fontWeight: '600',
  },
  summaryCard: {
    gap: 8,
    padding: 14,
    borderRadius: 10,
    backgroundColor: '#F8F5F0',
  },
  summaryName: {
    color: COLORS.textPrimary,
    fontSize: 14,
    fontWeight: '500',
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  summaryLabel: {
    color: COLORS.textSecondary,
    fontSize: 13,
  },
  summaryValue: {
    color: COLORS.textPrimary,
    fontSize: 13,
  },
  summaryDiscount: {
    color: COLORS.success,
    fontSize: 13,
    fontWeight: '500',
  },
  summaryTotalRow: {
    marginTop: 4,
    paddingTop: 10,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: COLORS.border,
  },
  summaryTotalLabel: {
    color: COLORS.textPrimary,
    fontSize: 14,
    fontWeight: '500',
  },
  summaryTotal: {
    color: COLORS.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  drawerActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 16,
  },
  drawerSecondary: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  drawerSecondaryText: {
    color: COLORS.textPrimary,
    fontSize: 14,
    fontWeight: '500',
  },
  drawerPrimary: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 12,
    borderRadius: 8,
    backgroundColor: COLORS.primary,
  },
  drawerPrimaryText: {
    color: COLORS.textWhite,
    fontSize: 14,
    fontWeight: '600',
  },
});
