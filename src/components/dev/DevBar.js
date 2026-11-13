import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  Modal,
  SafeAreaView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { navigate } from '../../navigation/navigationRef';
import { useAuth } from '../../context/AuthContext';
import { MOCK_PRODUCTS } from '../../api/apiClient';

export default function DevBar() {
  const [isOpen, setIsOpen] = useState(false);
  const { user, login, logout } = useAuth();

  const handleQuickLogin = async () => {
    await login('0901234567', 'Mooncake@2026');
  };

  const handleQuickLogout = async () => {
    await logout();
  };

  const navGroups = [
    {
      title: '✨ Giao Diện Mới: Ant Design & Lucian Labs',
      items: [
        {
          label: 'UI Showcase · AntD & Lucian Labs',
          screen: 'UiCatalog',
          icon: 'color-palette-outline',
        },
      ],
    },
    {
      title: '🛍️ Mua Sắm & Khám Phá Bánh',
      items: [
        { label: 'Trang Chủ Khám Phá', screen: 'MainTabs', params: { screen: 'HomeTab' }, icon: 'home-outline' },
        { label: 'Tìm Kiếm & Bộ Lọc FTS', screen: 'Search', icon: 'search-outline' },
        {
          label: 'Chi Tiết Bánh & Biến Thể',
          screen: 'ProductDetail',
          params: { product: MOCK_PRODUCTS[0] },
          icon: 'gift-outline',
        },
        { label: 'Giỏ Hàng & Chiết Khấu Sỉ', screen: 'MainTabs', params: { screen: 'CartTab' }, icon: 'cart-outline' },
        { label: 'Xác Nhận Đặt Hàng & VAT', screen: 'Checkout', icon: 'card-outline' },
      ],
    },
    {
      title: '📋 Đấu Thầu & Hợp Đồng B2B',
      items: [
        { label: 'Mở Thầu B2B (Tạo RFQ)', screen: 'CreateRfq', icon: 'add-circle-outline' },
        { label: 'Danh Sách Gói Thầu RFQ', screen: 'RfqList', icon: 'list-outline' },
        {
          label: 'So Sánh Báo Giá Side-by-Side',
          screen: 'RfqDetailBidding',
          params: {
            rfq: {
              id: 'rfq-0042',
              rfqNumber: 'RFQ-2026-0042',
              title: 'Đặt 350 Hộp Quà Hoàng Triều Tri Ân Đối Tác VIP',
              targetQuantity: 350,
              deliveryDate: '10/08/2026',
            },
          },
          icon: 'git-compare-outline',
        },
        { label: 'Hợp Đồng Điện Tử (e-Contract)', screen: 'Contracts', icon: 'document-text-outline' },
        {
          label: 'Ký Số Hợp Đồng & OTP SMS',
          screen: 'ContractSign',
          params: {
            contractNumber: 'HĐ-2026-0812',
            rfq: { title: '350 Hộp Bánh Hoàng Triều Thượng Hạng' },
          },
          icon: 'pencil-outline',
        },
      ],
    },
    {
      title: '🚚 Vận Chuyển, AI & Đánh Giá',
      items: [
        { label: 'Lịch Sử Đơn Hàng B2B', screen: 'MainTabs', params: { screen: 'OrdersTab' }, icon: 'receipt-outline' },
        {
          label: 'Giám Sát Xe Lạnh & Ảnh PoD',
          screen: 'DeliveryPoD',
          params: { orderId: 'ord-8711', orderNumber: 'ORD-2026-8711' },
          icon: 'snow-outline',
        },
        { label: 'Trợ Lý Ảo AI Nguyệt Phố', screen: 'AiAssistant', icon: 'sparkles-outline' },
        {
          label: 'Đánh Giá 4 Tiêu Chí Chất Lượng',
          screen: 'ReviewForm',
          params: { orderNumber: 'ORD-2026-8711', shopName: 'Bảo Ngọc Đường' },
          icon: 'star-outline',
        },
        { label: 'Trung Tâm Thông Báo Realtime', screen: 'Notification', icon: 'notifications-outline' },
        { label: 'Hồ Sơ Doanh Nghiệp & MST', screen: 'MainTabs', params: { screen: 'ProfileTab' }, icon: 'business-outline' },
        { label: 'Màn Hình Đăng Nhập', screen: 'Login', icon: 'log-in-outline' },
      ],
    },
  ];

  const handleNavigate = (item) => {
    setIsOpen(false);
    setTimeout(() => {
      navigate(item.screen, item.params);
    }, 150);
  };

  return (
    <>
      {/* Floating Dev Button */}
      <TouchableOpacity
        style={styles.floatingButton}
        activeOpacity={0.85}
        onPress={() => setIsOpen(true)}
      >
        <Ionicons name="construct" size={18} color="#FFFFFF" />
        <Text style={styles.floatingButtonText}>DEV BAR</Text>
      </TouchableOpacity>

      {/* Dev Menu Modal */}
      <Modal
        visible={isOpen}
        animationType="slide"
        transparent={false}
        onRequestClose={() => setIsOpen(false)}
      >
        <SafeAreaView style={styles.modalContainer}>
          {/* Header */}
          <View style={styles.modalHeader}>
            <View style={styles.headerTitleWrap}>
              <Ionicons name="construct" size={22} color={COLORS.accent} />
              <View>
                <Text style={styles.headerTitle}>NGUYỆT PHỐ DEV BAR</Text>
                <Text style={styles.headerSubtitle}>Kiểm thử giao diện không cần đăng nhập</Text>
              </View>
            </View>
            <TouchableOpacity
              style={styles.closeButton}
              onPress={() => setIsOpen(false)}
            >
              <Ionicons name="close-circle" size={28} color="#FFFFFF" />
            </TouchableOpacity>
          </View>

          {/* User Auth Simulation Bar */}
          <View style={styles.authStatusBar}>
            <View style={styles.authInfo}>
              <View
                style={[
                  styles.statusDot,
                  { backgroundColor: user ? COLORS.success : '#8C8C8C' },
                ]}
              />
              <Text style={styles.authStatusText}>
                {user ? `Đã đăng nhập: ${user.fullName || user.email}` : 'Chế độ: Khách vãng lai (Guest)'}
              </Text>
            </View>
            {user ? (
              <TouchableOpacity
                style={[styles.authBtn, styles.logoutBtn]}
                onPress={handleQuickLogout}
              >
                <Text style={styles.authBtnText}>Đăng xuất</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity
                style={[styles.authBtn, styles.loginBtn]}
                onPress={handleQuickLogin}
              >
                <Text style={styles.authBtnText}>Giả lập B2B Login</Text>
              </TouchableOpacity>
            )}
          </View>

          {/* Navigation Links ScrollView */}
          <ScrollView style={styles.navList} contentContainerStyle={styles.navListContent}>
            {navGroups.map((group, groupIdx) => (
              <View key={groupIdx} style={styles.groupContainer}>
                <Text style={styles.groupTitle}>{group.title}</Text>
                <View style={styles.groupItemsWrap}>
                  {group.items.map((item, itemIdx) => (
                    <TouchableOpacity
                      key={itemIdx}
                      style={styles.navItem}
                      activeOpacity={0.7}
                      onPress={() => handleNavigate(item)}
                    >
                      <View style={styles.navItemLeft}>
                        <View style={styles.navItemIconWrap}>
                          <Ionicons name={item.icon} size={18} color={COLORS.primary} />
                        </View>
                        <Text style={styles.navItemLabel}>{item.label}</Text>
                      </View>
                      <Ionicons name="chevron-forward" size={16} color={COLORS.textMuted} />
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            ))}
            <View style={{ height: 40 }} />
          </ScrollView>
        </SafeAreaView>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  floatingButton: {
    position: 'absolute',
    bottom: 74,
    right: 14,
    backgroundColor: COLORS.primaryDark,
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 7,
    paddingHorizontal: 12,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: COLORS.accent,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.35,
    shadowRadius: 5,
    elevation: 8,
    zIndex: 9999,
    gap: 6,
  },
  floatingButtonText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  modalContainer: {
    flex: 1,
    backgroundColor: '#141414',
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
    backgroundColor: COLORS.primaryDark,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.accent,
  },
  headerTitleWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  headerTitle: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '800',
    letterSpacing: 1,
  },
  headerSubtitle: {
    color: '#E8D2A3',
    fontSize: 11,
  },
  closeButton: {
    padding: 2,
  },
  authStatusBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#1F1F1F',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#2D2D2D',
  },
  authInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  authStatusText: {
    color: '#D4D4D4',
    fontSize: 12,
    flex: 1,
  },
  authBtn: {
    paddingVertical: 5,
    paddingHorizontal: 10,
    borderRadius: 6,
  },
  loginBtn: {
    backgroundColor: COLORS.accent,
  },
  logoutBtn: {
    backgroundColor: '#434343',
  },
  authBtnText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
  },
  navList: {
    flex: 1,
  },
  navListContent: {
    padding: 16,
  },
  groupContainer: {
    marginBottom: 20,
  },
  groupTitle: {
    color: COLORS.accent,
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  groupItemsWrap: {
    backgroundColor: '#1F1F1F',
    borderRadius: 12,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#2D2D2D',
  },
  navItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 14,
    paddingVertical: 13,
    borderBottomWidth: 1,
    borderBottomColor: '#2A2A2A',
  },
  navItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  navItemIconWrap: {
    width: 28,
    height: 28,
    borderRadius: 6,
    backgroundColor: '#FFF1F0',
    alignItems: 'center',
    justifyContent: 'center',
  },
  navItemLabel: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '600',
  },
});
