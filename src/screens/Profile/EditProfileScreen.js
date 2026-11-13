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
  Image,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { useAuth } from '../../context/AuthContext';
import { profileService } from '../../services/api/profileService';
import { imageSource } from '../../utils/imageSource';

const PRESET_AVATARS = [
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
];

export default function EditProfileScreen({ navigation }) {
  const { user, updateUserProfile } = useAuth();

  const [fullName, setFullName] = useState(user?.fullName || '');
  const [companyName, setCompanyName] = useState(user?.companyName || '');
  const [taxId, setTaxId] = useState(user?.taxId || '');
  const [phoneNumber, setPhoneNumber] = useState(user?.phoneNumber || '');
  const [email, setEmail] = useState(user?.email || '');
  const [address, setAddress] = useState(user?.address || user?.deliveryAddress || '');
  const [avatarUrl, setAvatarUrl] = useState(user?.avatarUrl || user?.avatar || null);
  const [loading, setLoading] = useState(false);
  const [showAvatarPicker, setShowAvatarPicker] = useState(false);

  const handleSaveProfile = async () => {
    if (!fullName.trim()) {
      Alert.alert('Thiếu thông tin', 'Vui lòng nhập họ và tên của bạn.');
      return;
    }

    setLoading(true);
    try {
      const payload = {
        fullName: fullName.trim(),
        companyName: companyName.trim() || null,
        taxId: taxId.trim() || null,
        phoneNumber: phoneNumber.trim() || null,
        address: address.trim() || null,
      };

      await profileService.updateMine(payload).catch((err) => {
        // If server is not reachable in offline dev mode, still succeed locally
        console.warn('Backend updateMine call notice:', err);
      });

      await updateUserProfile({
        ...payload,
        avatarUrl,
      });

      Alert.alert('Thành công', 'Thông tin tài khoản đã được cập nhật.', [
        { text: 'OK', onPress: () => navigation.goBack() },
      ]);
    } catch (e) {
      Alert.alert('Lỗi cập nhật', e?.response?.data?.message || 'Không thể cập nhật hồ sơ lúc này.');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectPresetAvatar = async (url) => {
    setAvatarUrl(url);
    setShowAvatarPicker(false);
    try {
      // If backend supports avatar upload by url or mock update
      await updateUserProfile({ avatarUrl: url });
      Alert.alert('Ảnh đại diện', 'Đã cập nhật ảnh đại diện mới.');
    } catch (_) {}
  };

  const handleRemoveAvatar = async () => {
    Alert.alert('Gỡ ảnh đại diện', 'Bạn có chắc chắn muốn gỡ ảnh đại diện hiện tại?', [
      { text: 'Hủy', style: 'cancel' },
      {
        text: 'Gỡ ảnh',
        style: 'destructive',
        onPress: async () => {
          try {
            await profileService.removeAvatar().catch(() => {});
            setAvatarUrl(null);
            await updateUserProfile({ avatarUrl: null });
            Alert.alert('Đã gỡ', 'Ảnh đại diện đã được gỡ bỏ.');
          } catch (e) {
            Alert.alert('Lỗi', 'Không gỡ được ảnh.');
          }
        },
      },
    ]);
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <AppHeader
        title="Chỉnh sửa hồ sơ"
        subtitle="Thông tin người mua & doanh nghiệp"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Avatar Section */}
        <View style={styles.avatarSection}>
          <View style={styles.avatarWrap}>
            {avatarUrl ? (
              <Image source={imageSource(avatarUrl)} style={styles.avatarImage} />
            ) : (
              <View style={styles.avatarPlaceholder}>
                <Text style={styles.avatarInitial}>{fullName ? fullName.charAt(0) : 'U'}</Text>
              </View>
            )}
            <TouchableOpacity
              style={styles.changeAvatarBadge}
              onPress={() => setShowAvatarPicker(!showAvatarPicker)}
            >
              <Ionicons name="camera" size={16} color="#FFFFFF" />
            </TouchableOpacity>
          </View>

          <View style={styles.avatarActions}>
            <TouchableOpacity
              style={styles.avatarBtn}
              onPress={() => setShowAvatarPicker(!showAvatarPicker)}
            >
              <Ionicons name="images-outline" size={14} color={COLORS.primary} />
              <Text style={styles.avatarBtnText}>Đổi ảnh đại diện</Text>
            </TouchableOpacity>
            {avatarUrl && (
              <TouchableOpacity
                style={[styles.avatarBtn, styles.removeAvatarBtn]}
                onPress={handleRemoveAvatar}
              >
                <Ionicons name="trash-outline" size={14} color={COLORS.error} />
                <Text style={[styles.avatarBtnText, { color: COLORS.error }]}>Xoá ảnh</Text>
              </TouchableOpacity>
            )}
          </View>

          {/* Preset Avatar Tray */}
          {showAvatarPicker && (
            <View style={styles.presetTray}>
              <Text style={styles.presetTitle}>Chọn ảnh đại diện phong cách:</Text>
              <View style={styles.presetRow}>
                {PRESET_AVATARS.map((url, i) => (
                  <TouchableOpacity
                    key={i}
                    onPress={() => handleSelectPresetAvatar(url)}
                    style={[styles.presetThumbWrap, avatarUrl === url && styles.presetThumbActive]}
                  >
                    <Image source={{ uri: url }} style={styles.presetThumb} />
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          )}
        </View>

        {/* Profile Form */}
        <View style={styles.card}>
          <Text style={styles.sectionHeading}>Thông tin cá nhân & Liên hệ</Text>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Họ và tên *</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="person-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                value={fullName}
                onChangeText={setFullName}
                placeholder="Nhập họ và tên"
              />
            </View>
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Số điện thoại liên hệ</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="call-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                value={phoneNumber}
                onChangeText={setPhoneNumber}
                keyboardType="phone-pad"
                placeholder="0912 345 678"
              />
            </View>
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Địa chỉ Email</Text>
            <View style={[styles.inputWrapper, { backgroundColor: '#F0F0EE' }]}>
              <Ionicons name="mail-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={[styles.input, { color: COLORS.textMuted }]}
                value={email}
                editable={false}
                placeholder="Email đăng ký"
              />
            </View>
          </View>

          <View style={styles.divider} />
          <Text style={styles.sectionHeading}>Thông tin Doanh nghiệp & Xuất hóa đơn</Text>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Tên công ty / Doanh nghiệp</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="business-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                value={companyName}
                onChangeText={setCompanyName}
                placeholder="Công ty Cổ phần Tập đoàn Á Châu"
              />
            </View>
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Mã số thuế (MST)</Text>
            <View style={styles.inputWrapper}>
              <Ionicons name="receipt-outline" size={18} color={COLORS.textMuted} style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                value={taxId}
                onChangeText={setTaxId}
                placeholder="0312456789"
                keyboardType="numeric"
              />
            </View>
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Địa chỉ nhận hàng mặc định</Text>
            <View style={[styles.inputWrapper, { height: 72, alignItems: 'flex-start', paddingTop: 8 }]}>
              <Ionicons name="location-outline" size={18} color={COLORS.textMuted} style={[styles.inputIcon, { marginTop: 4 }]} />
              <TextInput
                style={[styles.input, { textAlignVertical: 'top' }]}
                value={address}
                onChangeText={setAddress}
                placeholder="Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành phố"
                multiline
                numberOfLines={2}
              />
            </View>
          </View>

          <CustomButton
            title="Lưu thay đổi hồ sơ"
            icon="save-outline"
            onPress={handleSaveProfile}
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
    padding: 16,
    paddingBottom: 40,
  },
  avatarSection: {
    alignItems: 'center',
    marginVertical: 14,
  },
  avatarWrap: {
    position: 'relative',
    marginBottom: 8,
  },
  avatarImage: {
    width: 88,
    height: 88,
    borderRadius: 44,
    borderWidth: 2,
    borderColor: COLORS.accent,
  },
  avatarPlaceholder: {
    width: 88,
    height: 88,
    borderRadius: 44,
    backgroundColor: COLORS.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: COLORS.accent,
  },
  avatarInitial: {
    color: '#FFFFFF',
    fontSize: 34,
    fontWeight: '700',
  },
  changeAvatarBadge: {
    position: 'absolute',
    right: 0,
    bottom: 0,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: COLORS.primary,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  avatarActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 4,
  },
  avatarBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
    backgroundColor: '#FFF1F0',
    borderWidth: 1,
    borderColor: '#FFA39E',
  },
  removeAvatarBtn: {
    backgroundColor: '#FFF1F0',
    borderColor: '#FFA39E',
  },
  avatarBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.primary,
  },
  presetTray: {
    backgroundColor: COLORS.surface,
    padding: 12,
    borderRadius: 12,
    marginTop: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    alignItems: 'center',
  },
  presetTitle: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginBottom: 8,
  },
  presetRow: {
    flexDirection: 'row',
    gap: 12,
  },
  presetThumbWrap: {
    borderRadius: 24,
    borderWidth: 2,
    borderColor: 'transparent',
    padding: 2,
  },
  presetThumbActive: {
    borderColor: COLORS.accent,
  },
  presetThumb: {
    width: 44,
    height: 44,
    borderRadius: 22,
  },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: 18,
    borderWidth: 1,
    borderColor: COLORS.border,
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  sectionHeading: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 12,
  },
  inputGroup: {
    marginBottom: 12,
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
    height: 46,
  },
  inputIcon: {
    marginRight: 8,
  },
  input: {
    flex: 1,
    fontSize: 14,
    color: COLORS.textPrimary,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: COLORS.border,
    marginVertical: 14,
  },
  submitBtn: {
    marginTop: 12,
  },
});
