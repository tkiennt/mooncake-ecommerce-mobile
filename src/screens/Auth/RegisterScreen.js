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
import CustomButton from '../../components/common/CustomButton';
import { authService } from '../../services/api/authService';

export default function RegisterScreen({ navigation }) {
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [agreed, setAgreed] = useState(true);
  const [loading, setLoading] = useState(false);

  const handleRegister = async () => {
    if (!fullName.trim() || !phone.trim() || !email.trim() || !password) {
      Alert.alert('Thiếu thông tin', 'Vui lòng điền đầy đủ các thông tin bắt buộc.');
      return;
    }
    if (password.length < 8) {
      Alert.alert('Mật khẩu yếu', 'Mật khẩu phải có tối thiểu 8 ký tự.');
      return;
    }
    if (password !== confirmPassword) {
      Alert.alert('Không khớp', 'Mật khẩu xác nhận không khớp với mật khẩu đã nhập.');
      return;
    }
    if (!agreed) {
      Alert.alert('Điều khoản', 'Vui lòng đồng ý với điều khoản sử dụng sàn thương mại Nguyệt Phố.');
      return;
    }

    setLoading(true);
    try {
      await authService.register({
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email.trim(),
        password,
      });

      Alert.alert(
        'Đăng ký thành công',
        `Mã OTP kích hoạt tài khoản đã được gửi tới email ${email.trim()}. Vui lòng kiểm tra hộp thư để xác nhận.`,
        [
          {
            text: 'Nhập mã OTP',
            onPress: () => navigation.navigate('VerifyEmail', { email: email.trim() }),
          },
        ]
      );
    } catch (e) {
      Alert.alert('Đăng ký không thành công', e?.response?.data?.message || e.message || 'Số điện thoại hoặc email đã được sử dụng.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Header Branding */}
        <View style={styles.headerArea}>
          <View style={styles.logoBadge}>
            <Ionicons name="moon" size={32} color={COLORS.accent} />
          </View>
          <Text style={styles.brandTitle}>Nguyệt Phố</Text>
          <Text style={styles.brandSubtitle}>
            Tài khoản mua sắm & đặt bánh Trung thu số lượng lớn
          </Text>
        </View>

        {/* Register Card */}
        <View style={styles.formCard}>
          <Text style={styles.cardHeading}>Tạo tài khoản mới</Text>
          <Text style={styles.cardDesc}>
            Đặt bánh trực tiếp từ xưởng nghệ nhân với chiết khấu cao
          </Text>

          {/* Full Name */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Họ và tên / Đại diện mua sắm *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="person-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Nguyễn Văn An"
                value={fullName}
                onChangeText={setFullName}
                autoCapitalize="words"
              />
            </View>
          </View>

          {/* Phone */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Số điện thoại *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="call-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="0912 345 678"
                value={phone}
                onChangeText={setPhone}
                keyboardType="phone-pad"
                autoCapitalize="none"
              />
            </View>
          </View>

          {/* Email */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Địa chỉ Email *</Text>
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

          {/* Password */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Mật khẩu (tối thiểu 8 ký tự) *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="lock-closed-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Nhập mật khẩu"
                value={password}
                onChangeText={setPassword}
                secureTextEntry={!showPassword}
              />
              <TouchableOpacity onPress={() => setShowPassword(!showPassword)}>
                <Ionicons
                  name={showPassword ? 'eye-off-outline' : 'eye-outline'}
                  size={18}
                  color={COLORS.textMuted}
                />
              </TouchableOpacity>
            </View>
          </View>

          {/* Confirm Password */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Xác nhận mật khẩu *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="shield-checkmark-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Nhập lại mật khẩu"
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                secureTextEntry={!showPassword}
              />
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
              size={20}
              color={COLORS.primary}
            />
            <Text style={styles.checkboxLabel}>
              Tôi đồng ý với Quy chế hoạt động và Điều khoản bảo mật của Sàn Nguyệt Phố.
            </Text>
          </TouchableOpacity>

          <CustomButton
            title="Đăng ký tài khoản"
            onPress={handleRegister}
            loading={loading}
            size="large"
            style={styles.submitBtn}
          />
        </View>

        {/* Footer Link to Login */}
        <View style={styles.footerPrompt}>
          <Text style={styles.footerText}>Đã có tài khoản? </Text>
          <TouchableOpacity onPress={() => navigation.navigate('Login')}>
            <Text style={styles.footerLink}>Đăng nhập ngay</Text>
          </TouchableOpacity>
        </View>
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
    paddingTop: 40,
    paddingBottom: 40,
  },
  headerArea: {
    alignItems: 'center',
    marginBottom: 20,
  },
  logoBadge: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: COLORS.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: COLORS.accent,
    marginBottom: 10,
  },
  brandTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: COLORS.primary,
    letterSpacing: 0.5,
  },
  brandSubtitle: {
    fontSize: 13,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: 4,
  },
  formCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 20,
    borderWidth: 1,
    borderColor: COLORS.border,
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.06,
    shadowRadius: 10,
    elevation: 3,
  },
  cardHeading: {
    fontSize: 20,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 4,
  },
  cardDesc: {
    fontSize: 13,
    color: COLORS.textSecondary,
    marginBottom: 16,
  },
  inputGroup: {
    marginBottom: 14,
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
  checkboxRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 8,
    marginVertical: 12,
  },
  checkboxLabel: {
    flex: 1,
    fontSize: 12,
    color: COLORS.textSecondary,
    lineHeight: 18,
  },
  submitBtn: {
    marginTop: 6,
  },
  footerPrompt: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 20,
  },
  footerText: {
    fontSize: 14,
    color: COLORS.textSecondary,
  },
  footerLink: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.primary,
  },
});
