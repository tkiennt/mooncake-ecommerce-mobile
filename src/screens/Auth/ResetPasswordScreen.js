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

export default function ResetPasswordScreen({ route, navigation }) {
  const email = route?.params?.email || '';
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleResetPassword = async () => {
    if (!code.trim() || code.trim().length !== 6) {
      Alert.alert('Mã không hợp lệ', 'Vui lòng nhập đủ 6 chữ số mã xác thực OTP.');
      return;
    }
    if (!newPassword || newPassword.length < 8) {
      Alert.alert('Mật khẩu yếu', 'Mật khẩu mới phải có tối thiểu 8 ký tự.');
      return;
    }
    if (newPassword !== confirmPassword) {
      Alert.alert('Không khớp', 'Mật khẩu xác nhận không khớp với mật khẩu mới.');
      return;
    }

    setLoading(true);
    try {
      await authService.resetPassword({
        email,
        code: code.trim(),
        newPassword,
      });

      Alert.alert(
        'Đổi mật khẩu thành công',
        'Mật khẩu của bạn đã được cập nhật thành công. Vui lòng đăng nhập bằng mật khẩu mới.',
        [
          {
            text: 'Đăng nhập ngay',
            onPress: () => navigation.navigate('Login'),
          },
        ]
      );
    } catch (e) {
      Alert.alert('Không thành công', e?.response?.data?.message || 'Mã xác thực không đúng hoặc đã hết hạn.');
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
        title="Đặt lại mật khẩu"
        subtitle={email}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <View style={styles.card}>
          <Text style={styles.cardHeading}>Thiết lập mật khẩu mới</Text>
          <Text style={styles.cardDesc}>
            Nhập mã OTP 6 số đã được gửi tới hòm thư của bạn và tạo mật khẩu mới.
          </Text>

          {/* OTP Code */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Mã xác thực OTP (6 chữ số) *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="key-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="123456"
                value={code}
                onChangeText={setCode}
                keyboardType="numeric"
                maxLength={6}
              />
            </View>
          </View>

          {/* New Password */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Mật khẩu mới (tối thiểu 8 ký tự) *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="lock-closed-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Nhập mật khẩu mới"
                value={newPassword}
                onChangeText={setNewPassword}
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

          {/* Confirm New Password */}
          <View style={styles.inputGroup}>
            <Text style={styles.label}>Xác nhận mật khẩu mới *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="shield-checkmark-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Nhập lại mật khẩu mới"
                value={confirmPassword}
                onChangeText={setConfirmPassword}
                secureTextEntry={!showPassword}
              />
            </View>
          </View>

          <CustomButton
            title="Đổi mật khẩu"
            icon="checkmark-circle-outline"
            onPress={handleResetPassword}
            loading={loading}
            size="large"
            style={styles.submitBtn}
          />
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
    alignItems: 'center',
  },
  card: {
    width: '100%',
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 20,
    marginTop: 10,
    borderWidth: 1,
    borderColor: COLORS.border,
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  cardHeading: {
    fontSize: 18,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 4,
  },
  cardDesc: {
    fontSize: 13,
    color: COLORS.textSecondary,
    marginBottom: 16,
    lineHeight: 18,
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
  submitBtn: {
    marginTop: 10,
  },
});
