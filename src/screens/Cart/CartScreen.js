import React from 'react';
import {
  View,
  Text,
  ScrollView,
  Image,
  StyleSheet,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { useCart } from '../../context/CartContext';
import { imageSource } from '../../utils/imageSource';

export default function CartScreen({ navigation }) {
  const {
    cartItems,
    updateQuantity,
    removeFromCart,
    clearCart,
    calculateItemDiscount,
    getCartTotals,
  } = useCart();

  const { rawSubtotal, totalDiscount, finalTotal, totalItems } = getCartTotals();

  const formatVND = (num) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(num);
  };

  const handleClear = () => {
    Alert.alert('Xác nhận', 'Bạn có chắc chắn muốn xóa toàn bộ giỏ hàng?', [
      { text: 'Hủy', style: 'cancel' },
      { text: 'Xóa', style: 'destructive', onPress: clearCart },
    ]);
  };

  // RF-05: Polish Empty State theo phong cách Hoàng Gia B2B
  if (cartItems.length === 0) {
    return (
      <View style={styles.container}>
        <AppHeader title="Giỏ Hàng Doanh Nghiệp" />
        <View style={styles.emptyContainer}>
          <View style={styles.emptyMoonCircle}>
            <Ionicons name="cart-outline" size={42} color={COLORS.primary} />
            <View style={styles.emptySparkle} />
          </View>

          <Text style={styles.emptyTitle}>Giỏ Hàng Doanh Nghiệp Đang Trống</Text>
          <Text style={styles.emptySub}>
            Quý khách chưa chọn hộp bánh nào. Khám phá các bộ sưu tập quà tặng Trung Thu hoàng gia hoặc tạo gói thầu để nhận chiết khấu lên đến 35%.
          </Text>

          <View style={styles.emptyTrustBadge}>
            <Ionicons name="shield-checkmark" size={14} color="#059669" />
            <Text style={styles.emptyTrustText}>100% Xuất Hóa Đơn VAT & Ký e-Contract Pháp Lý</Text>
          </View>

          <View style={styles.emptyBtnGroup}>
            <CustomButton
              title="Khám Phá Bộ Sưu Tập"
              icon="🏮"
              onPress={() => navigation.navigate('HomeTab')}
              size="medium"
              style={styles.browseBtn}
            />
            <TouchableOpacity
              style={styles.rfqSecondaryBtn}
              onPress={() => navigation.navigate('CreateRfq')}
            >
              <Ionicons name="briefcase-outline" size={16} color={COLORS.primary} />
              <Text style={styles.rfqSecondaryText}>Mở Thầu RFQ May Đo</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <AppHeader
        title="Giỏ Hàng Doanh Nghiệp"
        subtitle={`${totalItems} hộp bánh đã chọn`}
        rightIcon="trash-outline"
        onRightPress={handleClear}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        {cartItems.map((item, idx) => {
          const calc = calculateItemDiscount(item);
          return (
            <View key={item.cartId || idx} style={styles.cartCard}>
              <Image source={imageSource(item.product.coverImage)} style={styles.itemImage} />

              <View style={styles.itemDetails}>
                <View style={styles.itemHeader}>
                  <Text style={styles.itemName} numberOfLines={1}>
                    {item.product.name}
                  </Text>
                  <TouchableOpacity
                    onPress={() => removeFromCart(item.cartId)}
                    hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                  >
                    <Ionicons name="close" size={18} color={COLORS.textMuted} />
                  </TouchableOpacity>
                </View>

                <Text style={styles.shopName}>{item.product.shopName}</Text>
                <Text style={styles.variantName}>
                  Biến thể: <Text style={styles.bold}>{item.variant.name}</Text>
                </Text>

                {/* Price and discount badge */}
                <View style={styles.priceRow}>
                  <Text style={styles.unitPrice}>{formatVND(calc.discountedUnitPrice)}/hộp</Text>
                  {calc.discountPercent > 0 && (
                    <View style={styles.discountBadge}>
                      <Text style={styles.discountBadgeText}>-{calc.discountPercent}% B2B</Text>
                    </View>
                  )}
                </View>

                {/* Quantity Controls */}
                <View style={styles.qtyRow}>
                  <View style={styles.stepper}>
                    <TouchableOpacity
                      style={styles.stepperBtn}
                      onPress={() => updateQuantity(item.cartId, item.quantity - 5)}
                    >
                      <Ionicons name="remove" size={16} color={COLORS.primary} />
                    </TouchableOpacity>
                    <Text style={styles.stepperVal}>{item.quantity}</Text>
                    <TouchableOpacity
                      style={styles.stepperBtn}
                      onPress={() => updateQuantity(item.cartId, item.quantity + 5)}
                    >
                      <Ionicons name="add" size={16} color={COLORS.primary} />
                    </TouchableOpacity>
                  </View>

                  <Text style={styles.itemTotal}>{formatVND(calc.itemTotal)}</Text>
                </View>
              </View>
            </View>
          );
        })}

        {/* VAT & B2B Summary Card */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryHeading}>DỰ TOÁN THANH TOÁN B2B</Text>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Tổng tiền hàng gốc:</Text>
            <Text style={styles.summaryValue}>{formatVND(rawSubtotal)}</Text>
          </View>

          {totalDiscount > 0 && (
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Tổng chiết khấu bậc thang:</Text>
              <Text style={styles.summaryDiscount}>-{formatVND(totalDiscount)}</Text>
            </View>
          )}

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Thuế GTGT (VAT 8% B2B):</Text>
            <Text style={styles.summaryValue}>Đã bao gồm trong giá</Text>
          </View>

          <View style={styles.summaryDivider} />

          <View style={styles.summaryRow}>
            <Text style={styles.totalLabel}>TỔNG THANH TOÁN:</Text>
            <Text style={styles.totalPrice}>{formatVND(finalTotal)}</Text>
          </View>

          <View style={styles.vatNoteBox}>
            <Ionicons name="checkmark-circle-outline" size={14} color="#059669" />
            <Text style={styles.vatNoteText}>
              Đơn hàng đủ điều kiện xuất hóa đơn điện tử VAT & hợp đồng kinh tế theo Luật Thương mại.
            </Text>
          </View>
        </View>

        <View style={{ height: 100 }} />
      </ScrollView>

      {/* Sticky Bottom Checkout Bar */}
      <View style={styles.bottomBar}>
        <View style={styles.bottomInfo}>
          <Text style={styles.bottomLabel}>Tổng thanh toán ({totalItems} hộp):</Text>
          <Text style={styles.bottomTotal}>{formatVND(finalTotal)}</Text>
        </View>
        <CustomButton
          title="Xác Nhận Đặt Hàng"
          icon="💼"
          onPress={() => navigation.navigate('Checkout')}
          size="medium"
          style={styles.checkoutBtn}
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
    padding: 16,
    paddingBottom: 40,
  },
  // Empty State Styles
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    paddingVertical: 60,
  },
  emptyMoonCircle: {
    width: 88,
    height: 88,
    borderRadius: 44,
    backgroundColor: COLORS.accentGoldBg,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    borderColor: '#E8D2A3',
    position: 'relative',
    marginBottom: 16,
  },
  emptySparkle: {
    position: 'absolute',
    top: 16,
    right: 18,
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: COLORS.accent,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '900',
    color: COLORS.primaryDark,
    marginBottom: 8,
    textAlign: 'center',
  },
  emptySub: {
    fontSize: 12,
    color: COLORS.textSecondary,
    textAlign: 'center',
    lineHeight: 18,
    marginBottom: 16,
  },
  emptyTrustBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F6FFED',
    borderWidth: 1,
    borderColor: '#B7EB8F',
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
    marginBottom: 20,
  },
  emptyTrustText: {
    fontSize: 11,
    color: '#059669',
    fontWeight: '700',
  },
  emptyBtnGroup: {
    width: '100%',
    gap: 10,
  },
  browseBtn: {
    width: '100%',
  },
  rfqSecondaryBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1.2,
    borderColor: COLORS.primary,
    backgroundColor: COLORS.surface,
    gap: 6,
  },
  rfqSecondaryText: {
    color: COLORS.primary,
    fontSize: 13,
    fontWeight: '700',
  },

  // Cart List Styles
  cartCard: {
    flexDirection: 'row',
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  itemImage: {
    width: 80,
    height: 80,
    borderRadius: 8,
    backgroundColor: '#FAF5EE',
  },
  itemDetails: {
    flex: 1,
    marginLeft: 12,
    justifyContent: 'space-between',
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  itemName: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
    flex: 1,
    marginRight: 6,
  },
  shopName: {
    fontSize: 11,
    color: COLORS.accent,
    fontWeight: '600',
  },
  variantName: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  bold: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  priceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginVertical: 4,
  },
  unitPrice: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primary,
  },
  discountBadge: {
    backgroundColor: '#FFE58F',
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  discountBadgeText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#874D00',
  },
  qtyRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 4,
  },
  stepper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.background,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  stepperBtn: {
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  stepperVal: {
    paddingHorizontal: 6,
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.textPrimary,
    minWidth: 26,
    textAlign: 'center',
  },
  itemTotal: {
    fontSize: 14,
    fontWeight: '900',
    color: COLORS.primaryDark,
  },

  // Summary
  summaryCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1,
    borderColor: '#E8D2A3',
    marginTop: 4,
    marginBottom: 20,
  },
  summaryHeading: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  summaryLabel: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  summaryValue: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  summaryDiscount: {
    fontSize: 12,
    fontWeight: '700',
    color: '#059669',
  },
  summaryDivider: {
    height: 1,
    backgroundColor: '#F5F0E6',
    marginVertical: 8,
  },
  totalLabel: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  totalPrice: {
    fontSize: 17,
    fontWeight: '900',
    color: COLORS.primary,
  },
  vatNoteBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F6FFED',
    padding: 8,
    borderRadius: 6,
    marginTop: 10,
  },
  vatNoteText: {
    fontSize: 10,
    color: '#059669',
    flex: 1,
    lineHeight: 14,
  },

  // Bottom Bar
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
  bottomInfo: {
    flex: 1,
  },
  bottomLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  bottomTotal: {
    fontSize: 17,
    fontWeight: '900',
    color: COLORS.primaryDark,
  },
  checkoutBtn: {
    marginLeft: 12,
    minWidth: 150,
  },
});
