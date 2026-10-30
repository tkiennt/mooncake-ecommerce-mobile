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

  if (cartItems.length === 0) {
    return (
      <View style={styles.container}>
        <AppHeader title="Giỏ Hàng Doanh Nghiệp" />
        <View style={styles.emptyContainer}>
          <Ionicons name="cart-outline" size={64} color={COLORS.textMuted} />
          <Text style={styles.emptyTitle}>Giỏ hàng đang trống</Text>
          <Text style={styles.emptySub}>
            Khám phá các bộ sưu tập quà tặng Trung Thu hoàng gia và chọn sản phẩm yêu thích.
          </Text>
          <CustomButton
            title="Khám Phá Ngay"
            onPress={() => navigation.navigate('HomeTab')}
            size="medium"
            style={styles.browseBtn}
          />
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
            <View key={`${item.product.id}-${item.variant.id}`} style={styles.cartCard}>
              <Image
                source={{ uri: item.product.coverImage }}
                style={styles.itemImg}
                resizeMode="cover"
              />
              <View style={styles.itemContent}>
                <View style={styles.itemHeader}>
                  <Text style={styles.shopName} numberOfLines={1}>
                    {item.product.shopName}
                  </Text>
                  <TouchableOpacity
                    onPress={() => removeFromCart(item.product.id, item.variant.id)}
                  >
                    <Ionicons name="close" size={18} color={COLORS.textMuted} />
                  </TouchableOpacity>
                </View>

                <Text style={styles.prodName} numberOfLines={1}>
                  {item.product.name}
                </Text>

                <View style={styles.variantBadge}>
                  <Text style={styles.variantText} numberOfLines={1}>
                    Vị: {item.variant.name}
                  </Text>
                </View>

                {calc.discountPercent > 0 && (
                  <View style={styles.discountRow}>
                    <Text style={styles.discountBadge}>
                      Chiết khấu sỉ: -{calc.discountPercent}%
                    </Text>
                  </View>
                )}

                <View style={styles.itemFooter}>
                  <View style={styles.qtyControls}>
                    <TouchableOpacity
                      style={styles.qtyBtn}
                      onPress={() =>
                        updateQuantity(item.product.id, item.variant.id, item.quantity - 1)
                      }
                    >
                      <Ionicons name="remove" size={14} color={COLORS.primary} />
                    </TouchableOpacity>
                    <Text style={styles.qtyText}>{item.quantity}</Text>
                    <TouchableOpacity
                      style={styles.qtyBtn}
                      onPress={() =>
                        updateQuantity(item.product.id, item.variant.id, item.quantity + 1)
                      }
                    >
                      <Ionicons name="add" size={14} color={COLORS.primary} />
                    </TouchableOpacity>
                  </View>

                  <View style={styles.priceCol}>
                    <Text style={styles.itemTotal}>{formatVND(calc.total)}</Text>
                    {calc.discountAmount > 0 && (
                      <Text style={styles.itemRawPrice}>{formatVND(calc.subtotal)}</Text>
                    )}
                  </View>
                </View>
              </View>
            </View>
          );
        })}

        {/* Order Summary Card */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryTitle}>Tóm Tắt Đơn Hàng B2B</Text>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Tổng số lượng</Text>
            <Text style={styles.summaryVal}>{totalItems} hộp</Text>
          </View>

          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Tổng tiền cơ bản</Text>
            <Text style={styles.summaryVal}>{formatVND(rawSubtotal)}</Text>
          </View>

          {totalDiscount > 0 && (
            <View style={styles.summaryRow}>
              <Text style={[styles.summaryLabel, styles.greenText]}>Chiết khấu theo số lượng</Text>
              <Text style={[styles.summaryVal, styles.greenText]}>-{formatVND(totalDiscount)}</Text>
            </View>
          )}

          <View style={styles.summaryDivider} />

          <View style={styles.summaryRow}>
            <Text style={styles.finalTotalLabel}>Tổng thanh toán</Text>
            <Text style={styles.finalTotalVal}>{formatVND(finalTotal)}</Text>
          </View>
        </View>
      </ScrollView>

      {/* Sticky Bottom Bar */}
      <View style={styles.checkoutBar}>
        <View>
          <Text style={styles.barLabel}>Tổng đơn:</Text>
          <Text style={styles.barPrice}>{formatVND(finalTotal)}</Text>
        </View>
        <CustomButton
          title="Tiến Hành Đặt Hàng"
          icon="💳"
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
    paddingBottom: 110,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 30,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: 16,
  },
  emptySub: {
    fontSize: 13,
    color: COLORS.textMuted,
    textAlign: 'center',
    marginTop: 8,
    lineHeight: 20,
    marginBottom: 20,
  },
  browseBtn: {
    minWidth: 160,
  },
  cartCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 12,
    flexDirection: 'row',
    marginBottom: 12,
  },
  itemImg: {
    width: 84,
    height: 84,
    borderRadius: 8,
    backgroundColor: '#F0ECE4',
  },
  itemContent: {
    flex: 1,
    marginLeft: 12,
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  shopName: {
    fontSize: 11,
    color: COLORS.accent,
    fontWeight: '600',
  },
  prodName: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: 2,
  },
  variantBadge: {
    alignSelf: 'flex-start',
    backgroundColor: '#FAFAF8',
    borderWidth: 1,
    borderColor: COLORS.border,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    marginTop: 4,
  },
  variantText: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  discountRow: {
    marginTop: 4,
  },
  discountBadge: {
    fontSize: 10,
    fontWeight: '700',
    color: '#389E0D',
  },
  itemFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 10,
  },
  qtyControls: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 6,
  },
  qtyBtn: {
    paddingHorizontal: 8,
    paddingVertical: 4,
  },
  qtyText: {
    fontSize: 13,
    fontWeight: '700',
    paddingHorizontal: 8,
  },
  priceCol: {
    alignItems: 'flex-end',
  },
  itemTotal: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primary,
  },
  itemRawPrice: {
    fontSize: 11,
    color: COLORS.textMuted,
    textDecorationLine: 'line-through',
  },
  summaryCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginTop: 8,
  },
  summaryTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 12,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  summaryLabel: {
    fontSize: 13,
    color: COLORS.textSecondary,
  },
  summaryVal: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  greenText: {
    color: '#389E0D',
    fontWeight: '700',
  },
  summaryDivider: {
    height: 1,
    backgroundColor: COLORS.border,
    marginVertical: 10,
  },
  finalTotalLabel: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  finalTotalVal: {
    fontSize: 18,
    fontWeight: '800',
    color: COLORS.primary,
  },
  checkoutBar: {
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
    justifyContent: 'space-between',
    alignItems: 'center',
    elevation: 8,
  },
  barLabel: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  barPrice: {
    fontSize: 18,
    fontWeight: '800',
    color: COLORS.primary,
  },
  checkoutBtn: {
    paddingHorizontal: 22,
  },
});
