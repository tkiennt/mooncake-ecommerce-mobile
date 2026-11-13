import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
  TouchableOpacity,
  Linking,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { paymentService } from '../../services/api/paymentService';
import CustomButton from '../../components/common/CustomButton';

const formatVND = (value = 0) => `${Math.round(value).toLocaleString('vi-VN')} ₫`;

const parseVnPayDate = (str) => {
  if (!str || str.length < 14) return new Date().toLocaleString('vi-VN');
  const year = str.substring(0, 4);
  const month = str.substring(4, 6);
  const day = str.substring(6, 8);
  const hour = str.substring(8, 10);
  const minute = str.substring(10, 12);
  const second = str.substring(12, 14);
  return `${hour}:${minute}:${second} - ${day}/${month}/${year}`;
};

const VNPAY_ERROR_CODES = {
  '07': 'Trừ tiền thành công. Giao dịch bị nghi ngờ gian lận.',
  '09': 'Thẻ/Tài khoản chưa đăng ký dịch vụ InternetBanking tại ngân hàng.',
  '10': 'Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần.',
  '11': 'Đã hết hạn chờ thanh toán. Xin vui lòng thử lại giao dịch.',
  '12': 'Thẻ/Tài khoản bị khóa hoặc không đủ hạn mức.',
  '13': 'Quý khách nhập sai mật khẩu xác thực giao dịch (OTP).',
  '24': 'Khách hàng đã hủy giao dịch trên cổng thanh toán.',
  '51': 'Tài khoản không đủ số dư để thực hiện giao dịch.',
  '65': 'Tài khoản đã vượt quá hạn mức giao dịch trong ngày.',
  '75': 'Ngân hàng thanh toán đang bảo trì hệ thống.',
  '79': 'Khách hàng nhập sai mật khẩu thanh toán quá số lần quy định.',
  '99': 'Lỗi không xác định từ cổng VNPay.',
};

