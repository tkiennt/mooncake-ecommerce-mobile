import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
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
import { useAuth } from '../../context/AuthContext';
import { orderService } from '../../services/api/orderService';

export default function CheckoutScreen({ navigation }) {
  const { cartItems, getCartTotals, clearCart } = useCart();
  const { user } = useAuth();
  const { rawSubtotal, totalDiscount, finalTotal, totalItems } = getCartTotals();

  // Prefill only from the signed-in profile — never ship someone else's name/address as defaults.
  const [fullName, setFullName] = useState(user?.fullName || '');
  const [phoneNumber, setPhoneNumber] = useState(user?.phoneNumber || '');
  const [companyName, setCompanyName] = useState(user?.companyName || '');
  const [address, setAddress] = useState(user?.address || '');
  const [deliveryDate, setDeliveryDate] = useState('');
  const [notes, setNotes] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('vnpay'); // vnpay | escrow | cod
  const [loading, setLoading] = useState(false);

  const formatVND = (num) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(num);
  };

  const handlePlaceOrder = async () => {
    if (!fullName || !phoneNumber || !address) {
      Alert.alert('Thiếu thông tin', 'Vui lòng điền đầy đủ người nhận, số điện thoại và địa chỉ giao hàng.');
      return;
    }

    setLoading(true);

    // The backend creates one order per shop (POST /orders): group the cart by shop.
    const byShop = cartItems.reduce((groups, item) => {
      const key = item.product.shopId || 'demo';
      (groups[key] = groups[key] || []).push(item);
      return groups;
    }, {});
    const dateMatch = deliveryDate.match(/(\d{1,2})\/(\d{1,2})\/(\d{4})/);
    const deliveryDateExpected = dateMatch
      ? `${dateMatch[3]}-${dateMatch[2].padStart(2, '0')}-${dateMatch[1].padStart(2, '0')}`
      : null;

    try {
      if (byShop.demo) {
        // Bundled demo products have no shop on the server; treat like offline.
        throw Object.assign(new Error('demo'), { isDemoCart: true });
      }
      const created = [];
      for (const [shopId, items] of Object.entries(byShop)) {
        const lines = items.map((item) => ({ productId: item.product.id, variantId: item.variant.id, quantity: item.quantity }));
        // Quote first so the order is placed against the price the customer saw.
        const quote = await orderService.previewQuote({ shopId, items: lines }).catch(() => null);
        created.push(await orderService.create({
          shopId,
          items: lines,
          shippingZoneCode: null,
          deliveryAddress: address.trim(),
          recipientName: fullName.trim(),
          recipientPhone: phoneNumber.trim(),
          deliveryDateExpected,
          acceptedPriceVersion: quote?.priceVersion || null,
          notes: [companyName && `Đơn vị: ${companyName}`, notes].filter(Boolean).join(' · ') || null,
        }));
      }
      clearCart();
      Alert.alert(
        'Đã gửi đơn hàng',
        `${created.map((o) => `#${o.orderNumber}`).join(', ')} đã được gửi tới xưởng. Xưởng sẽ phản hồi trong thời hạn quy định; bạn thanh toán sau khi xưởng xác nhận.`,
        [{ text: 'Xem đơn hàng', onPress: () => navigation.navigate('MainTabs', { screen: 'OrdersTab' }) }],
      );
    } catch (e) {
      if (e?.response) {
        const code = e.response.data?.errorCode;
        Alert.alert(
          'Không đặt được hàng',
          code === 'PRICE_CHANGED'
            ? 'Giá sản phẩm vừa thay đổi. Vui lòng xem lại giỏ hàng và đặt lại.'
            : code === 'INSUFFICIENT_STOCK'
              ? 'Số lượng vượt quá tồn kho của xưởng. Vui lòng giảm số lượng.'
              : e.response.data?.message || 'Vui lòng thử lại sau.',
        );
      } else {
        // Offline / demo cart: nothing is sent to a server.
        clearCart();
        Alert.alert(
          'Đặt hàng (chế độ demo)',
          'Không kết nối được máy chủ hoặc giỏ chứa sản phẩm mẫu, nên đơn chỉ được mô phỏng trên máy.',
          [{ text: 'Xem danh sách đơn', onPress: () => navigation.navigate('MainTabs', { screen: 'OrdersTab' }) }],
        );
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Xác Nhận Đặt Hàng"
        subtitle="Thông tin giao hàng & Thanh toán"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Recipient Information */}
        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>
            <Ionicons name="location-outline" size={16} color={COLORS.primary} /> Thông Tin Giao Nhận Doanh Nghiệp
          </Text>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Tên người nhận đại diện</Text>
            <TextInput
              style={styles.input}
              value={fullName}
              placeholder="Họ tên người nhận hàng"
              placeholderTextColor={COLORS.textMuted}
              onChangeText={setFullName}
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Số điện thoại liên hệ</Text>
            <TextInput
              style={styles.input}
              value={phoneNumber}
              placeholder="Số điện thoại liên hệ"
              placeholderTextColor={COLORS.textMuted}
              onChangeText={setPhoneNumber}
              keyboardType="phone-pad"
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Tên doanh nghiệp xuất VAT</Text>
            <TextInput
              style={styles.input}
              value={companyName}
              placeholder="Tên doanh nghiệp trên hóa đơn VAT"
              placeholderTextColor={COLORS.textMuted}
              onChangeText={setCompanyName}
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Địa chỉ kho / trụ sở giao hàng</Text>
            <TextInput
              style={[styles.input, styles.multiline]}
              value={address}
              placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành"
              placeholderTextColor={COLORS.textMuted}
              onChangeText={setAddress}
              multiline
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Ngày mong muốn giao hàng</Text>
            <TextInput
              style={styles.input}
              value={deliveryDate}
              placeholder="dd/mm/yyyy (không bắt buộc)"
              placeholderTextColor={COLORS.textMuted}
              onChangeText={setDeliveryDate}
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Ghi chú đóng gói & bảo quản</Text>
            <TextInput
              style={[styles.input, styles.multiline]}
              value={notes}
              placeholder="Yêu cầu đóng gói, giờ nhận hàng… (không bắt buộc)"
              placeholderTextColor={COLORS.textMuted}
              onChangeText={setNotes}
              multiline
            />
          </View>
        </View>

        {/* Payment Methods */}
        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>
            <Ionicons name="card-outline" size={16} color={COLORS.primary} /> Phương Thức Thanh Toán
          </Text>

          <TouchableOpacity
            style={[styles.payOption, paymentMethod === 'vnpay' && styles.payOptionActive]}
            onPress={() => setPaymentMethod('vnpay')}
          >
            <Ionicons name="qr-code-outline" size={20} color={COLORS.primary} />
            <View style={styles.payInfo}>
              <Text style={styles.payTitle}>VNPay / Mobile Banking QR (Khuyên dùng)</Text>
              <Text style={styles.paySub}>Quét mã VietQR chuyển khoản tự động qua app ngân hàng</Text>
            </View>
            <View style={styles.radio}>
              {paymentMethod === 'vnpay' && <View style={styles.radioInner} />}
            </View>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.payOption, paymentMethod === 'escrow' && styles.payOptionActive]}
            onPress={() => setPaymentMethod('escrow')}
          >
            <Ionicons name="shield-checkmark-outline" size={20} color={COLORS.accent} />
            <View style={styles.payInfo}>
              <Text style={styles.payTitle}>Ký Quỹ SafeTrade Escrow B2B</Text>
              <Text style={styles.paySub}>Tiền cọc giữ an toàn bởi sàn, chỉ giải ngân khi nhận bánh đạt chuẩn</Text>
            </View>
            <View style={styles.radio}>
              {paymentMethod === 'escrow' && <View style={styles.radioInner} />}
            </View>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.payOption, paymentMethod === 'cod' && styles.payOptionActive]}
            onPress={() => setPaymentMethod('cod')}
          >
            <Ionicons name="cash-outline" size={20} color={COLORS.textSecondary} />
            <View style={styles.payInfo}>
              <Text style={styles.payTitle}>Thanh toán khi nhận hàng (COD)</Text>
              <Text style={styles.paySub}>Áp dụng cho đơn thử nghiệm hoặc giá trị dưới 20 triệu VNĐ</Text>
            </View>
            <View style={styles.radio}>
              {paymentMethod === 'cod' && <View style={styles.radioInner} />}
            </View>
          </TouchableOpacity>
        </View>

        {/* Bill Summary */}
        <View style={styles.sectionCard}>
          <Text style={styles.sectionTitle}>Tóm Tắt Thanh Toán</Text>

          <View style={styles.billRow}>
            <Text style={styles.billLabel}>Tổng số lượng đặt</Text>
            <Text style={styles.billVal}>{totalItems} hộp bánh</Text>
          </View>
          <View style={styles.billRow}>
            <Text style={styles.billLabel}>Tạm tính tiền hàng</Text>
            <Text style={styles.billVal}>{formatVND(rawSubtotal)}</Text>
          </View>
          {totalDiscount > 0 && (
            <View style={styles.billRow}>
              <Text style={[styles.billLabel, styles.green]}>Chiết khấu số lượng lớn</Text>
              <Text style={[styles.billVal, styles.green]}>-{formatVND(totalDiscount)}</Text>
            </View>
          )}
          <View style={styles.billDivider} />
          <View style={styles.billRow}>
            <Text style={styles.totalLabel}>Tổng cộng phải trả:</Text>
            <Text style={styles.totalPrice}>{formatVND(finalTotal)}</Text>
          </View>
        </View>

        <CustomButton
          title="Xác Nhận & Hoàn Tất Đơn Hàng"
          onPress={handlePlaceOrder}
          loading={loading}
          size="large"
          style={styles.orderBtn}
        />
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
  sectionCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 14,
  },
  inputBox: {
    marginBottom: 12,
  },
  label: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: COLORS.textPrimary,
    backgroundColor: '#FAFAF8',
  },
  multiline: {
    minHeight: 55,
    textAlignVertical: 'top',
  },
  payOption: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
    backgroundColor: '#FFF',
  },
  payOptionActive: {
    borderColor: COLORS.primary,
    backgroundColor: 'rgba(140, 21, 36, 0.03)',
  },
  payInfo: {
    flex: 1,
    marginHorizontal: 10,
  },
  payTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  paySub: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  radio: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: COLORS.primary,
  },
  billRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  billLabel: {
    fontSize: 13,
    color: COLORS.textSecondary,
  },
  billVal: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  green: {
    color: '#389E0D',
    fontWeight: '700',
  },
  billDivider: {
    height: 1,
    backgroundColor: COLORS.border,
    marginVertical: 10,
  },
  totalLabel: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  totalPrice: {
    fontSize: 18,
    fontWeight: '800',
    color: COLORS.primary,
  },
  orderBtn: {
    marginTop: 10,
    marginBottom: 20,
  },
});

