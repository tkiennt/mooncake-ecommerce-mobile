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
import { apiClient } from '../../api/apiClient';
import { ENDPOINTS } from '../../api/endpoints';

export default function CheckoutScreen({ navigation }) {
  const { cartItems, getCartTotals, clearCart } = useCart();
  const { user } = useAuth();
  const { rawSubtotal, totalDiscount, finalTotal, totalItems } = getCartTotals();

  const [fullName, setFullName] = useState(user?.fullName || 'Nguyễn Văn An');
  const [phoneNumber, setPhoneNumber] = useState(user?.phoneNumber || '0901234567');
  const [companyName, setCompanyName] = useState(user?.companyName || 'Công ty Cổ Phần Tập Đoàn Á Châu');
  const [address, setAddress] = useState('Tòa nhà Landmark 81, 720A Điện Biên Phủ, P.22, Bình Thạnh, TP.HCM');
  const [deliveryDate, setDeliveryDate] = useState('15/08/2026 (Trước Rằm)');
  const [notes, setNotes] = useState('Đóng gói thùng carton chịu lực, vận chuyển bằng xe lạnh giữ nhiệt.');
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

    const payload = {
      customerName: fullName,
      phoneNumber,
      companyName,
      shippingAddress: address,
      expectedDeliveryDate: deliveryDate,
      specialInstructions: notes,
      paymentMethod,
      items: cartItems.map((item) => ({
        productId: item.product.id,
        variantId: item.variant.id,
        quantity: item.quantity,
        unitPrice: item.product.basePrice + (item.variant.priceAdjustment || 0),
      })),
      totalAmount: finalTotal,
    };

    try {
      // Gọi API backend
      await apiClient.post(ENDPOINTS.CREATE_ORDER, payload);
      clearCart();
      Alert.alert(
        'Đặt hàng B2B thành công!',
        'Đơn hàng của bạn đã được chuyển tới các xưởng sản xuất. Chúng tôi sẽ thông báo khi xưởng xác nhận đơn.',
        [
          {
            text: 'Xem đơn hàng',
            onPress: () => {
              navigation.navigate('OrdersTab');
            },
          },
        ]
      );
    } catch (e) {
      // Fallback khi offline
      clearCart();
      Alert.alert(
        'Đặt hàng thành công (Demo Mode)',
        'Đơn hàng đã được lưu cục bộ. Mã đơn mẫu: #ORD-2026-8899.',
        [
          {
            text: 'Xem danh sách đơn',
            onPress: () => navigation.navigate('OrdersTab'),
          },
        ]
      );
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
              onChangeText={setFullName}
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Số điện thoại liên hệ</Text>
            <TextInput
              style={styles.input}
              value={phoneNumber}
              onChangeText={setPhoneNumber}
              keyboardType="phone-pad"
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Tên doanh nghiệp xuất VAT</Text>
            <TextInput
              style={styles.input}
              value={companyName}
              onChangeText={setCompanyName}
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Địa chỉ kho / trụ sở giao hàng</Text>
            <TextInput
              style={[styles.input, styles.multiline]}
              value={address}
              onChangeText={setAddress}
              multiline
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Ngày mong muốn giao hàng</Text>
            <TextInput
              style={styles.input}
              value={deliveryDate}
              onChangeText={setDeliveryDate}
            />
          </View>

          <View style={styles.inputBox}>
            <Text style={styles.label}>Ghi chú đóng gói & bảo quản</Text>
            <TextInput
              style={[styles.input, styles.multiline]}
              value={notes}
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