export default function PaymentResultScreen({ route, navigation }) {
  const insets = useSafeAreaInsets();
  const [verifying, setVerifying] = useState(true);
  const [verificationResult, setVerificationResult] = useState(null);
  const [params, setParams] = useState(route?.params || {});

  useEffect(() => {
    let isMounted = true;

    async function handleIncomingUrl() {
      try {
        let incomingParams = { ...(route?.params || {}) };

        // If route params are empty, try checking initial or current URL
        if (!incomingParams.vnp_ResponseCode && !incomingParams.vnp_TransactionNo) {
          const initialUrl = await Linking.getInitialURL();
          if (initialUrl && initialUrl.includes('?')) {
            const queryStr = initialUrl.split('?')[1];
            const parsed = new URLSearchParams(queryStr);
            parsed.forEach((val, key) => {
              incomingParams[key] = val;
            });
          }
        }

        if (isMounted) {
          setParams(incomingParams);
        }

        // Reconstruct query string for backend verification
        const queryPairs = Object.entries(incomingParams)
          .filter(([k]) => k.startsWith('vnp_'))
          .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`);

        if (queryPairs.length > 0) {
          const queryString = queryPairs.join('&');
          const verifyData = await paymentService.verifyReturnCallback(queryString).catch((err) => {
            console.warn('Backend verification call error:', err);
            return null;
          });
          if (isMounted) {
            setVerificationResult(verifyData);
          }
        }
      } catch (err) {
        console.warn('Error verifying VNPay return:', err);
      } finally {
        if (isMounted) {
          setVerifying(false);
        }
      }
    }

    handleIncomingUrl();
    return () => {
      isMounted = false;
    };
  }, [route?.params]);

  const responseCode = params.vnp_ResponseCode || params.responseCode || '99';
  const isSuccess = responseCode === '00';
  const amount = params.vnp_Amount ? Number(params.vnp_Amount) / 100 : 0;
  const transactionNo = params.vnp_TransactionNo || '---';
  const bankCode = params.vnp_BankCode || 'VNPay';
  const orderInfo = params.vnp_OrderInfo ? decodeURIComponent(params.vnp_OrderInfo) : 'Thanh toán đơn hàng / hợp đồng';
  const payDate = parseVnPayDate(params.vnp_PayDate);
  const txnRef = params.vnp_TxnRef || '';

  return (
    <View style={[styles.container, { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 16 }]}>
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Status Illustration */}
        <View style={styles.centerBox}>
          {verifying ? (
            <View style={styles.iconCircleVerifying}>
              <ActivityIndicator size="large" color={COLORS.primary} />
            </View>
          ) : isSuccess ? (
            <View style={[styles.iconCircle, styles.iconCircleSuccess]}>
              <Ionicons name="shield-checkmark" size={56} color={COLORS.success} />
            </View>
          ) : (
            <View style={[styles.iconCircle, styles.iconCircleError]}>
              <Ionicons name="close-circle" size={56} color={COLORS.error} />
            </View>
          )}

          <Text style={styles.statusTitle}>
            {verifying
              ? 'Đang đối soát giao dịch VNPay...'
              : isSuccess
              ? 'Thanh toán thành công!'
              : 'Giao dịch chưa hoàn tất'}
          </Text>

          <Text style={styles.statusSub}>
            {verifying
              ? 'Vui lòng chờ trong giây lát để hệ thống kiểm tra chữ ký số và cập nhật số dư Escrow.'
              : isSuccess
              ? 'Khoản tiền đã được ghi nhận và giữ bảo chứng an toàn trong tài khoản Escrow.'
              : (VNPAY_ERROR_CODES[responseCode] || 'Giao dịch bị từ chối hoặc khách hàng đã hủy.')}
          </Text>
        </View>

        {/* Amount Box */}
        {amount > 0 && (
          <View style={styles.amountCard}>
            <Text style={styles.amountLabel}>Số tiền đã thanh toán</Text>
            <Text style={styles.amountValue}>{formatVND(amount)}</Text>
          </View>
        )}

        {/* Transaction Details Receipt */}
        <View style={styles.receiptCard}>
          <Text style={styles.receiptHeading}>Chi tiết giao dịch</Text>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Mã giao dịch VNPay</Text>
            <Text style={styles.detailValueBold}>{transactionNo}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Cổng thanh toán</Text>
            <Text style={styles.detailValue}>VNPay Sandbox ({bankCode})</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Thời gian</Text>
            <Text style={styles.detailValue}>{payDate}</Text>
          </View>

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Mã tham chiếu đơn</Text>
            <Text style={styles.detailValue}>{txnRef || 'N/A'}</Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.detailRow}>
            <Text style={styles.detailLabel}>Nội dung</Text>
            <Text style={[styles.detailValue, { flex: 1, textAlign: 'right' }]} numberOfLines={2}>
              {orderInfo}
            </Text>
          </View>

          {verificationResult?.message && (
            <View style={styles.verifiedNotice}>
              <Ionicons name="checkmark-done" size={14} color={COLORS.success} />
              <Text style={styles.verifiedText}>{verificationResult.message}</Text>
            </View>
          )}
        </View>

        {/* Action Buttons */}
        <View style={styles.buttonStack}>
          {txnRef ? (
            <CustomButton
              title="Xem chi tiết đơn hàng"
              icon="receipt-outline"
              onPress={() => {
                navigation.navigate('OrderDetail', { orderId: txnRef });
              }}
              style={styles.primaryBtn}
            />
          ) : null}

          <TouchableOpacity
            style={styles.secondaryBtn}
            onPress={() => navigation.navigate('MainTabs', { screen: 'OrdersTab' })}
          >
            <Ionicons name="list-outline" size={18} color={COLORS.primary} />
            <Text style={styles.secondaryBtnText}>Xem danh sách đơn đã mua</Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.ghostBtn}
            onPress={() => navigation.navigate('MainTabs', { screen: 'HomeTab' })}
          >
            <Text style={styles.ghostBtnText}>Về trang chủ Nguyệt Phố</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FDFBF7',
  },
  scroll: {
    paddingHorizontal: 20,
    paddingVertical: 10,
    alignItems: 'center',
  },
  centerBox: {
    alignItems: 'center',
    marginVertical: 16,
    paddingHorizontal: 12,
  },
  iconCircle: {
    width: 96,
    height: 96,
    borderRadius: 48,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  iconCircleVerifying: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: '#FFF1F0',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  iconCircleSuccess: {
    backgroundColor: '#F6FFED',
    borderWidth: 2,
    borderColor: '#B7EB8F',
  },
  iconCircleError: {
    backgroundColor: '#FFF1F0',
    borderWidth: 2,
    borderColor: '#FFA39E',
  },
  statusTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: COLORS.textPrimary,
    textAlign: 'center',
    marginBottom: 8,
  },
  statusSub: {
    fontSize: 14,
    color: COLORS.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 8,
  },
  amountCard: {
    width: '100%',
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginBottom: 16,
  },
  amountLabel: {
    fontSize: 13,
    color: COLORS.textSecondary,
    marginBottom: 4,
  },
  amountValue: {
    fontSize: 26,
    fontWeight: '800',
    color: COLORS.primary,
  },
  receiptCard: {
    width: '100%',
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: COLORS.border,
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
    marginBottom: 24,
  },
  receiptHeading: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 14,
  },
  detailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
  },
  detailLabel: {
    fontSize: 13,
    color: COLORS.textSecondary,
  },
  detailValue: {
    fontSize: 13,
    color: COLORS.textPrimary,
  },
  detailValueBold: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: COLORS.border,
    marginVertical: 6,
  },
  verifiedNotice: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F6FFED',
    padding: 8,
    borderRadius: 6,
    marginTop: 10,
  },
  verifiedText: {
    fontSize: 12,
    color: COLORS.success,
    fontWeight: '600',
  },
  buttonStack: {
    width: '100%',
    gap: 10,
  },
  primaryBtn: {
    width: '100%',
  },
  secondaryBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.primary,
    borderRadius: 8,
    paddingVertical: 14,
  },
  secondaryBtnText: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.primary,
  },
  ghostBtn: {
    alignItems: 'center',
    paddingVertical: 12,
  },
  ghostBtnText: {
    fontSize: 14,
    color: COLORS.textSecondary,
  },
});
