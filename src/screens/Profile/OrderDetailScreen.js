import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  Image,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  ActivityIndicator,
  Alert,
  Modal,
  TextInput,
  Linking,
  Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { ANTD_TOKENS, LUCIAN_TOKENS } from '../../theme/tokens';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { orderService } from '../../services/api/orderService';
import { paymentService } from '../../services/api/paymentService';
import { MOCK_PRODUCTS } from '../../api/apiClient';
import { imageSource } from '../../utils/imageSource';
import { PAYMENT_RETURN_URL } from '../../api/paymentReturn';

const formatVND = (value = 0) => `${Math.round(value).toLocaleString('vi-VN')} ₫`;
const productById = (id) => MOCK_PRODUCTS.find((p) => p.id === id) || MOCK_PRODUCTS[0];

const ORDER_STATUS_MAP = {
  Pending: { label: 'Chờ xưởng xác nhận', color: COLORS.warning, bg: COLORS.warningBg, icon: 'time-outline' },
  AwaitingCustomerDeliveryApproval: { label: 'Cần bạn duyệt ngày giao', color: '#D46B08', bg: '#FFF7E6', icon: 'calendar-outline' },
  Confirmed: { label: 'Xưởng đã nhận đơn', color: COLORS.info, bg: COLORS.infoBg, icon: 'checkmark-circle-outline' },
  Processing: { label: 'Đang sản xuất', color: COLORS.info, bg: COLORS.infoBg, icon: 'construct-outline' },
  Shipping: { label: 'Đang vận chuyển lạnh', color: COLORS.accent, bg: COLORS.accentGoldBg, icon: 'snow-outline' },
  Shipped: { label: 'Đang vận chuyển lạnh', color: COLORS.accent, bg: COLORS.accentGoldBg, icon: 'snow-outline' },
  Delivered: { label: 'Đã giao thành công', color: COLORS.success, bg: COLORS.successBg, icon: 'checkmark-done-circle-outline' },
  CancellationRequested: { label: 'Chờ duyệt yêu cầu hủy', color: COLORS.error, bg: COLORS.errorBg, icon: 'alert-circle-outline' },
  Cancelled: { label: 'Đã hủy', color: COLORS.textMuted, bg: '#F5F5F5', icon: 'close-circle-outline' },
  Expired: { label: 'Đơn hết hạn', color: COLORS.textMuted, bg: '#F5F5F5', icon: 'time-outline' },
};

