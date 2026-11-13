import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Switch,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { notificationService } from '../../services/api/notificationService';

export default function NotificationSettingsScreen({ navigation }) {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [preferences, setPreferences] = useState({
    orderUpdates: true,
    rfqBids: true,
    deliveryUpdates: true,
    contractPayments: true,
    promotions: false,
    emailDigest: true,
  });

  useEffect(() => {
    let alive = true;
    notificationService.getPreferences()
      .then((data) => {
        if (alive && data) {
          setPreferences((prev) => ({ ...prev, ...data }));
        }
      })
      .catch((err) => {
        console.warn('Could not load preferences:', err);
      })
      .finally(() => {
        if (alive) setLoading(false);
      });

    return () => { alive = false; };
  }, []);

  const handleToggle = (key) => {
    setPreferences((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await notificationService.updatePreferences(preferences).catch(() => {});
      Alert.alert('Thành công', 'Đã lưu cài đặt thông báo của bạn.', [
        { text: 'OK', onPress: () => navigation.goBack() },
      ]);
    } catch (e) {
      Alert.alert('Lỗi', 'Không lưu được cài đặt lúc này.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.centerBox}>
        <ActivityIndicator size="large" color={COLORS.primary} />
      </View>
    );
  }

  const SETTING_ITEMS = [
    {
      key: 'orderUpdates',
      icon: 'receipt-outline',
      title: 'Trạng thái đơn hàng',
      desc: 'Thông báo khi xưởng xác nhận đơn, bắt đầu làm bánh và đóng gói.',
    },
    {
      key: 'deliveryUpdates',
      icon: 'snow-outline',
      title: 'Vận chuyển xe lạnh (PoD)',
      desc: 'Cập nhật chuyến giao hàng, nhiệt độ thùng lạnh và biên bản ký nhận.',
    },
    {
      key: 'rfqBids',
      icon: 'briefcase-outline',
      title: 'Báo giá & Đấu thầu B2B',
      desc: 'Nhận thông báo ngay khi có xưởng nghệ nhân nộp báo giá cạnh tranh.',
    },
    {
      key: 'contractPayments',
      icon: 'shield-checkmark-outline',
      title: 'Hợp đồng & Thanh toán Escrow',
      desc: 'Nhắc đến hạn thanh toán từng đợt và biên lai đối soát chuyển khoản.',
    },
    {
      key: 'promotions',
      icon: 'gift-outline',
      title: 'Chính sách chiết khấu & Mẫu bánh mới',
      desc: 'Nhận bảng giá ưu đãi theo số lượng và bộ sưu tập mùa Trăng 2026.',
    },
  ];

  return (
    <View style={styles.container}>
      <AppHeader
        title="Cài đặt thông báo"
        subtitle="Quản lý kênh và loại tin nhận"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <View style={styles.card}>
          <Text style={styles.cardHeading}>Thông báo qua ứng dụng (Push Notifications)</Text>
          <Text style={styles.cardDesc}>
            Lựa chọn các loại thông báo quan trọng để theo dõi tiến độ mua hàng thuận tiện.
          </Text>

          {SETTING_ITEMS.map((item, index) => {
            const isEnabled = Boolean(preferences[item.key]);
            return (
              <View key={item.key}>
                <View style={styles.settingRow}>
                  <View style={styles.iconWrap}>
                    <Ionicons name={item.icon} size={20} color={COLORS.primary} />
                  </View>
                  <View style={styles.textBox}>
                    <Text style={styles.itemTitle}>{item.title}</Text>
                    <Text style={styles.itemDesc}>{item.desc}</Text>
                  </View>
                  <Switch
                    value={isEnabled}
                    onValueChange={() => handleToggle(item.key)}
                    trackColor={{ false: '#E0E0E0', true: '#FFA39E' }}
                    thumbColor={isEnabled ? COLORS.primary : '#FFFFFF'}
                  />
                </View>
                {index < SETTING_ITEMS.length - 1 && <View style={styles.divider} />}
              </View>
            );
          })}
        </View>

        <CustomButton
          title="Lưu cấu hình thông báo"
          icon="save-outline"
          onPress={handleSave}
          loading={saving}
          size="large"
          style={styles.saveBtn}
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
  centerBox: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.background,
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
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
    marginBottom: 20,
  },
  cardHeading: {
    fontSize: 16,
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
  settingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
  },
  iconWrap: {
    width: 38,
    height: 38,
    borderRadius: 19,
    backgroundColor: '#FFF1F0',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  textBox: {
    flex: 1,
    marginRight: 8,
  },
  itemTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  itemDesc: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
    lineHeight: 16,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: COLORS.border,
  },
  saveBtn: {
    marginTop: 4,
  },
});
