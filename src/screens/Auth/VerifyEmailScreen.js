import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import AntdOtpInput from '../../components/antd/AntdOtpInput';
import { authService } from '../../services/api/authService';

export default function VerifyEmailScreen({ route, navigation }) {
  const email = route?.params?.email || '';
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);

  const handleVerify = async () => {
    if (!otp || otp.length !== 6) {
      Alert.alert('Chưa đủ mã', 'Vui lòng nhập đủ 6 chữ số mã xác thực OTP.');
      return;
    }

    setLoading(true);
    try {
      await authService.verifyEmail(email, otp);
      Alert.alert(
        'Kích hoạt thành công',
        'Email của bạn đã được xác minh thành công. Hãy đăng nhập để bắt đầu đặt hàng.',
        [
          {
            text: 'Đăng nhập ngay',
            onPress: () => navigation.navigate('Login'),
          },
        ]
      );
    } catch (e) {
      Alert.alert(
        'Mã không hợp lệ',
        e?.response?.data?.message || 'Mã OTP không đúng hoặc đã hết hạn. Vui lòng thử lại.'
      );
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    try {
      await authService.resendVerification(email);
      Alert.alert('Đã gửi lại mã', `Mã OTP mới đã được gửi về hòm thư ${email}.`);
    } catch (e) {
      Alert.alert('Không gửi được', e?.response?.data?.message || 'Vui lòng thử lại sau giây lát.');
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <AppHeader
        title="Xác thực Email"
        subtitle="Kích hoạt tài khoản mua sắm"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <View style={styles.centerBox}>
          <View style={styles.iconCircle}>
            <Ionicons name="mail-open-outline" size={48} color={COLORS.primary} />
          </View>

          <Text style={styles.title}>Nhập mã xác thực 6 số</Text>
          <Text style={styles.desc}>
            Chúng tôi đã gửi mã xác thực gồm 6 chữ số đến địa chỉ email:
          </Text>
          <Text style={styles.emailText}>{email || 'email của bạn'}</Text>
        </View>

        <View style={styles.card}>
          <AntdOtpInput
            length={6}
            onComplete={(code) => setOtp(code)}
            countdownSeconds={60}
            onResend={handleResend}
          />

          <CustomButton
            title="Xác nhận & Kích hoạt"
            icon="checkmark-circle-outline"
            onPress={handleVerify}
            loading={loading}
            size="large"
            style={styles.verifyBtn}
          />
        </View>

        <TouchableOpacity
          style={styles.changeEmailBtn}
          onPress={() => navigation.navigate('Register')}
        >
          <Text style={styles.changeEmailText}>Đăng ký lại với email khác</Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  scroll: {
    padding: 20,
    alignItems: 'center',
  },
  centerBox: {
    alignItems: 'center',
    marginVertical: 20,
  },
  iconCircle: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#FFF1F0',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#FFA39E',
    marginBottom: 16,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 8,
  },
  desc: {
    fontSize: 14,
    color: COLORS.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 16,
  },
  emailText: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.primary,
    marginTop: 4,
  },
  card: {
    width: '100%',
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: COLORS.border,
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
    alignItems: 'center',
  },
  verifyBtn: {
    width: '100%',
    marginTop: 20,
  },
  changeEmailBtn: {
    marginTop: 24,
    padding: 10,
  },
  changeEmailText: {
    fontSize: 14,
    color: COLORS.primary,
    fontWeight: '600',
  },
});
