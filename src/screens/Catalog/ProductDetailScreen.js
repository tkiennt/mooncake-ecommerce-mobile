import React, { useState } from 'react';
import {
  View,
  Text,
  Image,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { useCart } from '../../context/CartContext';
import { MOCK_PRODUCTS } from '../../api/apiClient';

export default function ProductDetailScreen({ route, navigation }) {
  const product = route?.params?.product || MOCK_PRODUCTS[0];
  const { addToCart } = useCart();

  // Bắt buộc chọn variant (mặc định chọn cái đầu tiên)
  const [selectedVariant, setSelectedVariant] = useState(
    product.variants && product.variants.length > 0 ? product.variants[0] : null
  );

  const [quantity, setQuantity] = useState(product.minOrderQty || 10);

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
  const finalTotal = subtotal - discountAmount;

  const handleAddToCart = () => {
    if (!selectedVariant) {
      Alert.alert('Chưa chọn biến thể', 'Vui lòng chọn loại bánh và nhân cụ thể.');
      return;
    }
    if (quantity < product.minOrderQty) {
      Alert.alert('Số lượng chưa đạt', `Số lượng tối thiểu là ${product.minOrderQty} hộp.`);
      return;
    }

    addToCart(product, selectedVariant, quantity);
    Alert.alert(
      'Đã thêm vào giỏ',
      `Đã thêm ${quantity} hộp [${selectedVariant.name}] vào giỏ hàng.`,
      [
        { text: 'Tiếp tục xem', style: 'cancel' },
        { text: 'Xem giỏ hàng', onPress: () => navigation.navigate('CartTab') },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Chi Tiết Bánh"
        subtitle={product.shopName}
        showBack={true}
        onBack={() => navigation.goBack()}
        rightIcon="cart-outline"
        onRightPress={() => navigation.navigate('CartTab')}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        <Image source={{ uri: product.coverImage }} style={styles.image} resizeMode="cover" />

        <View style={styles.body}>
          {/* Shop badge & Category */}
          <View style={styles.shopRow}>
            <View style={styles.shopBadge}>
              <Ionicons name="storefront-outline" size={14} color={COLORS.accent} />
              <Text style={styles.shopBadgeText}>{product.shopName}</Text>
            </View>
            <Text style={styles.categoryBadge}>{product.category}</Text>
          </View>

          <Text style={styles.title}>{product.name}</Text>

          {/* Rating & MOQ */}
          <View style={styles.metaBox}>
            <View style={styles.ratingRow}>
              <Ionicons name="star" size={16} color="#FAAD14" />
              <Text style={styles.ratingScore}>{product.rating}</Text>
              <Text style={styles.reviewCount}>({product.reviewCount} đánh giá doanh nghiệp)</Text>
            </View>
            <View style={styles.moqBox}>
              <Text style={styles.moqLabel}>MOQ: </Text>
              <Text style={styles.moqVal}>{product.minOrderQty} hộp</Text>
            </View>
          </View>

          {/* Price display */}
          <View style={styles.priceContainer}>
            <View>
              <Text style={styles.priceSub}>Đơn giá cơ bản</Text>
              <Text style={styles.mainPrice}>{formatVND(unitPrice)}</Text>
            </View>
            {activeDiscountPercent > 0 && (
              <View style={styles.discountTag}>
                <Text style={styles.discountTagText}>Đang áp dụng giảm {activeDiscountPercent}%</Text>
              </View>
            )}
          </View>

          {/* Tiered Pricing Table */}
          {product.tierPricing && product.tierPricing.length > 0 && (
            <View style={styles.tierSection}>
              <Text style={styles.sectionHeading}>
                <Ionicons name="trending-down" size={16} color={COLORS.primary} /> Bảng Giá Chiết Khấu Theo Số Lượng
              </Text>
              <View style={styles.tierTable}>
                {product.tierPricing.map((tier, idx) => {
                  const isCurrent =
                    quantity >= tier.minQty && (!tier.maxQty || quantity <= tier.maxQty);
                  return (
                    <View
                      key={idx}
                      style={[styles.tierRow, isCurrent && styles.tierRowActive]}
                    >
                      <Text style={[styles.tierQty, isCurrent && styles.tierTextActive]}>
                        {tier.minQty} - {tier.maxQty ? `${tier.maxQty} hộp` : 'trở lên'}
                      </Text>
                      <Text style={[styles.tierDiscount, isCurrent && styles.tierTextActive]}>
                        Giảm -{tier.discountPercent}%
                      </Text>
                    </View>
                  );
                })}
              </View>
            </View>
          )}

          {/* Variant Selection (Bắt buộc theo rule hệ thống) */}
          <View style={styles.variantSection}>
            <Text style={styles.sectionHeading}>
              Chọn Biến Thể Bánh & Nhân <Text style={styles.required}>*</Text>
            </Text>
            <Text style={styles.variantNotice}>
              Quy định sàn: Quý khách bắt buộc chọn hương vị và loại vỏ trước khi thêm giỏ hàng.
            </Text>

            {product.variants.map((v) => {
              const isSelected = selectedVariant?.id === v.id;
              return (
                <TouchableOpacity
                  key={v.id}
                  style={[styles.variantCard, isSelected && styles.variantCardSelected]}
                  onPress={() => setSelectedVariant(v)}
                >
                  <View style={styles.radio}>
                    {isSelected && <View style={styles.radioInner} />}
                  </View>
                  <View style={styles.variantInfo}>
                    <Text style={[styles.variantName, isSelected && styles.variantTextSelected]}>
                      {v.name}
                    </Text>
                    <Text style={styles.variantMeta}>
                      Vỏ: {v.crustType} • Nhân: {v.filling} • Tồn: {v.stock}
                    </Text>
                  </View>
                  {v.priceAdjustment !== 0 && (
                    <Text style={styles.adjText}>
                      {v.priceAdjustment > 0 ? `+${formatVND(v.priceAdjustment)}` : formatVND(v.priceAdjustment)}
                    </Text>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>

          {/* Description */}
          <View style={styles.descSection}>
            <Text style={styles.sectionHeading}>Mô Tả Sản Phẩm & Quy Cách</Text>
            <Text style={styles.descText}>{product.description}</Text>
          </View>

          {/* Quantity Selector */}
          <View style={styles.qtySection}>
            <Text style={styles.sectionHeading}>Số Lượng Đặt Mua (Hộp)</Text>
            <View style={styles.qtyRow}>
              <TouchableOpacity
                style={styles.qtyBtn}
                onPress={() => setQuantity(Math.max(product.minOrderQty, quantity - 5))}
              >
                <Ionicons name="remove" size={18} color={COLORS.primary} />
              </TouchableOpacity>
              <Text style={styles.qtyVal}>{quantity}</Text>
              <TouchableOpacity
                style={styles.qtyBtn}
                onPress={() => setQuantity(quantity + 5)}
              >
                <Ionicons name="add" size={18} color={COLORS.primary} />
              </TouchableOpacity>

              <View style={styles.calcBox}>
                <Text style={styles.calcSub}>Thành tiền tạm tính:</Text>
                <Text style={styles.calcTotal}>{formatVND(finalTotal)}</Text>
              </View>
            </View>
          </View>
        </View>
      </ScrollView>

      {/* Sticky Bottom Actions */}
      <View style={styles.bottomBar}>
        <View style={styles.bottomTotal}>
          <Text style={styles.bottomLabel}>Tổng thanh toán:</Text>
          <Text style={styles.bottomPrice}>{formatVND(finalTotal)}</Text>
          {discountAmount > 0 && (
            <Text style={styles.bottomDiscount}>Tiết kiệm: {formatVND(discountAmount)}</Text>
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
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  scroll: {
    paddingBottom: 100,
  },
  image: {
    width: '100%',
    height: 260,
    backgroundColor: '#EAE5DB',
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
  },
  shopBadgeText: {
    fontSize: 13,
    color: COLORS.accent,
    fontWeight: '600',
    marginLeft: 6,
  },
  categoryBadge: {
    backgroundColor: 'rgba(140, 21, 36, 0.08)',
    color: COLORS.primary,
    fontSize: 11,
    fontWeight: '700',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
  },
  title: {
    fontSize: 20,
    fontWeight: '800',
    color: COLORS.textPrimary,
    lineHeight: 26,
    marginBottom: 10,
  },
  metaBox: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
    marginBottom: 14,
  },
  ratingRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  ratingScore: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginLeft: 4,
  },
  reviewCount: {
    fontSize: 12,
    color: COLORS.textMuted,
    marginLeft: 6,
  },
  moqBox: {
    flexDirection: 'row',
  },
  moqLabel: {
    fontSize: 12,
    color: COLORS.textMuted,
  },
  moqVal: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.primary,
  },
  priceContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#FFF',
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 16,
  },
  priceSub: {
    fontSize: 12,
    color: COLORS.textMuted,
  },
  mainPrice: {
    fontSize: 20,
    fontWeight: '800',
    color: COLORS.primary,
    marginTop: 2,
  },
  discountTag: {
    backgroundColor: '#F6FFED',
    borderWidth: 1,
    borderColor: '#B7EB8F',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
  },
  discountTagText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#389E0D',
  },
  tierSection: {
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 10,
    padding: 14,
    marginBottom: 18,
  },
  sectionHeading: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 8,
  },
  required: {
    color: COLORS.error,
  },
  tierTable: {
    marginTop: 6,
  },
  tierRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 6,
    paddingHorizontal: 8,
    borderRadius: 4,
  },
  tierRowActive: {
    backgroundColor: '#FFE58F',
  },
  tierQty: {
    fontSize: 13,
    color: '#873800',
  },
  tierDiscount: {
    fontSize: 13,
    fontWeight: '700',
    color: '#873800',
  },
  tierTextActive: {
    fontWeight: '800',
  },
  variantSection: {
    marginBottom: 18,
  },
  variantNotice: {
    fontSize: 12,
    color: COLORS.textMuted,
    marginBottom: 10,
  },
  variantCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
  },
  variantCardSelected: {
    borderColor: COLORS.primary,
    backgroundColor: 'rgba(140, 21, 36, 0.03)',
  },
  radio: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
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
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  variantTextSelected: {
    color: COLORS.primary,
    fontWeight: '700',
  },
  variantMeta: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  adjText: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.accent,
  },
  descSection: {
    marginBottom: 18,
  },
  descText: {
    fontSize: 13,
    color: COLORS.textSecondary,
    lineHeight: 20,
  },
  qtySection: {
    backgroundColor: '#FFF',
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  qtyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 8,
  },
  qtyBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFF',
  },
  qtyVal: {
    fontSize: 16,
    fontWeight: '700',
    marginHorizontal: 16,
    minWidth: 30,
    textAlign: 'center',
  },
  calcBox: {
    flex: 1,
    alignItems: 'flex-end',
  },
  calcSub: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  calcTotal: {
    fontSize: 16,
    fontWeight: '800',
    color: COLORS.primary,
  },
  bottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFF',
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    paddingHorizontal: 16,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    elevation: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  bottomTotal: {
    flex: 1,
  },
  bottomLabel: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  bottomPrice: {
    fontSize: 18,
    fontWeight: '800',
    color: COLORS.primary,
  },
  bottomDiscount: {
    fontSize: 11,
    color: '#389E0D',
    fontWeight: '600',
  },
  addBtn: {
    paddingHorizontal: 20,
  },
});

