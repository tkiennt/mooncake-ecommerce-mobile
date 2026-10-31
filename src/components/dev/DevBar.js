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
              id: 'rfq-001',
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
    navigate(item.screen, item.params);
  };

  return (
    <>
      {/* Floating Toggle Button */}
      <TouchableOpacity
        style={styles.floatingButton}
        activeOpacity={0.85}
        onPress={() => setIsOpen(true)}
      >
        <View style={styles.floatingInner}>
          <Ionicons name="construct" size={14} color="#FFF" />
          <Text style={styles.floatingText}>DEV BAR</Text>
          <View style={[styles.statusDot, user ? styles.dotLoggedIn : styles.dotGuest]} />
        </View>
      </TouchableOpacity>

      {/* Full Preview Drawer Modal */}
      <Modal visible={isOpen} animationType="slide" transparent={true}>
        <View style={styles.modalOverlay}>
          <SafeAreaView style={styles.modalContainer}>
            {/* Modal Header */}
            <View style={styles.header}>
              <View style={styles.headerTitleBox}>
                <Ionicons name="compass" size={20} color={COLORS.accent} />
                <Text style={styles.headerTitle}>DEV PREVIEW BAR</Text>
              </View>
              <TouchableOpacity style={styles.closeBtn} onPress={() => setIsOpen(false)}>
                <Ionicons name="close" size={22} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>

            {/* Quick Auth Switcher */}
            <View style={styles.authBanner}>
              <View style={styles.authInfo}>
                <Ionicons
                  name={user ? 'person-circle' : 'person-circle-outline'}
                  size={20}
                  color={user ? COLORS.success : COLORS.textMuted}
                />
                <View style={styles.authTextBox}>
                  <Text style={styles.authStatusText}>
                    {user ? user.fullName : 'Chưa đăng nhập (Khách vãng lai)'}
                  </Text>
                  <Text style={styles.authSubText}>
                    {user ? `Doanh nghiệp: ${user.companyName}` : 'Đang xem chế độ Guest preview'}
                  </Text>
                </View>
              </View>
              {user ? (
                <TouchableOpacity style={styles.authBtnLogout} onPress={handleQuickLogout}>
                  <Text style={styles.authBtnLogoutText}>Thử Guest</Text>
                </TouchableOpacity>
              ) : (
                <TouchableOpacity style={styles.authBtnLogin} onPress={handleQuickLogin}>
                  <Text style={styles.authBtnLoginText}>Đăng nhập B2B</Text>
                </TouchableOpacity>
              )}
            </View>

            <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
              <Text style={styles.guideText}>
                👉 Bấm vào bất kỳ màn hình nào dưới đây để xem trực tiếp giao diện mà không cần đăng nhập:
              </Text>

              {navGroups.map((group, gIdx) => (
                <View key={gIdx} style={styles.groupCard}>
                  <Text style={styles.groupHeading}>{group.title}</Text>
                  {group.items.map((item, iIdx) => (
                    <TouchableOpacity
                      key={iIdx}
                      style={[styles.navItem, iIdx !== group.items.length - 1 && styles.navItemBorder]}
                      onPress={() => handleNavigate(item)}
                    >
                      <View style={styles.itemLeft}>
                        <View style={styles.iconCircle}>
                          <Ionicons name={item.icon} size={16} color={COLORS.primary} />
                        </View>
                        <Text style={styles.itemLabel}>{item.label}</Text>
                      </View>
                      <Ionicons name="chevron-forward" size={16} color={COLORS.textMuted} />
                    </TouchableOpacity>
                  ))}
                </View>
              ))}
            </ScrollView>
          </SafeAreaView>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  floatingButton: {
    position: 'absolute',
    bottom: 74,
    right: 14,
    backgroundColor: '#1F1F1F',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderWidth: 1.5,
    borderColor: COLORS.accent,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.3,
    shadowRadius: 5,
    elevation: 10,
    zIndex: 9999,
  },
  floatingInner: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  floatingText: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: '800',
    letterSpacing: 0.5,
    marginLeft: 6,
    marginRight: 6,
  },
  statusDot: {
    width: 7,
    height: 7,
    borderRadius: 4,
  },
  dotLoggedIn: {
    backgroundColor: '#52C41A',
  },
  dotGuest: {
    backgroundColor: '#FAAD14',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.65)',
    justifyContent: 'flex-end',
  },
  modalContainer: {
    backgroundColor: COLORS.background,
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    maxHeight: '88%',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 18,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
    backgroundColor: '#FFF',
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
  },
  headerTitleBox: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primary,
    marginLeft: 8,
    letterSpacing: 0.5,
  },
  closeBtn: {
    padding: 4,
  },
  authBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFBE6',
    borderBottomWidth: 1,
    borderBottomColor: '#FFE58F',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  authInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
    marginRight: 10,
  },
  authTextBox: {
    marginLeft: 8,
    flex: 1,
  },
  authStatusText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#873800',
  },
  authSubText: {
    fontSize: 10,
    color: '#614700',
  },
  authBtnLogin: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
  },
  authBtnLoginText: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: '700',
  },
  authBtnLogout: {
    backgroundColor: '#FFF',
    borderWidth: 1,
    borderColor: '#FFA39E',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
  },
  authBtnLogoutText: {
    color: COLORS.error,
    fontSize: 11,
    fontWeight: '700',
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 40,
  },
  guideText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginBottom: 12,
    lineHeight: 16,
  },
  groupCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    paddingHorizontal: 14,
    paddingTop: 12,
    paddingBottom: 4,
    marginBottom: 14,
  },
  groupHeading: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primary,
    letterSpacing: 0.3,
    marginBottom: 8,
  },
  navItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 10,
  },
  navItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: '#F5F3EF',
  },
  itemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  iconCircle: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(140, 21, 36, 0.06)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
  },
  itemLabel: {
    fontSize: 13,
    color: COLORS.textPrimary,
    fontWeight: '600',
  },
});
