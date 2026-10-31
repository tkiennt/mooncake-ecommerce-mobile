import React, { useState } from 'react';
import {
  View,
  Text,
  Image,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { useCart } from '../../context/CartContext';
import { MOCK_PRODUCTS } from '../../api/apiClient';
import B2BPriceCalculator from '../../components/lucian/B2BPriceCalculator';
import TearOffCoupon from '../../components/lucian/TearOffCoupon';

export default function ProductDetailScreen({ route, navigation }) {
  const product = route?.params?.product || MOCK_PRODUCTS[0];
  const { addToCart } = useCart();

  // Bắt buộc chọn variant (mặc định chọn cái đầu tiên)
  const [selectedVariant, setSelectedVariant] = useState(
    product.variants && product.variants.length > 0 ? product.variants[0] : null
  );

  const [quantity, setQuantity] = useState(product.minOrderQty || 20);
  const [appliedCoupon, setAppliedCoupon] = useState(null);
  const [isAddedDrawerOpen, setIsAddedDrawerOpen] = useState(false);

  const formatVND = (num) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(num);
  };

  const unitPrice = product.basePrice + (selectedVariant ? selectedVariant.priceAdjustment : 0);
  const subtotal = unitPrice * quantity;

  // Tính chiết khấu bậc thang theo số lượng
  let activeDiscountPercent = 0;
  if (product.tierPricing) {
    for (const tier of product.tierPricing) {
      if (quantity >= tier.minQty && (!tier.maxQty || quantity <= tier.maxQty)) {
        activeDiscountPercent = Math.max(activeDiscountPercent, tier.discountPercent);
      }
    }
  }

  const discountAmount = Math.round((subtotal * activeDiscountPercent) / 100);
  const couponDiscount = appliedCoupon ? 500000 : 0;
  const finalTotal = Math.max(0, subtotal - discountAmount - couponDiscount);

  const handleAddToCart = () => {
    if (!selectedVariant) {
      Alert.alert('Chưa chọn biến thể', 'Vui lòng chọn loại bánh và nhân cụ thể.');
      return;
    }
    if (quantity < (product.minOrderQty || 20)) {
      Alert.alert('Số lượng chưa đạt MOQ', `Số lượng tối thiểu là ${product.minOrderQty || 20} hộp.`);
      return;
    }

    addToCart(product, selectedVariant, quantity);
    // RF-02: Mở Drawer trượt thay vì Alert.alert thô sơ
    setIsAddedDrawerOpen(true);
  };

  const handleApplyTier = (calc) => {
    setQuantity(calc.quantity);
  };

  const handleApplyCoupon = (code) => {
    setAppliedCoupon(code);
    Alert.alert('Kích hoạt ưu đãi', `Đã áp dụng mã ${code} (-500.000₫) cho đơn hàng này.`);
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Chi Tiết Bánh Hoàng Gia"
        subtitle={product.shopName}
        showBack={true}
        onBack={() => navigation.goBack()}
        rightIcon="cart-outline"
        onRightPress={() => navigation.navigate('CartTab')}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Product Cover Image */}
        <Image source={{ uri: product.coverImage }} style={styles.image} resizeMode="cover" />

        <View style={styles.body}>
          {/* Shop badge & Category */}
          <View style={styles.shopRow}>
            <View style={styles.shopBadge}>
              <Ionicons name="storefront" size={14} color={COLORS.accent} />
              <Text style={styles.shopBadgeText}>{product.shopName}</Text>
            </View>
            <View style={styles.categoryBadgeWrap}>
              <Text style={styles.categoryBadge}>{product.category}</Text>
            </View>
          </View>

          <Text style={styles.title}>{product.name}</Text>

          {/* Rating & MOQ Info */}
          <View style={styles.metaBox}>
            <View style={styles.ratingRow}>
              <Ionicons name="star" size={16} color="#FAAD14" />
              <Text style={styles.ratingScore}>{product.rating || '4.9'}</Text>
              <Text style={styles.reviewCount}>({product.reviewCount || 128} đánh giá B2B)</Text>
            </View>
            <View style={styles.moqBox}>
              <Ionicons name="cube-outline" size={14} color={COLORS.primary} />
              <Text style={styles.moqLabel}>MOQ: </Text>
              <Text style={styles.moqVal}>{product.minOrderQty || 20} hộp</Text>
            </View>
          </View>

          {/* Price Header */}
          <View style={styles.priceContainer}>
            <View>
              <Text style={styles.priceSub}>Đơn giá cơ sở niêm yết</Text>
              <Text style={styles.mainPrice}>{formatVND(unitPrice)}/hộp</Text>
            </View>
            {activeDiscountPercent > 0 && (
              <View style={styles.discountTag}>
                <Ionicons name="trending-down" size={14} color="#874D00" />
                <Text style={styles.discountTagText}>Giảm {activeDiscountPercent}% bậc số lượng</Text>
              </View>
            )}
          </View>

          {/* 1. Lucian Tear-Off Coupon Component */}
          <TearOffCoupon
            code="B2BMOON2026"
            discountText="GIẢM 500.000₫"
            conditionText="Áp dụng cho đơn hàng từ 30 hộp"
            onApply={handleApplyCoupon}
          />

          {/* 2. Lucian B2B Price Calculator Component */}
          <B2BPriceCalculator
            baseRetailPrice={unitPrice}
            initialQuantity={quantity}
            onApplyTier={handleApplyTier}
          />

          {/* 3. Ant Design Radio Selection Cards (Variant Selection) */}
          <View style={styles.variantSection}>
            <View style={styles.sectionHeadingWrap}>
              <Ionicons name="list" size={16} color={COLORS.primary} />
              <Text style={styles.sectionHeading}>
                Chọn Biến Thể Bánh & Nhân <Text style={styles.required}>*</Text>
              </Text>
            </View>
            <Text style={styles.variantNotice}>
              Quy chuẩn B2B: Bắt buộc chọn hương vị và loại vỏ trước khi chốt đơn/hợp đồng.
            </Text>

            {product.variants.map((v) => {
              const isSelected = selectedVariant?.id === v.id;
              return (
                <TouchableOpacity
                  key={v.id}
                  style={[styles.variantCard, isSelected && styles.variantCardSelected]}
                  onPress={() => setSelectedVariant(v)}
                  activeOpacity={0.8}
                >
                  <View style={[styles.radio, isSelected && styles.radioActive]}>
                    {isSelected && <View style={styles.radioInner} />}
                  </View>
                  <View style={styles.variantInfo}>
                    <Text style={[styles.variantName, isSelected && styles.variantTextSelected]}>
                      {v.name}
                    </Text>
                    <Text style={styles.variantMeta}>
                      Vỏ: {v.crustType} • Nhân: {v.filling} • Tồn kho: {v.stock} hộp
                    </Text>
                  </View>
                  {v.priceAdjustment !== 0 && (
                    <View style={styles.adjBadge}>
                      <Text style={styles.adjText}>
                        {v.priceAdjustment > 0 ? `+${formatVND(v.priceAdjustment)}` : formatVND(v.priceAdjustment)}
                      </Text>
                    </View>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>

          {/* Description */}
          <View style={styles.descSection}>
            <View style={styles.sectionHeadingWrap}>
              <Ionicons name="information-circle-outline" size={16} color={COLORS.primary} />
              <Text style={styles.sectionHeading}>Mô Tả Sản Phẩm & Quy Cách Đóng Gói</Text>
            </View>
            <Text style={styles.descText}>{product.description}</Text>
          </View>
        </View>
      </ScrollView>

      {/* Sticky Bottom Actions */}
      <View style={styles.bottomBar}>
        <View style={styles.bottomTotal}>
          <Text style={styles.bottomLabel}>Tổng dự toán ({quantity} hộp):</Text>
          <Text style={styles.bottomPrice}>{formatVND(finalTotal)}</Text>
          {(discountAmount > 0 || couponDiscount > 0) && (
            <Text style={styles.bottomDiscount}>
              Tiết kiệm: {formatVND(discountAmount + couponDiscount)}
            </Text>
          )}
        </View>
        <CustomButton
          title="Thêm Vào Giỏ"
          icon="🛍️"
          onPress={handleAddToCart}
          size="medium"
          style={styles.addBtn}
        />
      </View>

      {/* RF-02: Animated Mini-Cart Added Drawer (Checklist Design Standard) */}
      <Modal
        visible={isAddedDrawerOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setIsAddedDrawerOpen(false)}
      >
        <View style={styles.drawerOverlay}>
          <View style={styles.drawerCard}>
            <View style={styles.drawerHandle} />

            <View style={styles.successRow}>
              <View style={styles.successIconCircle}>
                <Ionicons name="checkmark-circle" size={28} color="#059669" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.successTitle}>ĐÃ THÊM VÀO GIỎ HÀNG B2B</Text>
                <Text style={styles.successSub}>Sẵn sàng tạo đơn hoặc xuất hợp đồng điện tử</Text>
              </View>
            </View>

            {/* Added Summary Box */}
            <View style={styles.summaryCard}>
              <Text style={styles.summaryProdName}>{product.name}</Text>
              <Text style={styles.summaryVariant}>
                Biến thể: <Text style={styles.bold}>{selectedVariant?.name}</Text>
              </Text>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>Số lượng đóng gói:</Text>
                <Text style={styles.summaryVal}>{quantity} hộp</Text>
              </View>
              <View style={styles.summaryRow}>
                <Text style={styles.summaryLabel}>Chiết khấu bậc thang:</Text>
                <Text style={styles.summaryDiscountText}>-{activeDiscountPercent}%</Text>
              </View>
              {appliedCoupon ? (
                <View style={styles.summaryRow}>
                  <Text style={styles.summaryLabel}>Voucher mùa vụ:</Text>
                  <Text style={styles.summaryDiscountText}>-500.000 ₫</Text>
                </View>
              ) : null}
              <View style={styles.summaryDivider} />
              <View style={styles.summaryRow}>
                <Text style={styles.summaryTotalLabel}>Tổng tạm tính:</Text>
                <Text style={styles.summaryTotalVal}>{formatVND(finalTotal)}</Text>
              </View>
            </View>

            {/* Action Buttons */}
            <View style={styles.drawerActions}>
              <TouchableOpacity
                style={styles.continueBtn}
                onPress={() => setIsAddedDrawerOpen(false)}
              >
                <Text style={styles.continueBtnText}>Tiếp tục xem bánh</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.goToCartBtn}
                onPress={() => {
                  setIsAddedDrawerOpen(false);
                  navigation.navigate('CartTab');
                }}
              >
                <Text style={styles.goToCartText}>Xem Giỏ Hàng →</Text>
              </TouchableOpacity>
            </View>
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
  scroll: {
    paddingBottom: 90,
  },
  image: {
    width: '100%',
    height: 250,
    backgroundColor: '#FAF5EE',
  },
  body: {
    padding: 16,
  },
  shopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  shopBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: COLORS.accentGoldBg,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  shopBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.accent,
  },
  categoryBadgeWrap: {
    backgroundColor: '#FFF1F0',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  categoryBadge: {
    fontSize: 11,
    color: COLORS.primary,
    fontWeight: '600',
  },
  title: {
    fontSize: 20,
    fontWeight: '900',
    color: COLORS.primaryDark,
    marginBottom: 10,
    lineHeight: 28,
  },
  metaBox: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 14,
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  ratingScore: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.textPrimary,
  },
  reviewCount: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  moqBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  moqLabel: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  moqVal: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primary,
  },
  priceContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 10,
  },
  priceSub: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginBottom: 2,
  },
  mainPrice: {
    fontSize: 20,
    fontWeight: '900',
    color: COLORS.primary,
  },
  discountTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFE58F',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  discountTagText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#874D00',
  },

  // Ant Design Variant Selection Cards
  variantSection: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 14,
    marginVertical: 12,
  },
  sectionHeadingWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  sectionHeading: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  required: {
    color: COLORS.primary,
  },
  variantNotice: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginBottom: 12,
  },
  variantCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
  },
  variantCardSelected: {
    borderColor: COLORS.accent,
    borderWidth: 1.5,
    backgroundColor: '#FFFDF9',
  },
  radio: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: COLORS.borderDark,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
  },
  radioActive: {
    borderColor: COLORS.primary,
  },
  radioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: COLORS.primary,
  },
  variantInfo: {
    flex: 1,
  },
  variantName: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginBottom: 2,
  },
  variantTextSelected: {
    color: COLORS.primary,
    fontWeight: '800',
  },
  variantMeta: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  adjBadge: {
    backgroundColor: '#FFF1F0',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  adjText: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.primary,
  },

  // Description
  descSection: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 14,
    marginBottom: 16,
  },
  descText: {
    fontSize: 13,
    color: COLORS.textPrimary,
    lineHeight: 20,
    marginTop: 6,
  },

  // Bottom Sticky Bar
  bottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: COLORS.surface,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    paddingHorizontal: 16,
    paddingVertical: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -3 },
    shadowOpacity: 0.08,
    shadowRadius: 5,
    elevation: 8,
  },
  bottomTotal: {
    flex: 1,
  },
  bottomLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  bottomPrice: {
    fontSize: 18,
    fontWeight: '900',
    color: COLORS.primaryDark,
  },
  bottomDiscount: {
    fontSize: 11,
    fontWeight: '700',
    color: '#059669',
  },
  addBtn: {
    marginLeft: 12,
    minWidth: 140,
  },

  // RF-02 Drawer styles
  drawerOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  drawerCard: {
    backgroundColor: COLORS.surface,
    borderTopLeftRadius: 22,
    borderTopRightRadius: 22,
    padding: 20,
    borderTopWidth: 1.5,
    borderTopColor: COLORS.accent,
  },
  drawerHandle: {
    width: 40,
    height: 4,
    backgroundColor: '#D1C8B8',
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: 16,
  },
  successRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  successIconCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#F6FFED',
    alignItems: 'center',
    justifyContent: 'center',
  },
  successTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#059669',
    letterSpacing: 0.5,
  },
  successSub: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  summaryCard: {
    backgroundColor: COLORS.background,
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    borderColor: '#EFEAE1',
    marginBottom: 16,
  },
  summaryProdName: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 4,
  },
  summaryVariant: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginBottom: 8,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  summaryLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  summaryVal: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  summaryDiscountText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#874D00',
  },
  summaryDivider: {
    height: 1,
    backgroundColor: '#EAE3D5',
    marginVertical: 6,
  },
  summaryTotalLabel: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  summaryTotalVal: {
    fontSize: 15,
    fontWeight: '900',
    color: COLORS.primary,
  },
  drawerActions: {
    flexDirection: 'row',
    gap: 10,
  },
  continueBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1.2,
    borderColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  continueBtnText: {
    color: COLORS.primary,
    fontSize: 13,
    fontWeight: '700',
  },
  goToCartBtn: {
    flex: 1,
    backgroundColor: COLORS.primary,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  goToCartText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
  },
  bold: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
});
