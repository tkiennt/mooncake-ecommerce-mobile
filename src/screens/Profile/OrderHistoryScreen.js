import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  Image,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  StatusBar,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { MOCK_PRODUCTS } from '../../api/apiClient';
import { orderService } from '../../services/api/orderService';
import { toMobileOrder } from '../../api/mappers';
import { imageSource } from '../../utils/imageSource';

const formatVND = (value = 0) => `${Math.round(value).toLocaleString('vi-VN')} ₫`;
const productById = (id) => MOCK_PRODUCTS.find((p) => p.id === id) || MOCK_PRODUCTS[0];

// Demo orders, shown immediately so the screen never waits on an unreachable backend.
const MOCK_ORDERS = [
  {
    id: 'ord-8899',
    orderNumber: 'ORD-2026-8899',
    shopName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
    trusted: true,
    status: 'Pending',
    productId: 'prod-001',
    variantName: 'Thập cẩm gà quay vi cá',
    quantity: 50,
    listPrice: 650000,
    unitPrice: 617500,
    note: 'Xưởng sẽ xác nhận trước 14:20 ngày 31/10',
  },
  {
    id: 'ord-8872',
    orderNumber: 'ORD-2026-8872',
    shopName: 'Tiệm Bánh Thủ Công An Lạc',
    status: 'Processing',
    productId: 'prod-002',
    variantName: 'Hạt sen trà xanh matcha',
    quantity: 100,
    listPrice: 880000,
    unitPrice: 774400,
    note: 'Đang sản xuất · dự kiến giao 05/11',
  },
  {
    id: 'ord-8840',
    orderNumber: 'ORD-2026-8840',
    shopName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
    trusted: true,
    status: 'Shipping',
    productId: 'prod-004',
    variantName: 'Hạt sen hạt điều',
    quantity: 40,
    listPrice: 360000,
    unitPrice: 338400,
    note: 'Xe lạnh đang trên đường giao · 20.5°C',
  },
  {
    id: 'ord-8711',
    orderNumber: 'ORD-2026-8711',
    shopName: 'Bảo Ngọc Đường',
    status: 'Delivered',
    productId: 'prod-003',
    variantName: 'Dừa non sữa tươi',
    quantity: 30,
    listPrice: 420000,
    unitPrice: 378000,
    note: 'Giao hàng thành công vào 22 Thg 10',
  },
];

const STATUS = {
  Pending: { label: 'Chờ xác nhận', strip: 'warning' },
  Processing: { label: 'Đang sản xuất', strip: 'neutral' },
  Shipping: { label: 'Đang giao', strip: 'neutral' },
  Delivered: { label: 'Đã giao', strip: 'success' },
  Cancelled: { label: 'Đã hủy', strip: 'neutral' },
};

const TABS = [
  { key: 'ALL', label: 'Tất cả' },
  { key: 'Pending', label: 'Chờ xác nhận' },
  { key: 'Processing', label: 'Đang sản xuất' },
  { key: 'Shipping', label: 'Đang giao' },
  { key: 'Delivered', label: 'Đã giao' },
  { key: 'Cancelled', label: 'Đã hủy' },
];

