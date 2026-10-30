import React, { useState, useEffect } from 'react';
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

export default function ContractSignScreen({ route, navigation }) {
  const { bid, rfq, contractNumber } = route.params || {};

  const [agreed, setAgreed] = useState(false);
  const [otpCode, setOtpCode] = useState('');
  const [countdown, setCountdown] = useState(60);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    let timer;
    if (countdown > 0) {
      timer = setInterval(() => setCountdown((c) => c - 1), 1000);
    }
    return () => clearInterval(timer);
  }, [countdown]);

  const handleSendOtp = () => {
    setCountdown(60);
    Alert.alert('Mã OTP Mới', 'Mã xác thực 6 số đã được gửi tới số điện thoại đăng ký của bạn. (Mã demo: 123456)');
  };

  const handleConfirmSign = () => {
    if (!agreed) {
      Alert.alert('Chưa đồng ý điều khoản', 'Vui lòng đọc và bấm xác nhận đồng ý với các điều khoản hợp đồng.');
      return;
    }
    if (otpCode.length < 6) {
      Alert.alert('Mã OTP không hợp lệ', 'Vui lòng nhập đủ 6 chữ số mã OTP xác thực.');
      return;
    }

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      Alert.alert(
        'Ký Hợp Đồng Thành Công!',
        `Hợp đồng điện tử ${contractNumber || 'HĐ-2026-0812'} đã được ký kết và đóng dấu thời gian số hợp pháp.\n\nBước tiếp theo: Vui lòng thanh toán khoản Đặt Cọc M1 (30%) để xưởng chính thức kích hoạt dây chuyền sản xuất.`,
        [
          {
            text: 'Quản lý Hợp Đồng & Đặt Cọc',
            onPress: () => navigation.navigate('Contracts'),
          },
        ]
      );
    }, 1200);
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Ký Số Hợp Đồng Điện Tử"
        subtitle={contractNumber || 'HĐ-2026-0812'}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Parties Box */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>CÁC BÊN THAM GIA HỢP ĐỒNG</Text>

          <View style={styles.partyItem}>
            <Text style={styles.partyRole}>BÊN A (BÊN MUA):</Text>
            <Text style={styles.partyName}>Công ty Cổ Phần Tập Đoàn Á Châu</Text>
            <Text style={styles.partyMeta}>MST: 0312456789 • Đại diện: Nguyễn Văn An</Text>
          </View>

          <View style={styles.partyDivider} />

          <View style={styles.partyItem}>
            <Text style={styles.partyRole}>BÊN B (BÊN BÁN):</Text>
            <Text style={styles.partyName}>{bid?.supplierName || 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ'}</Text>
            <Text style={styles.partyMeta}>MST: 0108923456 • Chứng nhận ATTP số: 452/2026/ATTP</Text>
          </View>
        </View>

        {/* Scope and Terms Preview */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>TÓM TẮT ĐIỀU KHOẢN CHÍNH</Text>

          <View style={styles.termRow}>
            <Text style={styles.termLabel}>Gói hàng hóa:</Text>
            <Text style={styles.termVal}>{rfq?.title || '350 Hộp Bánh Hoàng Triều Thượng Hạng'}</Text>
          </View>
          <View style={styles.termRow}>
            <Text style={styles.termLabel}>Tổng giá trị thanh toán:</Text>
            <Text style={[styles.termVal, styles.price]}>238.000.000 ₫ (Đã gồm VAT 8%)</Text>
          </View>
          <View style={styles.termRow}>
            <Text style={styles.termLabel}>Điều khoản thanh toán:</Text>
            <Text style={styles.termVal}>M1: Đặt cọc 30% • M2: 50% khi giao hàng • M3: 20% khi nghiệm thu</Text>
          </View>
          <View style={styles.termRow}>
            <Text style={styles.termLabel}>Chế tài phạt vi phạm:</Text>
            <Text style={styles.termVal}>{bid?.penaltyTerms || 'Phạt 2% mỗi ngày trễ hạn, bồi thường 100% nếu hàng lỗi.'}</Text>
          </View>
        </View>

        {/* Agreement Checkbox */}
        <TouchableOpacity
          style={styles.checkContainer}
          onPress={() => setAgreed(!agreed)}
        >
          <Ionicons
            name={agreed ? 'checkbox' : 'square-outline'}
            size={24}
            color={COLORS.primary}
          />
          <Text style={styles.checkLabel}>
            Tôi cam kết đại diện pháp luật doanh nghiệp đã đọc, hiểu rõ và đồng ý toàn bộ điều khoản pháp lý trong dự thảo hợp đồng điện tử này.
          </Text>
        </TouchableOpacity>

        {/* OTP Section */}
        <View style={styles.otpCard}>
          <Text style={styles.otpHeading}>XÁC THỰC KÝ SỐ BẰNG OTP</Text>
          <Text style={styles.otpSub}>
            Mã OTP gồm 6 chữ số đã được gửi qua tin nhắn SMS tới số điện thoại của bạn.
          </Text>

          <View style={styles.otpInputRow}>
            <TextInput
              style={styles.otpInput}
              placeholder="Nhập mã OTP (ví dụ: 123456)"
              value={otpCode}
              onChangeText={setOtpCode}
              keyboardType="number-pad"
              maxLength={6}
            />
          </View>

          <TouchableOpacity
            style={styles.resendBtn}
            disabled={countdown > 0}
            onPress={handleSendOtp}
          >
            <Text style={[styles.resendText, countdown > 0 && { color: COLORS.textMuted }]}>
              {countdown > 0 ? `Gửi lại mã OTP sau ${countdown}s` : 'Gửi lại mã OTP'}
            </Text>
          </TouchableOpacity>
        </View>

        <CustomButton
          title="Xác Nhận Ký Số Điện Tử"
          icon="✍️"
          onPress={handleConfirmSign}
          loading={loading}
          disabled={!agreed}
          size="large"
          style={styles.signBtn}
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
  card: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
  },
  cardHeading: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primary,
    letterSpacing: 0.5,
    marginBottom: 12,
  },
  partyItem: {
    paddingVertical: 4,
  },
  partyRole: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.textMuted,
  },
  partyName: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: 2,
  },
  partyMeta: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  partyDivider: {
    height: 1,
    backgroundColor: COLORS.border,
    marginVertical: 10,
  },
  termRow: {
    marginBottom: 10,
  },
  termLabel: {
    fontSize: 12,
    color: COLORS.textMuted,
    fontWeight: '500',
  },
  termVal: {
    fontSize: 13,
    color: COLORS.textPrimary,
    fontWeight: '600',
    marginTop: 2,
    lineHeight: 18,
  },
  price: {
    color: COLORS.primary,
    fontSize: 15,
    fontWeight: '800',
  },
  checkContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: '#FAFAF8',
    padding: 14,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 16,
  },
  checkLabel: {
    flex: 1,
    fontSize: 12,
    color: COLORS.textPrimary,
    marginLeft: 10,
    lineHeight: 18,
  },
  otpCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 20,
    alignItems: 'center',
  },
  otpHeading: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.textPrimary,
  },
  otpSub: {
    fontSize: 12,
    color: COLORS.textMuted,
    textAlign: 'center',
    marginTop: 4,
    marginBottom: 14,
  },
  otpInputRow: {
    width: '100%',
    alignItems: 'center',
  },
  otpInput: {
    borderWidth: 1.5,
    borderColor: COLORS.primary,
    borderRadius: 8,
    width: '80%',
    height: 48,
    textAlign: 'center',
    fontSize: 18,
    fontWeight: '700',
    letterSpacing: 4,
    backgroundColor: '#FAFAF8',
    color: COLORS.textPrimary,
  },
  resendBtn: {
    marginTop: 12,
  },
  resendText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.primary,
  },
  signBtn: {
    marginBottom: 20,
  },
});
