import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import { apiClient } from '../../api/apiClient';
import { ENDPOINTS } from '../../api/endpoints';

const MOCK_ORDERS = [
  {
    id: 'ord-8899',
    orderNumber: 'ORD-2026-8899',
    createdAt: '30/10/2026 14:20',
    shopName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
    totalItems: 50,
    totalAmount: 29250000,
    status: 'Pending',
    statusLabel: 'Chờ xưởng xác nhận',
    statusColor: '#D46B08',
    itemSummary: '50x Hộp Hoàng Triều Thượng Hạng [Thập Cẩm Gà Quay Vi Cá]',
  },
  {
    id: 'ord-8872',
    orderNumber: 'ORD-2026-8872',
    createdAt: '25/10/2026 09:15',
    shopName: 'Tiệm Bánh Thủ Công An Lạc',
    totalItems: 100,
    totalAmount: 77440000,
    status: 'Processing',
    statusLabel: 'Đang sản xuất bánh',
    statusColor: '#0958D9',
    itemSummary: '100x Hộp Nguyệt Dạ Thưởng Hoa [Hạt Sen Trà Xanh]',
  },
  {
    id: 'ord-8711',
    orderNumber: 'ORD-2026-8711',
    createdAt: '18/10/2026 16:40',
    shopName: 'Bảo Ngọc Đường',
    totalItems: 30,
    totalAmount: 11340000,
    status: 'Delivered',
    statusLabel: 'Đã giao thành công (PoD)',
    statusColor: '#389E0D',
    itemSummary: '30x Bánh Dẻo Tuyết Ngọc Ngân Hà [Dừa Non]',
  },
];

export default function OrderHistoryScreen({ navigation }) {
  const [orders, setOrders] = useState(MOCK_ORDERS);
  const [activeTab, setActiveTab] = useState('ALL');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const res = await apiClient.get(ENDPOINTS.MY_ORDERS);
      if (res?.data && res.data.length > 0) {
        setOrders(res.data);
      }
    } catch (e) {
      // Dùng mock fallback
    } finally {
      setLoading(false);
    }
  };

  const formatVND = (num) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(num);
  };

  const tabs = [
    { key: 'ALL', label: 'Tất cả' },
    { key: 'Pending', label: 'Chờ duyệt' },
    { key: 'Processing', label: 'Đang làm' },
    { key: 'Delivered', label: 'Đã giao' },
  ];

  const filteredOrders = activeTab === 'ALL'
    ? orders
    : orders.filter((o) => o.status === activeTab);

  return (
    <View style={styles.container}>
      <AppHeader
        title="Lịch Sử Đơn Hàng B2B"
        subtitle="Quản lý tiến độ đơn quà tặng doanh nghiệp"
      />

      {/* Tabs */}
      <View style={styles.tabBar}>
        {tabs.map((tab) => (
          <TouchableOpacity
            key={tab.key}
            style={[styles.tabItem, activeTab === tab.key && styles.tabItemActive]}
            onPress={() => setActiveTab(tab.key)}
          >
            <Text
              style={[styles.tabText, activeTab === tab.key && styles.tabTextActive]}
            >
              {tab.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      <ScrollView contentContainerStyle={styles.scroll}>
        {loading ? (
          <ActivityIndicator color={COLORS.primary} size="large" style={{ marginTop: 40 }} />
        ) : filteredOrders.length > 0 ? (
          filteredOrders.map((ord) => (
            <View key={ord.id} style={styles.orderCard}>
              <View style={styles.cardHeader}>
                <View>
                  <Text style={styles.ordNumber}>{ord.orderNumber}</Text>
                  <Text style={styles.ordDate}>{ord.createdAt}</Text>
                </View>
                <View
                  style={[
                    styles.statusTag,
                    { backgroundColor: `${ord.statusColor || COLORS.primary}15` },
                  ]}
                >
                  <Text
                    style={[
                      styles.statusText,
                      { color: ord.statusColor || COLORS.primary },
                    ]}
                  >
                    {ord.statusLabel}
                  </Text>
                </View>
              </View>

              <View style={styles.divider} />

              <View style={styles.shopRow}>
                <Ionicons name="storefront-outline" size={14} color={COLORS.accent} />
                <Text style={styles.shopName}>{ord.shopName}</Text>
              </View>
              <Text style={styles.itemSummary}>{ord.itemSummary}</Text>

              <View style={styles.cardFooter}>
                <View>
                  <Text style={styles.footSub}>Tổng giá trị đơn ({ord.totalItems} hộp):</Text>
                  <Text style={styles.footAmount}>{formatVND(ord.totalAmount)}</Text>
                </View>
                <TouchableOpacity style={styles.detailBtn}>
                  <Text style={styles.detailBtnText}>Chi tiết</Text>
                  <Ionicons name="chevron-forward" size={14} color={COLORS.primary} />
                </TouchableOpacity>
              </View>
            </View>
          ))
        ) : (
          <View style={styles.emptyBox}>
            <Ionicons name="receipt-outline" size={48} color={COLORS.textMuted} />
            <Text style={styles.emptyTitle}>Chưa có đơn hàng nào</Text>
            <Text style={styles.emptySub}>
              Các đơn hàng đặt bánh số lượng lớn của bạn sẽ xuất hiện tại đây.
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  tabBar: {
    flexDirection: 'row',
    backgroundColor: '#FFF',
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  tabItem: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  tabItemActive: {
    borderBottomColor: COLORS.primary,
  },
  tabText: {
    fontSize: 13,
    color: COLORS.textSecondary,
    fontWeight: '500',
  },
  tabTextActive: {
    color: COLORS.primary,
    fontWeight: '700',
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
  },
  orderCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 14,
    marginBottom: 14,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  ordNumber: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.textPrimary,
  },
  ordDate: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  statusTag: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  statusText: {
    fontSize: 11,
    fontWeight: '700',
  },
  divider: {
    height: 1,
    backgroundColor: COLORS.border,
    marginVertical: 10,
  },
  shopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  shopName: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.accent,
    marginLeft: 6,
  },
  itemSummary: {
    fontSize: 13,
    color: COLORS.textPrimary,
    lineHeight: 18,
    marginBottom: 10,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    backgroundColor: '#FAFAF8',
    padding: 10,
    borderRadius: 8,
  },
  footSub: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  footAmount: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primary,
    marginTop: 2,
  },
  detailBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
    paddingHorizontal: 8,
  },
  detailBtnText: {
    fontSize: 12,
    color: COLORS.primary,
    fontWeight: '700',
    marginRight: 2,
  },
  emptyBox: {
    alignItems: 'center',
    marginTop: 60,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: 12,
  },
  emptySub: {
    fontSize: 13,
    color: COLORS.textMuted,
    textAlign: 'center',
    marginTop: 6,
    paddingHorizontal: 30,
  },
});
