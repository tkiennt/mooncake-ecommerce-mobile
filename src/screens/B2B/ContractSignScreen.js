import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import AntdSteps from '../../components/antd/AntdSteps';
import AntdOtpInput from '../../components/antd/AntdOtpInput';
import { contractService } from '../../services/api/contractService';

export default function ContractSignScreen({ route, navigation }) {
  const { bid, rfq, contract } = route.params || {};
  const contractNumber = contract?.contractNumber || route.params?.contractNumber;

  const [agreed, setAgreed] = useState(false);
  const [otpCode, setOtpCode] = useState('');
  const [loading, setLoading] = useState(false);

  const handleOtpComplete = (code) => {
    setOtpCode(code);
  };

  const handleConfirmSign = async () => {
    if (!agreed) {
      Alert.alert('Chưa xác nhận điều khoản', 'Vui lòng đánh dấu vào ô đồng ý với các điều khoản pháp lý và bảo chứng SafeTrade.');
      return;
    }
    if (otpCode.length < 6) {
      Alert.alert('Chưa nhập đủ OTP', 'Vui lòng nhập đủ 6 chữ số mã OTP xác thực.');
      return;
    }

    setLoading(true);
    const done = (title, message) => Alert.alert(title, message, [
      { text: 'Về danh sách hợp đồng', onPress: () => navigation.navigate('Contracts') },
    ]);
    if (!contract?.isFromApi) {
      setLoading(false);
      done('Chế độ demo', 'Đây là hợp đồng mẫu nên không có chữ ký thật nào được ghi nhận.');
      return;
    }
    try {
      // POST /contracts/{id}/sign { otpCode, confirmTerms }
      await contractService.sign(contract.id, otpCode, true);
      done('Đã ký hợp đồng', `Hợp đồng ${contract.contractNumber} đã được ký. Bước tiếp theo: thanh toán khoản đặt cọc để xưởng bắt đầu sản xuất.`);
    } catch (error) {
      Alert.alert('Không ký được hợp đồng', error?.response?.data?.message || 'Mã OTP không đúng hoặc đã hết hạn.');
    } finally {
      setLoading(false);
    }
  };

  // Ask the backend to send the signing OTP when a real contract opens.
  useEffect(() => {
    if (!contract?.isFromApi) return;
    contractService.requestSignatureOtp(contract.id)
      .catch((error) => Alert.alert('Không gửi được mã OTP', error?.response?.data?.message || 'Vui lòng thử lại.'));
  }, [contract?.id]);

  return (
    <View style={styles.container}>
      <AppHeader
        title="Ký hợp đồng"
        subtitle={contractNumber || 'Hợp đồng mẫu'}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Ant Design Steps: Bước 3 */}
        <View style={styles.stepsCard}>
          <AntdSteps
            current={2}
            items={[
              { title: '1. Nhu Cầu', desc: 'Đã hoàn tất' },
              { title: '2. Báo Giá', desc: 'Đã duyệt Bid' },
              { title: '3. Ký HĐ', desc: 'Ký số & Cọc M1' },
            ]}
          />
        </View>

        {/* Parties Box */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>CÁC BÊN THAM GIA HỢP ĐỒNG</Text>

          <View style={styles.partyItem}>
            <Text style={styles.partyRole}>BÊN A (BÊN MUA):</Text>
            <Text style={styles.partyName}>Công ty Cổ Phần Tập Đoàn Á Châu</Text>
            <Text style={styles.partyMeta}>MST: 0312456789 • Đại diện: Nguyễn Văn An</Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.partyItem}>
            <Text style={styles.partyRole}>BÊN B (XƯỞNG CUNG CẤP):</Text>
            <Text style={styles.partyName}>{bid?.supplierName || 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ'}</Text>
            <Text style={styles.partyMeta}>MST: 0108991234 • Chứng nhận: ISO 22000 & HACCP</Text>
          </View>
        </View>

        {/* Terms Box */}
        <View style={styles.card}>
          <Text style={styles.cardHeading}>ĐIỀU KHOẢN & TIẾN ĐỘ THỰC HIỆN</Text>

          <View style={styles.termRow}>
            <Ionicons name="cube-outline" size={16} color={COLORS.primary} />
            <Text style={styles.termText}>
              Gói sản phẩm: <Text style={styles.bold}>{rfq?.title || '350 Hộp Bánh Hoàng Triều Thượng Hạng'}</Text>
            </Text>
          </View>

          <View style={styles.termRow}>
            <Ionicons name="cash-outline" size={16} color={COLORS.primary} />
            <Text style={styles.termText}>
              Tổng giá trị HĐ: <Text style={styles.boldPrice}>238.000.000 ₫ (Đã gồm 8% VAT)</Text>
            </Text>
          </View>

          <View style={styles.termRow}>
            <Ionicons name="snow-outline" size={16} color={COLORS.accent} />
            <Text style={styles.termText}>
              Quy cách giao: Vận chuyển xe lạnh 20-25°C, giao đa điểm theo danh sách chi nhánh.
            </Text>
          </View>

          <View style={styles.termRow}>
            <Ionicons name="shield-checkmark-outline" size={16} color="#059669" />
            <Text style={styles.termText}>
              Bảo chứng SafeTrade: Tiền cọc được giữ tại tài khoản ký quỹ trung gian, chỉ giải ngân từng mốc sau khi ký biên bản PoD.
            </Text>
          </View>
        </View>

        {/* Agreement Checkbox */}
        <TouchableOpacity
          style={styles.checkboxRow}
          activeOpacity={0.8}
          onPress={() => setAgreed(!agreed)}
        >
          <Ionicons
            name={agreed ? 'checkbox' : 'square-outline'}
            size={22}
            color={COLORS.primary}
          />
          <Text style={styles.checkboxLabel}>
            Tôi là người đại diện hợp pháp của doanh nghiệp, đã đọc kỹ và đồng ý toàn bộ điều khoản hợp đồng kinh tế điện tử nói trên.
          </Text>
        </TouchableOpacity>

        {/* Ant Design OTP 6-Digit Input Box */}
        <View style={styles.otpCard}>
          <View style={styles.otpHeader}>
            <Ionicons name="key-outline" size={18} color={COLORS.primary} />
            <Text style={styles.otpTitle}>Xác Thực Chữ Ký Số Doanh Nghiệp</Text>
          </View>
          <Text style={styles.otpSub}>
            Mã OTP 6 số bảo mật đã được gửi tới số điện thoại đại diện pháp luật {__DEV__ ? <Text> (Mã demo: <Text style={styles.bold}>123456</Text>)</Text> : null}.
          </Text>

          <AntdOtpInput
            length={6}
            onComplete={handleOtpComplete}
            countdownSeconds={60}
            onResend={() => Alert.alert('OTP mới', 'Mã xác thực mới đã gửi về số điện thoại của bạn.')}
          />
        </View>

        {/* Action Button */}
        <CustomButton
          title={loading ? 'Đang tạo chữ ký số...' : 'Xác Nhận Ký Hợp Đồng Điện Tử'}
          icon="✍️"
          onPress={handleConfirmSign}
          disabled={loading || !agreed}
          style={styles.signBtn}
        />
        <View style={{ height: 40 }} />
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
  stepsCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 12,
  },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  cardHeading: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 12,
    letterSpacing: 0.5,
  },
  partyItem: {
    gap: 3,
  },
  partyRole: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.accent,
  },
  partyName: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.textPrimary,
  },
  partyMeta: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  divider: {
    height: 1,
    backgroundColor: '#F5F0E6',
    marginVertical: 12,
  },
  termRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    marginBottom: 10,
  },
  termText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    flex: 1,
    lineHeight: 18,
  },
  bold: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  boldPrice: {
    fontWeight: '800',
    color: COLORS.primary,
  },
  checkboxRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    backgroundColor: COLORS.surface,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 14,
  },
  checkboxLabel: {
    fontSize: 12,
    color: COLORS.textPrimary,
    flex: 1,
    lineHeight: 18,
  },
  otpCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
    marginBottom: 16,
  },
  otpHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  otpTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  otpSub: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginBottom: 8,
  },
  signBtn: {
    marginTop: 4,
  },
});