export default function OrderHistoryScreen({ navigation }) {
  const insets = useSafeAreaInsets();
  const [orders, setOrders] = useState(MOCK_ORDERS);
  const [activeTab, setActiveTab] = useState('ALL');
  const [refreshing, setRefreshing] = useState(false);

  const fetchOrders = async () => {
    try {
      const list = await orderService.listMine();
      setOrders((Array.isArray(list) ? list : list?.items || []).map(toMobileOrder));
    } catch (error) {
      // Keep the demo orders only when the backend is not reachable.
      if (error?.response) setOrders([]);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await fetchOrders();
    setRefreshing(false);
  };

  const visible = activeTab === 'ALL' ? orders : orders.filter((o) => o.status === activeTab);

  const actionsFor = (order) => {
    const track = { label: 'Theo dõi đơn', onPress: () => navigation.navigate('DeliveryPoD', { orderId: order.id, orderNumber: order.orderNumber }) };
    switch (order.status) {
      case 'Pending':
        return [{ label: 'Liên hệ xưởng', onPress: () => navigation.navigate('AiAssistant') }, { ...track, label: 'Xem chi tiết', primary: true }];
      case 'Processing':
        return [{ label: 'Xem hợp đồng', onPress: () => navigation.navigate('Contracts') }, { ...track, primary: true }];
      case 'Shipping':
        return [{ ...track, label: 'Theo dõi xe lạnh', primary: true }];
      case 'Delivered':
        return [
          { label: 'Mua lại', onPress: () => navigation.navigate('ProductDetail', { product: productById(order.productId) }) },
          { label: 'Đánh giá', primary: true, onPress: () => navigation.navigate('ReviewForm', { orderNumber: order.orderNumber, shopName: order.shopName }) },
        ];
      default:
        return [{ label: 'Mua lại', onPress: () => navigation.navigate('ProductDetail', { product: productById(order.productId) }) }];
    }
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor={COLORS.surface} />

      <View style={[styles.header, { paddingTop: insets.top + 8 }]}>
        <Text style={styles.headerTitle}>Đơn đã mua</Text>
        <TouchableOpacity style={styles.headerIcon} onPress={() => navigation.navigate('Search')} accessibilityLabel="Tìm kiếm">
          <Ionicons name="search-outline" size={22} color={COLORS.primary} />
        </TouchableOpacity>
        <TouchableOpacity style={styles.headerIcon} onPress={() => navigation.navigate('AiAssistant')} accessibilityLabel="Tư vấn">
          <Ionicons name="chatbubbles-outline" size={22} color={COLORS.primary} />
        </TouchableOpacity>
      </View>

      <View style={styles.tabsWrap}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.tabs}>
          {TABS.map((tab) => {
            const active = activeTab === tab.key;
            return (
              <TouchableOpacity key={tab.key} style={styles.tab} onPress={() => setActiveTab(tab.key)}>
                <Text style={[styles.tabText, active && styles.tabTextActive]}>{tab.label}</Text>
                <View style={[styles.tabLine, active && styles.tabLineActive]} />
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      <ScrollView
        contentContainerStyle={styles.list}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={COLORS.primary} />}
      >
        {visible.length === 0 ? (
          <View style={styles.empty}>
            <Ionicons name="receipt-outline" size={44} color={COLORS.textMuted} />
            <Text style={styles.emptyTitle}>Chưa có đơn nào</Text>
            <Text style={styles.emptySub}>Đơn hàng ở trạng thái này sẽ hiện tại đây.</Text>
            <TouchableOpacity style={styles.emptyButton} onPress={() => navigation.navigate('HomeTab')}>
              <Text style={styles.emptyButtonText}>Khám phá sản phẩm</Text>
            </TouchableOpacity>
          </View>
        ) : (
          visible.map((order) => {
            const demoProduct = order.isFromApi ? null : productById(order.productId);
            const product = {
              name: order.productName || demoProduct?.name || 'Sản phẩm',
              coverImage: order.productImage || demoProduct?.coverImage || null,
            };
            const status = STATUS[order.status] || { label: order.status, strip: 'neutral' };
            const total = order.totalAmount || order.unitPrice * order.quantity;
            return (
              <View key={order.id} style={styles.card}>
                <View style={styles.shopRow}>
                  {order.trusted ? (
                    <View style={styles.trustTag}><Text style={styles.trustTagText}>Uy tín</Text></View>
                  ) : (
                    <Ionicons name="storefront-outline" size={16} color={COLORS.textSecondary} />
                  )}
                  <Text style={styles.shopName} numberOfLines={1}>{order.shopName}</Text>
                  <Text style={styles.status}>{status.label}</Text>
                </View>

                <TouchableOpacity
                  style={styles.itemRow}
                  activeOpacity={0.8}
                  onPress={() => navigation.navigate('DeliveryPoD', { orderId: order.id, orderNumber: order.orderNumber })}
                >
                  {product.coverImage
                    ? <Image source={imageSource(product.coverImage)} style={styles.thumb} resizeMode="cover" />
                    : <View style={[styles.thumb, styles.thumbEmpty]}><Ionicons name="cube-outline" size={26} color={COLORS.textMuted} /></View>}
                  <View style={styles.itemBody}>
                    <Text style={styles.itemName} numberOfLines={1}>{product.name}</Text>
                    <View style={styles.variantRow}>
                      <Text style={styles.variant} numberOfLines={1}>{order.variantName}</Text>
                      <Text style={styles.qty}>x{order.quantity}</Text>
                    </View>
                    <View style={styles.priceRow}>
                      {order.listPrice > order.unitPrice && <Text style={styles.listPrice}>{formatVND(order.listPrice)}</Text>}
                      <Text style={styles.unitPrice}>{formatVND(order.unitPrice)}</Text>
                    </View>
                  </View>
                </TouchableOpacity>

                <Text style={styles.total}>
                  Tổng số tiền ({order.quantity} hộp): <Text style={styles.totalValue}>{formatVND(total)}</Text>
                </Text>

                {order.note ? (
                  <TouchableOpacity
                    style={[styles.strip, styles[`strip_${status.strip}`]]}
                    onPress={() => navigation.navigate('DeliveryPoD', { orderId: order.id, orderNumber: order.orderNumber })}
                  >
                    <Text style={[styles.stripText, styles[`stripText_${status.strip}`]]} numberOfLines={1}>{order.note}</Text>
                    <Ionicons name="chevron-forward" size={16} color={COLORS.textMuted} />
                  </TouchableOpacity>
                ) : null}

                <View style={styles.actions}>
                  {actionsFor(order).map((action) => (
                    <TouchableOpacity
                      key={action.label}
                      style={[styles.action, action.primary && styles.actionPrimary]}
                      onPress={action.onPress}
                    >
                      <Text style={[styles.actionText, action.primary && styles.actionTextPrimary]}>{action.label}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            );
          })
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4F1EC',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingBottom: 8,
    backgroundColor: COLORS.surface,
  },
  headerTitle: {
    flex: 1,
    color: COLORS.textPrimary,
    fontSize: 20,
    fontWeight: '600',
  },
  headerIcon: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabsWrap: {
    backgroundColor: COLORS.surface,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: COLORS.border,
  },
  tabs: {
    paddingHorizontal: 8,
  },
  tab: {
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingTop: 10,
  },
  tabText: {
    color: COLORS.textPrimary,
    fontSize: 14,
  },
  tabTextActive: {
    color: COLORS.primary,
    fontWeight: '600',
  },
  tabLine: {
    alignSelf: 'stretch',
    height: 3,
    marginTop: 9,
    borderRadius: 2,
    backgroundColor: 'transparent',
  },
  tabLineActive: {
    backgroundColor: COLORS.primary,
  },
  list: {
    padding: 10,
    gap: 10,
  },
  card: {
    padding: 14,
    gap: 12,
    borderRadius: 10,
    backgroundColor: COLORS.surface,
  },
  shopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  trustTag: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 999,
    backgroundColor: '#FBEEEE',
  },
  trustTagText: {
    color: COLORS.primary,
    fontSize: 11,
    fontWeight: '500',
  },
  shopName: {
    flex: 1,
    color: COLORS.textPrimary,
    fontSize: 14,
    fontWeight: '600',
  },
  status: {
    color: COLORS.primary,
    fontSize: 13,
  },
  itemRow: {
    flexDirection: 'row',
    gap: 12,
  },
  thumb: {
    width: 76,
    height: 76,
    borderRadius: 6,
    backgroundColor: COLORS.surfaceHover,
  },
  thumbEmpty: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  itemBody: {
    flex: 1,
    minWidth: 0,
    justifyContent: 'space-between',
  },
  itemName: {
    color: COLORS.textPrimary,
    fontSize: 14,
  },
  variantRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
  },
  variant: {
    flex: 1,
    color: COLORS.textMuted,
    fontSize: 12,
  },
  qty: {
    color: COLORS.textSecondary,
    fontSize: 12,
  },
  priceRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'flex-end',
    gap: 6,
  },
  listPrice: {
    color: COLORS.textMuted,
    fontSize: 12,
    textDecorationLine: 'line-through',
  },
  unitPrice: {
    color: COLORS.textPrimary,
    fontSize: 14,
  },
  total: {
    color: COLORS.textPrimary,
    fontSize: 13,
    textAlign: 'right',
  },
  totalValue: {
    fontSize: 15,
    fontWeight: '600',
  },
  strip: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
  },
  strip_success: { backgroundColor: '#EEF7F1' },
  strip_warning: { backgroundColor: '#FDF5E8' },
  strip_neutral: { backgroundColor: '#F6F3EF' },
  stripText: {
    flex: 1,
    fontSize: 13,
  },
  stripText_success: { color: '#2F7A4A' },
  stripText_warning: { color: '#9A5B0B' },
  stripText_neutral: { color: COLORS.textSecondary },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 10,
  },
  action: {
    minWidth: 96,
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: COLORS.borderDark,
  },
  actionPrimary: {
    borderColor: COLORS.primary,
  },
  actionText: {
    color: COLORS.textPrimary,
    fontSize: 13,
  },
  actionTextPrimary: {
    color: COLORS.primary,
    fontWeight: '500',
  },
  empty: {
    alignItems: 'center',
    gap: 8,
    paddingVertical: 60,
  },
  emptyTitle: {
    color: COLORS.textPrimary,
    fontSize: 15,
    fontWeight: '500',
  },
  emptySub: {
    color: COLORS.textSecondary,
    fontSize: 13,
  },
  emptyButton: {
    marginTop: 8,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: COLORS.primary,
  },
  emptyButtonText: {
    color: COLORS.primary,
    fontSize: 13,
  },
});