export default function OrderDetailScreen({ route, navigation }) {
  const insets = useSafeAreaInsets();
  const orderId = route?.params?.orderId || route?.params?.order?.id;
  const initialOrder = route?.params?.order || null;

  const [order, setOrder] = useState(initialOrder);
  const [paymentSummary, setPaymentSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  // Modals state
  const [cancelModalVisible, setCancelModalVisible] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [cancellationRequestModal, setCancellationRequestModal] = useState(false);
  const [disputeModalVisible, setDisputeModalVisible] = useState(false);
  const [disputeReason, setDisputeReason] = useState('');
  const [refundModalVisible, setRefundModalVisible] = useState(false);
  const [refundReason, setRefundReason] = useState('');
  const [refundAmount, setRefundAmount] = useState('');
  const [vietQrModalVisible, setVietQrModalVisible] = useState(false);
  const [selectedPart, setSelectedPart] = useState(null);

  const fetchOrderDetail = useCallback(async () => {
    if (!orderId) {
      setLoading(false);
      return;
    }
    try {
      // 1. Fetch real order detail from backend if not a pure demo id
      if (!orderId.startsWith('ord-')) {
        const data = await orderService.get(orderId);
        if (data) {
          setOrder(data);
        }
        // 2. Fetch payment summary
        try {
          const summary = await orderService.getPaymentSummary(orderId);
          if (summary) setPaymentSummary(summary);
        } catch (_) {
          // Non-critical if payment summary endpoint is missing or pending
        }
      } else {
        // Mock fallback for demo items
        if (!order) {
          setOrder({
            id: orderId,
            orderNumber: `ORD-2026-${orderId.replace(/\D/g, '') || '8899'}`,
            shopName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
            status: 'Pending',
            createdAt: new Date().toISOString(),
            recipientName: 'Nguyễn Văn An (Công ty CP Á Châu)',
            recipientPhone: '0912 345 678',
            deliveryAddress: 'Tầng 12, Tòa nhà Bitexco, Q.1, TP. Hồ Chí Minh',
            deliveryDateExpected: '2026-11-20',
            notes: 'Giao giờ hành chính, xe thùng lạnh kiểm soát nhiệt độ',
            items: [
              {
                id: 'item-1',
                productName: 'Hộp Hoàng Triều Thượng Hạng',
                variantName: 'Thập cẩm gà quay vi cá & Hạt sen matcha',
                quantity: 50,
                unitPrice: 617500,
                subtotal: 30875000,
                productId: 'prod-001',
              },
            ],
            totalAmount: 30875000,
            paymentParts: [
              { id: 'part-1', title: 'Đợt 1: Đặt cọc sản xuất (30%)', amount: 9262500, isPaid: false },
              { id: 'part-2', title: 'Đợt 2: Trước khi giao hàng (70%)', amount: 21612500, isPaid: false },
            ],
          });
        }
      }
    } catch (err) {
      console.warn('Could not fetch order detail:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [orderId]);

  useEffect(() => {
    fetchOrderDetail();
  }, [fetchOrderDetail]);

  const onRefresh = () => {
    setRefreshing(true);
    fetchOrderDetail();
  };

  // Actions: Respond to proposed delivery date
  const handleRespondDeliveryProposal = async (approve) => {
    Alert.alert(
      approve ? 'Đồng ý ngày giao xưởng đề xuất?' : 'Từ chối ngày giao đề xuất?',
      approve
        ? `Xác nhận giao hàng vào ngày ${order?.proposedDeliveryDate || 'mới do xưởng đề xuất'}?`
        : 'Từ chối đề xuất này có thể dẫn đến việc xưởng hủy đơn hoặc điều chỉnh lại.',
      [
        { text: 'Hủy', style: 'cancel' },
        {
          text: approve ? 'Đồng ý' : 'Từ chối',
          style: approve ? 'default' : 'destructive',
          onPress: async () => {
            setActionLoading(true);
            try {
              await orderService.respondDeliveryProposal(order.id, {
                approve,
                notes: approve ? 'Khách hàng đồng ý dời ngày giao.' : 'Khách hàng không thể dời ngày.',
              });
              Alert.alert('Thành công', approve ? 'Đã duyệt ngày giao hàng mới.' : 'Đã phản hồi từ chối tới xưởng.');
              fetchOrderDetail();
            } catch (e) {
              Alert.alert('Không thực hiện được', e?.response?.data?.message || 'Vui lòng thử lại sau.');
            } finally {
              setActionLoading(false);
            }
          },
        },
      ]
    );
  };

  // Actions: Cancel pending order
  const handleCancelOrder = async () => {
    if (!cancelReason.trim()) {
      Alert.alert('Thiếu thông tin', 'Vui lòng nhập lý do hủy đơn hàng.');
      return;
    }
    setActionLoading(true);
    try {
      await orderService.cancel(order.id, cancelReason.trim());
      setCancelModalVisible(false);
      setCancelReason('');
      Alert.alert('Đã hủy đơn hàng', 'Đơn hàng của bạn đã được hủy thành công.');
      fetchOrderDetail();
    } catch (e) {
      Alert.alert('Không hủy được đơn', e?.response?.data?.message || 'Có lỗi xảy ra.');
    } finally {
      setActionLoading(false);
    }
  };

  // Actions: Request cancellation when in production
  const handleRequestCancellation = async () => {
    if (!cancelReason.trim()) {
      Alert.alert('Thiếu thông tin', 'Vui lòng nhập lý do yêu cầu hủy đơn.');
      return;
    }
    setActionLoading(true);
    try {
      await orderService.requestCancellation(order.id, { reason: cancelReason.trim() });
      setCancellationRequestModal(false);
      setCancelReason('');
      Alert.alert('Đã gửi yêu cầu hủy', 'Yêu cầu hủy đã gửi đến xưởng. Xưởng sẽ phản hồi trong 24h.');
      fetchOrderDetail();
    } catch (e) {
      Alert.alert('Không gửi được yêu cầu', e?.response?.data?.message || 'Có lỗi xảy ra.');
    } finally {
      setActionLoading(false);
    }
  };

  // Actions: Pay VNPay
  const handlePayVnPay = async (partId) => {
    setActionLoading(true);
    try {
      let result;
      if (partId) {
        result = await orderService.createPartVnPayUrl(order.id, partId, PAYMENT_RETURN_URL);
      } else {
        result = await paymentService.createOrderVnPayUrl(order.id, PAYMENT_RETURN_URL);
      }
      const paymentUrl = result?.paymentUrl || result?.url || result?.data?.paymentUrl;
      if (!paymentUrl) {
        throw new Error('Không nhận được liên kết thanh toán từ cổng VNPay.');
      }
      await Linking.openURL(paymentUrl);
    } catch (e) {
      Alert.alert('Lỗi thanh toán', e?.response?.data?.message || e.message || 'Không thể tạo cổng thanh toán VNPay.');
    } finally {
      setActionLoading(false);
    }
  };

  // Actions: Confirm receipt
  const handleConfirmReceipt = () => {
    Alert.alert(
      'Xác nhận đã nhận đủ hàng',
      'Bạn đã nhận đúng, đủ số lượng và chất lượng bánh từ xưởng? Hệ thống sẽ giải ngân tiền cọc cho xưởng.',
      [
        { text: 'Chưa', style: 'cancel' },
        {
          text: 'Xác nhận đã nhận',
          onPress: async () => {
            setActionLoading(true);
            try {
              await orderService.confirmDeliveryReceipt(order.id, { notes: 'Khách hàng bấm xác nhận trên Mobile App' });
              Alert.alert('Thành công', 'Cảm ơn bạn! Đơn hàng đã hoàn tất.');
              fetchOrderDetail();
            } catch (e) {
              Alert.alert('Lỗi', e?.response?.data?.message || 'Không thể xác nhận lúc này.');
            } finally {
              setActionLoading(false);
            }
          },
        },
      ]
    );
  };

  // Actions: Dispute delivery
  const handleReportDispute = async () => {
    if (!disputeReason.trim()) {
      Alert.alert('Thiếu thông tin', 'Vui lòng mô tả chi tiết vấn đề giao nhận hoặc bánh lỗi.');
      return;
    }
    setActionLoading(true);
    try {
      await orderService.reportDeliveryDispute(order.id, {
        reason: disputeReason.trim(),
        severity: 'Moderate',
      });
      setDisputeModalVisible(false);
      setDisputeReason('');
      Alert.alert('Đã gửi khiếu nại', 'Bộ phận CSKH Nguyệt Phố và xưởng sẽ liên hệ xử lý trong 2h làm việc.');
      fetchOrderDetail();
    } catch (e) {
      Alert.alert('Lỗi khiếu nại', e?.response?.data?.message || 'Không thể gửi khiếu nại.');
    } finally {
      setActionLoading(false);
    }
  };

  // Actions: Request refund
  const handleRequestRefund = async () => {
    const amountNum = Number(refundAmount.replace(/\D/g, ''));
    if (!amountNum || amountNum <= 0) {
      Alert.alert('Số tiền không hợp lệ', 'Vui lòng nhập số tiền muốn hoàn.');
      return;
    }
    if (!refundReason.trim()) {
      Alert.alert('Thiếu lý do', 'Vui lòng nhập lý do yêu cầu hoàn tiền.');
      return;
    }
    setActionLoading(true);
    try {
      await orderService.requestRefund(order.id, {
        amount: amountNum,
        reason: refundReason.trim(),
      });
      setRefundModalVisible(false);
      setRefundReason('');
      setRefundAmount('');
      Alert.alert('Đã gửi yêu cầu hoàn tiền', 'Yêu cầu hoàn tiền đang được Admin thẩm định.');
      fetchOrderDetail();
    } catch (e) {
      Alert.alert('Lỗi hoàn tiền', e?.response?.data?.message || 'Không thể gửi yêu cầu hoàn tiền.');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading && !order) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={styles.loadingText}>Đang tải chi tiết đơn hàng...</Text>
      </View>
    );
  }

  const currentStatus = ORDER_STATUS_MAP[order?.rawStatus || order?.status] || {
    label: order?.status || 'Đang xử lý',
    color: COLORS.primary,
    bg: '#FFF1F0',
    icon: 'cube-outline',
  };

  const rawStatus = order?.rawStatus || order?.status || 'Pending';
  const items = order?.items || (order?.productName ? [
    {
      id: 'single-1',
      productName: order.productName,
      variantName: order.variantName,
      quantity: order.quantity,
      unitPrice: order.unitPrice,
      subtotal: (order.unitPrice || 0) * (order.quantity || 1),
      productId: order.productId,
    }
  ] : []);

  const totalAmount = order?.totalAmount || items.reduce((sum, it) => sum + (it.subtotal || 0), 0);
  const paymentParts = paymentSummary?.parts || order?.paymentParts || [];

  return (
    <View style={styles.container}>
      <AppHeader
        title={`Đơn hàng #${order?.orderNumber || orderId}`}
        subtitle={order?.shopName || 'Chi tiết đơn'}
        showBack={true}
        onBack={() => navigation.goBack()}
        rightIcon="help-circle-outline"
        onRightPress={() => navigation.navigate('AiAssistant')}
      />

      <ScrollView
        contentContainerStyle={[styles.scrollContent, { paddingBottom: insets.bottom + 100 }]}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={COLORS.primary} />}
        showsVerticalScrollIndicator={false}
      >
        {/* Status Banner */}
        <View style={[styles.statusCard, { backgroundColor: currentStatus.bg, borderColor: currentStatus.color }]}>
          <Ionicons name={currentStatus.icon} size={24} color={currentStatus.color} style={{ marginRight: 10 }} />
          <View style={{ flex: 1 }}>
            <Text style={[styles.statusLabel, { color: currentStatus.color }]}>{currentStatus.label}</Text>
            {order?.note ? <Text style={styles.statusSub}>{order.note}</Text> : null}
          </View>
        </View>

        {/* Urgent Action Banner: Awaiting Delivery Approval */}
        {rawStatus === 'AwaitingCustomerDeliveryApproval' && (
          <View style={styles.proposalBanner}>
            <View style={styles.proposalHeader}>
              <Ionicons name="alert-circle" size={20} color="#D46B08" />
              <Text style={styles.proposalTitle}>Xưởng đề xuất đổi ngày giao hàng</Text>
            </View>
            <Text style={styles.proposalDesc}>
              Xưởng bánh đề xuất giao vào ngày <Text style={styles.boldText}>{order?.proposedDeliveryDate || 'mới'}</Text> do công suất sản xuất mẻ mới.
            </Text>
            <View style={styles.proposalActionRow}>
              <TouchableOpacity
                style={[styles.proposalBtn, styles.proposalBtnReject]}
                onPress={() => handleRespondDeliveryProposal(false)}
                disabled={actionLoading}
              >
                <Text style={styles.proposalBtnTextReject}>Từ chối</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.proposalBtn, styles.proposalBtnApprove]}
                onPress={() => handleRespondDeliveryProposal(true)}
                disabled={actionLoading}
              >
                <Text style={styles.proposalBtnTextApprove}>Đồng ý ngày mới</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* Workshop Info */}
        <View style={styles.card}>
          <View style={styles.shopRow}>
            <View style={styles.shopAvatar}>
              <Ionicons name="storefront-outline" size={20} color={COLORS.primary} />
            </View>
            <View style={{ flex: 1, marginLeft: 10 }}>
              <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                <Text style={styles.shopName}>{order?.shopName || 'Xưởng Bánh Nghệ Nhân'}</Text>
                {order?.trusted && (
                  <Ionicons name="shield-checkmark" size={16} color={COLORS.accent} style={{ marginLeft: 4 }} />
                )}
              </View>
              <Text style={styles.shopSub}>Cam kết chuẩn vệ sinh ATTP & Vận chuyển xe lạnh</Text>
            </View>
            <TouchableOpacity
              style={styles.chatShopBtn}
              onPress={() => navigation.navigate('AiAssistant')}
            >
              <Ionicons name="chatbubble-ellipses-outline" size={16} color={COLORS.primary} />
              <Text style={styles.chatShopText}>Hỗ trợ</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Product Items */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Sản phẩm đặt mua ({items.length})</Text>
          {items.map((item, idx) => {
            const demoProd = productById(item.productId);
            const cover = item.productImage || demoProd?.coverImage;
            return (
              <View key={item.id || idx} style={styles.productItem}>
                {cover ? (
                  <Image source={imageSource(cover)} style={styles.productThumb} resizeMode="cover" />
                ) : (
                  <View style={[styles.productThumb, styles.productThumbEmpty]}>
                    <Ionicons name="cube-outline" size={24} color={COLORS.textMuted} />
                  </View>
                )}
                <View style={styles.productInfo}>
                  <Text style={styles.productName} numberOfLines={2}>{item.productName || 'Bánh Trung Thu Thượng Hạng'}</Text>
                  {item.variantName ? <Text style={styles.variantName}>{item.variantName}</Text> : null}
                  <View style={styles.priceQtyRow}>
                    <Text style={styles.qtyText}>Số lượng: x{item.quantity}</Text>
                    <Text style={styles.itemPrice}>{formatVND(item.subtotal || item.unitPrice * item.quantity)}</Text>
                  </View>
                </View>
              </View>
            );
          })}
        </View>

        {/* Delivery & Recipient Info */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Thông tin giao nhận</Text>
          <View style={styles.infoRow}>
            <Ionicons name="person-outline" size={16} color={COLORS.textSecondary} style={styles.infoIcon} />
            <Text style={styles.infoLabel}>Người nhận:</Text>
            <Text style={styles.infoValue}>{order?.recipientName || 'Chưa cung cấp'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Ionicons name="call-outline" size={16} color={COLORS.textSecondary} style={styles.infoIcon} />
            <Text style={styles.infoLabel}>Số điện thoại:</Text>
            <Text style={styles.infoValue}>{order?.recipientPhone || 'Chưa cung cấp'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Ionicons name="location-outline" size={16} color={COLORS.textSecondary} style={styles.infoIcon} />
            <Text style={styles.infoLabel}>Địa chỉ nhận:</Text>
            <Text style={[styles.infoValue, { flex: 1 }]}>{order?.deliveryAddress || 'Nhận tại xưởng'}</Text>
          </View>
          <View style={styles.infoRow}>
            <Ionicons name="calendar-outline" size={16} color={COLORS.textSecondary} style={styles.infoIcon} />
            <Text style={styles.infoLabel}>Ngày hẹn giao:</Text>
            <Text style={[styles.infoValue, styles.boldText]}>
              {order?.confirmedDeliveryDate || order?.deliveryDateExpected || 'Theo thỏa thuận'}
            </Text>
          </View>
          {order?.notes ? (
            <View style={styles.infoRow}>
              <Ionicons name="document-text-outline" size={16} color={COLORS.textSecondary} style={styles.infoIcon} />
              <Text style={styles.infoLabel}>Ghi chú:</Text>
              <Text style={[styles.infoValue, { flex: 1 }]}>{order.notes}</Text>
            </View>
          ) : null}
        </View>

        {/* Payment Summary & Installment Parts */}
        <View style={styles.card}>
          <View style={styles.sectionHeaderRow}>
            <Text style={styles.sectionTitle}>Tiến độ thanh toán</Text>
            <Text style={styles.totalBadge}>{formatVND(totalAmount)}</Text>
          </View>

          {paymentParts.length > 0 ? (
            paymentParts.map((part, index) => {
              const isPaid = Boolean(part.isPaid || part.status === 'Paid');
              return (
                <View key={part.id || index} style={[styles.partItem, isPaid && styles.partItemPaid]}>
                  <View style={{ flex: 1 }}>
                    <View style={{ flexDirection: 'row', alignItems: 'center' }}>
                      <Ionicons
                        name={isPaid ? 'checkmark-circle' : 'time-outline'}
                        size={18}
                        color={isPaid ? COLORS.success : COLORS.warning}
                      />
                      <Text style={[styles.partTitle, isPaid && styles.partTitlePaid]}>
                        {part.title || `Đợt ${index + 1}`}
                      </Text>
                    </View>
                    <Text style={styles.partAmount}>{formatVND(part.amount)}</Text>
                    {part.deadline ? <Text style={styles.partDeadline}>Hạn chót: {part.deadline}</Text> : null}
                  </View>

                  {!isPaid && (
                    <View style={styles.partActions}>
                      <TouchableOpacity
                        style={styles.payPartBtnVnPay}
                        onPress={() => handlePayVnPay(part.id)}
                        disabled={actionLoading}
                      >
                        <Text style={styles.payPartTextVnPay}>VNPay</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={styles.payPartBtnQr}
                        onPress={() => {
                          setSelectedPart(part);
                          setVietQrModalVisible(true);
                        }}
                      >
                        <Ionicons name="qr-code-outline" size={14} color={COLORS.primary} />
                        <Text style={styles.payPartTextQr}>VietQR</Text>
                      </TouchableOpacity>
                    </View>
                  )}
                  {isPaid && (
                    <View style={styles.paidBadge}>
                      <Text style={styles.paidBadgeText}>Đã thanh toán</Text>
                    </View>
                  )}
                </View>
              );
            })
          ) : (
            <View style={styles.singlePaymentRow}>
              <Text style={styles.singlePaymentSub}>Đơn hàng thanh toán 1 đợt qua cổng bảo chứng Escrow.</Text>
              {rawStatus !== 'Cancelled' && rawStatus !== 'Delivered' && (
                <View style={{ flexDirection: 'row', gap: 8, marginTop: 10 }}>
                  <CustomButton
                    title="Thanh toán VNPay"
                    icon="card-outline"
                    onPress={() => handlePayVnPay()}
                    style={{ flex: 1 }}
                  />
                  <TouchableOpacity
                    style={styles.singleVietQrBtn}
                    onPress={() => {
                      setSelectedPart({ title: 'Thanh toán đơn hàng', amount: totalAmount });
                      setVietQrModalVisible(true);
                    }}
                  >
                    <Ionicons name="qr-code-outline" size={18} color={COLORS.primary} />
                    <Text style={styles.singleVietQrText}>VietQR</Text>
                  </TouchableOpacity>
                </View>
              )}
            </View>
          )}
        </View>

        {/* PoD Logistics Navigation */}
        {(rawStatus === 'Shipping' || rawStatus === 'Shipped' || rawStatus === 'Delivered') && (
          <TouchableOpacity
            style={styles.podCard}
            onPress={() => navigation.navigate('DeliveryPoD', { orderId: order.id, orderNumber: order.orderNumber })}
          >
            <View style={styles.podIconWrap}>
              <Ionicons name="snow" size={24} color="#0958D9" />
            </View>
            <View style={{ flex: 1, marginLeft: 12 }}>
              <Text style={styles.podTitle}>Biên bản giao nhận & Xe lạnh (PoD)</Text>
              <Text style={styles.podSub}>Xem nhiệt độ xe lạnh và chữ ký/ảnh giao hàng thực tế.</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={COLORS.textMuted} />
          </TouchableOpacity>
        )}

        {/* Contextual Action Buttons */}
        <View style={styles.actionsContainer}>
          {/* 1. Pending: Customer can cancel */}
          {rawStatus === 'Pending' && (
            <TouchableOpacity
              style={[styles.outlineBtn, styles.dangerBtn]}
              onPress={() => setCancelModalVisible(true)}
              disabled={actionLoading}
            >
              <Ionicons name="close-circle-outline" size={18} color={COLORS.error} />
              <Text style={styles.dangerBtnText}>Hủy đơn hàng</Text>
            </TouchableOpacity>
          )}

          {/* 2. Confirmed / Processing: Customer can request cancellation */}
          {(rawStatus === 'Confirmed' || rawStatus === 'Processing') && (
            <TouchableOpacity
              style={[styles.outlineBtn, styles.dangerBtn]}
              onPress={() => setCancellationRequestModal(true)}
              disabled={actionLoading}
            >
              <Ionicons name="alert-circle-outline" size={18} color={COLORS.error} />
              <Text style={styles.dangerBtnText}>Gửi yêu cầu hủy đơn</Text>
            </TouchableOpacity>
          )}

          {/* 3. Delivered: Customer can confirm receipt, dispute, refund, review */}
          {rawStatus === 'Delivered' && (
            <View style={{ gap: 10 }}>
              <CustomButton
                title="Xác nhận đã nhận đủ hàng"
                icon="checkmark-done"
                onPress={handleConfirmReceipt}
              />
              <View style={{ flexDirection: 'row', gap: 10 }}>
                <TouchableOpacity
                  style={[styles.outlineBtn, { flex: 1 }]}
                  onPress={() => setDisputeModalVisible(true)}
                >
                  <Ionicons name="warning-outline" size={16} color={COLORS.warning} />
                  <Text style={[styles.outlineBtnText, { color: COLORS.warning }]}>Khiếu nại</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.outlineBtn, { flex: 1 }]}
                  onPress={() => setRefundModalVisible(true)}
                >
                  <Ionicons name="cash-outline" size={16} color={COLORS.primary} />
                  <Text style={[styles.outlineBtnText, { color: COLORS.primary }]}>Hoàn tiền</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.outlineBtn, { flex: 1 }]}
                  onPress={() => navigation.navigate('ReviewForm', {
                    orderId: order.id,
                    orderNumber: order.orderNumber,
                    shopName: order.shopName,
                  })}
                >
                  <Ionicons name="star-outline" size={16} color={COLORS.accent} />
                  <Text style={[styles.outlineBtnText, { color: COLORS.accent }]}>Đánh giá</Text>
                </TouchableOpacity>
              </View>
            </View>
          )}
        </View>
      </ScrollView>

      {/* MODAL 1: HỦY ĐƠN HÀNG TRỰC TIẾP (PENDING) */}
      <Modal visible={cancelModalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Hủy đơn hàng #{order?.orderNumber}</Text>
              <TouchableOpacity onPress={() => setCancelModalVisible(false)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            <Text style={styles.modalDesc}>
              Đơn hàng đang ở trạng thái chờ xác nhận. Bạn có thể hủy ngay lập tức mà không mất phí.
            </Text>
            <TextInput
              style={styles.textInput}
              placeholder="Nhập lý do hủy (vd: Thay đổi kế hoạch, Đặt nhầm số lượng...)"
              placeholderTextColor={COLORS.textMuted}
              multiline
              numberOfLines={3}
              value={cancelReason}
              onChangeText={setCancelReason}
            />
            <View style={styles.modalBtnRow}>
              <TouchableOpacity style={styles.modalCancelBtn} onPress={() => setCancelModalVisible(false)}>
                <Text style={styles.modalCancelText}>Đóng</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: COLORS.error }]}
                onPress={handleCancelOrder}
                disabled={actionLoading}
              >
                {actionLoading ? (
                  <ActivityIndicator color="#fff" size="small" />
                ) : (
                  <Text style={styles.modalConfirmText}>Xác nhận hủy</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* MODAL 2: YÊU CẦU HỦY ĐƠN (PROCESSING/CONFIRMED) */}
      <Modal visible={cancellationRequestModal} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Gửi yêu cầu hủy sản xuất</Text>
              <TouchableOpacity onPress={() => setCancellationRequestModal(false)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            <Text style={styles.modalDesc}>
              Đơn hàng đã được xưởng xác nhận hoặc đang sản xuất. Yêu cầu hủy cần được xưởng phê duyệt theo chính sách bồi hoàn nguyên liệu.
            </Text>
            <TextInput
              style={styles.textInput}
              placeholder="Lý do chi tiết muốn hủy..."
              placeholderTextColor={COLORS.textMuted}
              multiline
              numberOfLines={3}
              value={cancelReason}
              onChangeText={setCancelReason}
            />
            <View style={styles.modalBtnRow}>
              <TouchableOpacity style={styles.modalCancelBtn} onPress={() => setCancellationRequestModal(false)}>
                <Text style={styles.modalCancelText}>Quay lại</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: COLORS.error }]}
                onPress={handleRequestCancellation}
                disabled={actionLoading}
              >
                {actionLoading ? (
                  <ActivityIndicator color="#fff" size="small" />
                ) : (
                  <Text style={styles.modalConfirmText}>Gửi yêu cầu</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* MODAL 3: KHIẾU NẠI GIAO NHẬN */}
      <Modal visible={disputeModalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Khiếu nại giao nhận</Text>
              <TouchableOpacity onPress={() => setDisputeModalVisible(false)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            <Text style={styles.modalDesc}>
              Bánh bị móp méo, giao thiếu số lượng, hoặc xe lạnh không đạt nhiệt độ cam kết? Hãy mô tả chi tiết để được hỗ trợ.
            </Text>
            <TextInput
              style={styles.textInput}
              placeholder="Mô tả sự cố giao nhận..."
              placeholderTextColor={COLORS.textMuted}
              multiline
              numberOfLines={4}
              value={disputeReason}
              onChangeText={setDisputeReason}
            />
            <View style={styles.modalBtnRow}>
              <TouchableOpacity style={styles.modalCancelBtn} onPress={() => setDisputeModalVisible(false)}>
                <Text style={styles.modalCancelText}>Hủy</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: COLORS.warning }]}
                onPress={handleReportDispute}
                disabled={actionLoading}
              >
                {actionLoading ? (
                  <ActivityIndicator color="#fff" size="small" />
                ) : (
                  <Text style={styles.modalConfirmText}>Gửi khiếu nại</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* MODAL 4: YÊU CẦU HOÀN TIỀN */}
      <Modal visible={refundModalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Yêu cầu hoàn tiền</Text>
              <TouchableOpacity onPress={() => setRefundModalVisible(false)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            <Text style={styles.modalDesc}>
              Nhập số tiền muốn hoàn và lý do hoàn tiền từ tài khoản bảo chứng Escrow.
            </Text>
            <TextInput
              style={[styles.textInput, { height: 46, marginBottom: 12 }]}
              placeholder="Số tiền hoàn (VNĐ) - vd: 5000000"
              placeholderTextColor={COLORS.textMuted}
              keyboardType="numeric"
              value={refundAmount}
              onChangeText={setRefundAmount}
            />
            <TextInput
              style={styles.textInput}
              placeholder="Lý do hoàn tiền chi tiết..."
              placeholderTextColor={COLORS.textMuted}
              multiline
              numberOfLines={3}
              value={refundReason}
              onChangeText={setRefundReason}
            />
            <View style={styles.modalBtnRow}>
              <TouchableOpacity style={styles.modalCancelBtn} onPress={() => setRefundModalVisible(false)}>
                <Text style={styles.modalCancelText}>Hủy</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, { backgroundColor: COLORS.primary }]}
                onPress={handleRequestRefund}
                disabled={actionLoading}
              >
                {actionLoading ? (
                  <ActivityIndicator color="#fff" size="small" />
                ) : (
                  <Text style={styles.modalConfirmText}>Xác nhận yêu cầu</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* MODAL 5: CHUYỂN KHOẢN VIETQR (MB BANK NAPAS 247) */}
      <Modal visible={vietQrModalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.modalSheet}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Chuyển khoản VietQR</Text>
              <TouchableOpacity onPress={() => setVietQrModalVisible(false)}>
                <Ionicons name="close" size={24} color={COLORS.textPrimary} />
              </TouchableOpacity>
            </View>
            <View style={styles.qrCenterBox}>
              <View style={styles.qrPlaceholder}>
                <Ionicons name="qr-code" size={130} color={COLORS.primary} />
                <Text style={styles.qrBrand}>NAPAS 247 · VIETQR</Text>
              </View>
              <View style={styles.bankDetailCard}>
                <Text style={styles.bankName}>NGÂN HÀNG QUÂN ĐỘI (MB BANK)</Text>
                <Text style={styles.bankAcc}>STK: <Text style={styles.boldText}>0988 888 6868</Text></Text>
                <Text style={styles.bankHolder}>Chủ TK: CÔNG TY TNHH NGUYỆT PHỐ ESCROW</Text>
                <Text style={styles.bankAmount}>
                  Số tiền: <Text style={styles.boldPrice}>{formatVND(selectedPart?.amount || totalAmount)}</Text>
                </Text>
                <Text style={styles.bankSyntax}>
                  Nội dung CK: <Text style={styles.boldSyntax}>{order?.orderNumber || 'NP2026'} TT</Text>
                </Text>
              </View>
            </View>
            <Text style={styles.qrNotice}>
              Sau khi chuyển khoản thành công, hệ thống Escrow sẽ tự động ghi nhận thanh toán trong 30 giây.
            </Text>
            <CustomButton
              title="Đã chuyển khoản xong"
              onPress={() => {
                setVietQrModalVisible(false);
                Alert.alert('Ghi nhận', 'Đang đối soát giao dịch chuyển khoản. Vui lòng kiểm tra lại sau 1 phút.');
                fetchOrderDetail();
              }}
            />
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F4F1EC',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F4F1EC',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    color: COLORS.textSecondary,
  },
  scrollContent: {
    padding: 16,
    gap: 12,
  },
  statusCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  statusLabel: {
    fontSize: 16,
    fontWeight: '700',
  },
  statusSub: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  proposalBanner: {
    backgroundColor: '#FFF7E6',
    borderWidth: 1,
    borderColor: '#D46B08',
    borderRadius: 12,
    padding: 14,
  },
  proposalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 6,
  },
  proposalTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#D46B08',
  },
  proposalDesc: {
    fontSize: 13,
    color: COLORS.textPrimary,
    lineHeight: 18,
    marginBottom: 12,
  },
  proposalActionRow: {
    flexDirection: 'row',
    gap: 10,
  },
  proposalBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  proposalBtnReject: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: COLORS.borderDark,
  },
  proposalBtnApprove: {
    backgroundColor: '#D46B08',
  },
  proposalBtnTextReject: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textSecondary,
  },
  proposalBtnTextApprove: {
    fontSize: 13,
    fontWeight: '600',
    color: '#FFFFFF',
  },
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: COLORS.border,
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 3,
    elevation: 1,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 12,
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  totalBadge: {
    fontSize: 16,
    fontWeight: '700',
    color: COLORS.primary,
  },
  shopRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  shopAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#FFF1F0',
    alignItems: 'center',
    justifyContent: 'center',
  },
  shopName: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  shopSub: {
    fontSize: 12,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  chatShopBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: COLORS.primary,
  },
  chatShopText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.primary,
  },
  productItem: {
    flexDirection: 'row',
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: COLORS.border,
    gap: 12,
  },
  productThumb: {
    width: 64,
    height: 64,
    borderRadius: 8,
    backgroundColor: '#F5F5F5',
  },
  productThumbEmpty: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  productInfo: {
    flex: 1,
    justifyContent: 'space-between',
  },
  productName: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  variantName: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  priceQtyRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 6,
  },
  qtyText: {
    fontSize: 13,
    color: COLORS.textMuted,
  },
  itemPrice: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.primary,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginVertical: 4,
    gap: 8,
  },
  infoIcon: {
    marginTop: 2,
  },
  infoLabel: {
    fontSize: 13,
    color: COLORS.textSecondary,
    width: 100,
  },
  infoValue: {
    fontSize: 13,
    color: COLORS.textPrimary,
  },
  boldText: {
    fontWeight: '700',
  },
  boldPrice: {
    fontWeight: '700',
    color: COLORS.primary,
  },
  partItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    backgroundColor: '#FAFAF8',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 8,
  },
  partItemPaid: {
    backgroundColor: '#F6FFED',
    borderColor: '#B7EB8F',
  },
  partTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginLeft: 6,
  },
  partTitlePaid: {
    color: COLORS.success,
  },
  partAmount: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.primary,
    marginTop: 4,
  },
  partDeadline: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  partActions: {
    flexDirection: 'row',
    gap: 6,
  },
  payPartBtnVnPay: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 6,
  },
  payPartTextVnPay: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
  },
  payPartBtnQr: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderWidth: 1,
    borderColor: COLORS.primary,
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderRadius: 6,
  },
  payPartTextQr: {
    color: COLORS.primary,
    fontSize: 12,
    fontWeight: '600',
  },
  paidBadge: {
    backgroundColor: '#F6FFED',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#B7EB8F',
  },
  paidBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: COLORS.success,
  },
  singlePaymentRow: {
    paddingTop: 4,
  },
  singlePaymentSub: {
    fontSize: 13,
    color: COLORS.textSecondary,
  },
  singleVietQrBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    borderWidth: 1,
    borderColor: COLORS.primary,
    borderRadius: 8,
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  singleVietQrText: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.primary,
  },
  podCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#E6F4FF',
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    borderColor: '#91CAFF',
  },
  podIconWrap: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  podTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0958D9',
  },
  podSub: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  actionsContainer: {
    marginTop: 6,
  },
  outlineBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.borderDark,
    borderRadius: 8,
    paddingVertical: 12,
  },
  dangerBtn: {
    borderColor: COLORS.error,
    backgroundColor: '#FFF1F0',
  },
  dangerBtnText: {
    fontSize: 14,
    fontWeight: '700',
    color: COLORS.error,
  },
  outlineBtnText: {
    fontSize: 13,
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalSheet: {
    backgroundColor: COLORS.surface,
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
    padding: 20,
    maxHeight: '85%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  modalTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  modalDesc: {
    fontSize: 13,
    color: COLORS.textSecondary,
    lineHeight: 18,
    marginBottom: 12,
  },
  textInput: {
    backgroundColor: '#F7F7F7',
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    color: COLORS.textPrimary,
    textAlignVertical: 'top',
    marginBottom: 16,
  },
  modalBtnRow: {
    flexDirection: 'row',
    gap: 10,
  },
  modalCancelBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    backgroundColor: '#F0F0F0',
    alignItems: 'center',
  },
  modalCancelText: {
    fontSize: 14,
    fontWeight: '600',
    color: COLORS.textSecondary,
  },
  modalConfirmBtn: {
    flex: 2,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalConfirmText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  qrCenterBox: {
    alignItems: 'center',
    marginVertical: 10,
  },
  qrPlaceholder: {
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#FFF1F0',
    borderRadius: 16,
    marginBottom: 14,
  },
  qrBrand: {
    marginTop: 8,
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.primary,
    letterSpacing: 1,
  },
  bankDetailCard: {
    width: '100%',
    backgroundColor: '#FAFAF8',
    padding: 14,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    gap: 4,
  },
  bankName: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.primary,
  },
  bankAcc: {
    fontSize: 13,
    color: COLORS.textPrimary,
  },
  bankHolder: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  bankAmount: {
    fontSize: 13,
    color: COLORS.textPrimary,
    marginTop: 2,
  },
  bankSyntax: {
    fontSize: 13,
    color: COLORS.textPrimary,
  },
  boldSyntax: {
    fontWeight: '700',
    color: COLORS.accent,
  },
  qrNotice: {
    fontSize: 12,
    color: COLORS.textMuted,
    textAlign: 'center',
    marginVertical: 12,
  },
});
