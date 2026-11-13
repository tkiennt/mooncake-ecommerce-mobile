import React, { useCallback, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Linking,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import { useAuth } from '../../context/AuthContext';
import { useFocusEffect } from '@react-navigation/native';
import { profileService } from '../../services/api/profileService';
import { orderService } from '../../services/api/orderService';
import { rfqService } from '../../services/rfqService';

export default function ProfileScreen({ navigation }) {
  const { user: sessionUser, logout } = useAuth();
  const [profile, setProfile] = useState(null);
  const [stats, setStats] = useState({ orders: '–', rfqs: '–', boxes: '–' });
  const user = { ...sessionUser, ...profile };

  // GET /users/me plus counts from the customer's own orders and RFQs.
  useFocusEffect(useCallback(() => {
    let alive = true;
    profileService.getMine().then((p) => alive && p && setProfile(p)).catch(() => {});
    Promise.all([orderService.listMine().catch(() => null), rfqService.listMine().catch(() => null)])
      .then(([orders, rfqs]) => {
        if (!alive) return;
        const orderList = Array.isArray(orders) ? orders : orders?.items;
        const boxes = (orderList || []).reduce((sum, o) => sum + (o.items || []).reduce((s2, i) => s2 + (i.quantity || 0), 0), 0);
        setStats({
          orders: orderList ? orderList.length : '–',
          rfqs: Array.isArray(rfqs) ? rfqs.length : '–',
          boxes: orderList ? boxes.toLocaleString('vi-VN') : '–',
        });
      });
    return () => { alive = false; };
  }, []));

  const handleLogout = () => {
    Alert.alert('Đăng xuất', 'Bạn có chắc chắn muốn đăng xuất tài khoản này?', [
      { text: 'Hủy', style: 'cancel' },
      { text: 'Đăng xuất', style: 'destructive', onPress: logout },
    ]);
  };

  const menuItems = [
    {
      icon: 'business-outline',
      title: 'Hồ Sơ Doanh Nghiệp & MST',
      subtitle: user?.taxId ? `MST: ${user.taxId}` : 'Chưa cập nhật',
      onPress: () => Alert.alert('Hồ Sơ', `Công ty: ${user?.companyName}\nMST: ${user?.taxId}`),
    },
    {
      icon: 'document-text-outline',
      title: 'Hợp Đồng Điện Tử (e-Contract)',
      subtitle: 'Quản lý hợp đồng & Ký số bằng OTP',
      onPress: () => navigation.navigate('Contracts'),
    },
    {
      icon: 'briefcase-outline',
      title: 'Yêu Cầu Báo Giá (RFQ) Đang Mở',
      subtitle: 'Theo dõi các gói đấu thầu & Báo giá từ xưởng',
      onPress: () => navigation.navigate('RfqList'),
    },
    {
      icon: 'shield-checkmark-outline',
      title: 'Ký quỹ & thanh toán theo mốc',
      subtitle: 'Tiền cọc giữ trong ký quỹ, giải ngân khi nghiệm thu',
      onPress: () => navigation.navigate('Contracts'),
    },
    {
      icon: 'headset-outline',
      title: 'Hotline hỗ trợ',
      subtitle: '1900 6868 (8:00 – 21:00)',
      onPress: () => Linking.openURL('tel:19006868').catch(() => {}),
    },
  ];

  return (
    <View style={styles.container}>
      <AppHeader title="Tài khoản" />

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* User Card */}
        <View style={styles.userCard}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>
              {user?.fullName ? user.fullName.charAt(0) : 'U'}
            </Text>
          </View>
          <View style={styles.userInfo}>
            <Text style={styles.userName}>{user?.fullName || 'Khách hàng'}</Text>
            <Text style={styles.companyName}>{user?.companyName || 'Chưa cập nhật doanh nghiệp'}</Text>
            <View style={styles.badgeRow}>
              <Text style={styles.phoneText}>{[user?.phoneNumber, user?.email].filter(Boolean).join(' · ')}</Text>
            </View>
          </View>
        </View>

        {/* Stats Row */}
        <View style={styles.statsCard}>
          <TouchableOpacity
            style={styles.statCol}
            onPress={() => navigation.navigate('OrdersTab')}
          >
            <Text style={styles.statVal}>{stats.orders}</Text>
            <Text style={styles.statLabel}>Đơn hàng</Text>
          </TouchableOpacity>
          <View style={styles.statDivider} />
          <TouchableOpacity
            style={styles.statCol}
            onPress={() => navigation.navigate('RfqList')}
          >
            <Text style={styles.statVal}>{stats.rfqs}</Text>
            <Text style={styles.statLabel}>Gói thầu RFQ</Text>
          </TouchableOpacity>
          <View style={styles.statDivider} />
          <View style={styles.statCol}>
            <Text style={styles.statVal}>{stats.boxes}</Text>
            <Text style={styles.statLabel}>Hộp đã đặt</Text>
          </View>
        </View>

        {/* Menu list */}
        <View style={styles.menuCard}>
          {menuItems.map((item, idx) => (
            <TouchableOpacity
              key={idx}
              style={[
                styles.menuItem,
                idx !== menuItems.length - 1 && styles.menuItemBorder,
              ]}
              onPress={item.onPress}
            >
              <View style={styles.menuIconBox}>
                <Ionicons name={item.icon} size={20} color={COLORS.primary} />
              </View>
              <View style={styles.menuTextBox}>
                <Text style={styles.menuTitle}>{item.title}</Text>
                <Text style={styles.menuSub}>{item.subtitle}</Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={COLORS.textMuted} />
            </TouchableOpacity>
          ))}
        </View>

        {/* Logout button */}
        <TouchableOpacity style={styles.logoutBtn} onPress={handleLogout}>
          <Ionicons name="log-out-outline" size={18} color={COLORS.error} />
          <Text style={styles.logoutText}>Đăng Xuất Tài Khoản</Text>
        </TouchableOpacity>

        <Text style={styles.versionText}>Nguyệt Phố B2B Mobile • v1.0.0 (Phase 1 MVP)</Text>
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
  userCard: {
    backgroundColor: COLORS.primaryDark,
    borderRadius: 14,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 14,
    borderWidth: 1,
    borderColor: 'rgba(212, 136, 6, 0.4)',
  },
  avatar: {
    width: 54,
    height: 54,
    borderRadius: 27,
    backgroundColor: COLORS.accent,
    justifyContent: 'center',
    alignItems: 'center',
  },
  avatarText: {
    fontSize: 22,
    fontWeight: '800',
    color: '#FFF',
  },
  userInfo: {
    marginLeft: 14,
    flex: 1,
  },
  userName: {
    fontSize: 16,
    fontWeight: '700',
    color: '#FFF',
  },
  companyName: {
    fontSize: 12,
    color: '#E8E1D5',
    marginTop: 2,
  },
  badgeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
  },
  tierBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.accent,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 12,
  },
  tierText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#FFF',
    marginLeft: 4,
  },
  phoneText: {
    fontSize: 11,
    color: '#C4BDB0',
    marginLeft: 8,
  },
  statsCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    paddingVertical: 12,
    paddingHorizontal: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  statCol: {
    flex: 1,
    alignItems: 'center',
  },
  statVal: {
    fontSize: 18,
    fontWeight: '800',
    color: COLORS.primary,
  },
  statLabel: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  statDivider: {
    width: 1,
    height: 24,
    backgroundColor: COLORS.border,
  },
  menuCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 16,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
  },
  menuItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  menuIconBox: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: 'rgba(140, 21, 36, 0.06)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  menuTextBox: {
    flex: 1,
    marginLeft: 12,
  },
  menuTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  menuSub: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  logoutBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: '#FFA39E',
    borderRadius: 10,
    paddingVertical: 12,
    marginBottom: 20,
  },
  logoutText: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.error,
    marginLeft: 8,
  },
  versionText: {
    fontSize: 11,
    color: COLORS.textMuted,
    textAlign: 'center',
  },
});

