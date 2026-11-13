import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
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
import { authService } from '../../services/api/authService';

export default function ForgotPasswordScreen({ navigation }) {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSendResetCode = async () => {
    if (!email.trim()) {
      Alert.alert('Thiếu email', 'Vui lòng nhập địa chỉ email đã đăng ký tài khoản.');
      return;
    }

    setLoading(true);
    try {
      await authService.forgotPassword(email.trim());
      Alert.alert(
        'Đã gửi mã khôi phục',
        `Nếu email ${email.trim()} tồn tại trong hệ thống, mã khôi phục 6 số đã được gửi tới hộp thư của bạn.`,
        [
          {
            text: 'Nhập mã đặt lại mật khẩu',
            onPress: () => navigation.navigate('ResetPassword', { email: email.trim() }),
          },
        ]
      );
    } catch (e) {
      Alert.alert('Không thực hiện được', e?.response?.data?.message || 'Có lỗi xảy ra, vui lòng thử lại sau.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <AppHeader
        title="Quên mật khẩu"
        subtitle="Khôi phục tài khoản mua sắm"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <View style={styles.centerBox}>
          <View style={styles.iconCircle}>
            <Ionicons name="key-outline" size={44} color={COLORS.primary} />
          </View>
          <Text style={styles.title}>Lấy lại mật khẩu</Text>
          <Text style={styles.desc}>
            Nhập địa chỉ email liên kết với tài khoản mua hàng của bạn. Chúng tôi sẽ gửi mã OTP đặt lại mật khẩu.
          </Text>
        </View>

        <View style={styles.card}>
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Email tài khoản *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="mail-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="an.nguyen@company.com"
                value={email}
                onChangeText={setEmail}
                keyboardType="email-address"
                autoCapitalize="none"
              />
            </View>
          </View>

          <CustomButton
            title="Gửi mã xác nhận"
            icon="paper-plane-outline"
            onPress={handleSendResetCode}
            loading={loading}
            size="large"
            style={styles.submitBtn}
          />
        </View>

        <TouchableOpacity
          style={styles.backToLoginBtn}
          onPress={() => navigation.navigate('Login')}
        >
          <Text style={styles.backToLoginText}>Quay lại trang Đăng nhập</Text>
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
    paddingHorizontal: 16,
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
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginBottom: 6,
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FAFAF8',
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    height: 48,
  },
  inputIcon: {
    marginRight: 8,
  },
  input: {
    flex: 1,
    fontSize: 14,
    color: COLORS.textPrimary,
  },
  submitBtn: {
    marginTop: 8,
  },
  backToLoginBtn: {
    marginTop: 24,
    padding: 10,
  },
  backToLoginText: {
    fontSize: 14,
    color: COLORS.primary,
    fontWeight: '600',
  },
});
