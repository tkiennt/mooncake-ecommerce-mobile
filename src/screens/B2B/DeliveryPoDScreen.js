import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  Image,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Linking,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { deliveryService } from '../../services/api/deliveryService';
import { orderService } from '../../services/api/orderService';
import { imageSource } from '../../utils/imageSource';

export default function DeliveryPoDScreen({ route, navigation }) {
  const { orderId, orderNumber = 'ORD-2026-8711' } = route.params || {};

  const [deliveryInfo, setDeliveryInfo] = useState({
    trackingCode: 'VNP-COLD-2026-9941',
    carrierName: 'Nguyệt Phố Express (Đội xe lạnh chuyên dụng)',
    driverName: 'Trần Văn Mạnh',
    driverPhone: '0988 123 456',
    vehiclePlate: '29C-892.44',
    storageTemp: 20.5,
    safeMin: 18.0,
    safeMax: 22.0,
    estimatedArrival: '18/10/2026 - 16:30',
    status: 'Delivered',
    destination: 'Tòa nhà Landmark 81, 720A Điện Biên Phủ, P.22, Bình Thạnh, TP.HCM',
    timeline: [
      { step: 'Đã đóng gói hoàn tất tại xưởng', time: '18/10/2026 08:30', done: true },
      { step: 'Bàn giao xe lạnh chuyên dụng kiểm soát nhiệt', time: '18/10/2026 10:15', done: true },
      { step: 'Đang vận chuyển liên tỉnh kiểm soát IoT', time: '18/10/2026 13:45', done: true },
      { step: 'Đã giao tới điểm nhận & Ký nghiệm thu PoD', time: '18/10/2026 16:30', done: true },
    ],
    podData: {
      packagePhoto: require('../../../assets/products/hop-son-mai.jpg'),
      signaturePhoto: null,
      deliveredAt: '18/10/2026 16:30:15 GMT+7',
      gpsLocation: '10.7951° N, 106.7218° E (Landmark 81, TP.HCM)',
      receiverName: 'Nguyễn Văn An (Kế toán trưởng ký nhận)',
    },
  });

  const isRealOrder = Boolean(orderId) && !String(orderId).startsWith('ord-');

  // GET /deliveries/order/{orderId} (+ proofs). Driver/vehicle/temperature are not provided by the
  // backend, so those panels stay hidden for real deliveries instead of showing invented values.
  useEffect(() => {
    if (!isRealOrder) return;
    (async () => {
      try {
        const found = await deliveryService.getByOrder(orderId);
        const delivery = Array.isArray(found) ? found[0] : found;
        if (!delivery) { setDeliveryInfo(null); return; }
        const detail = await deliveryService.get(delivery.id).catch(() => delivery);
        const proof = (detail.proofs || []).find((item) => item.photoUrl || item.signatureUrl) || {};
        const steps = ['Pending', 'PickedUp', 'InTransit', 'Delivered'];
        const reached = Math.max(0, steps.indexOf(detail.status));
        setDeliveryInfo({
          trackingCode: detail.trackingCode || detail.deliveryNumber,
          carrierName: detail.supplierName || 'Xưởng giao hàng',
          driverName: null,
          storageTemp: null,
          status: detail.status,
          destination: detail.toAddress,
          timeline: [
            { step: 'Xưởng chuẩn bị hàng', time: detail.scheduledDate ? `Dự kiến ${detail.scheduledDate}` : '', done: reached >= 0 },
            { step: 'Đã lấy hàng lên xe', time: '', done: reached >= 1 },
            { step: 'Đang vận chuyển', time: '', done: reached >= 2 },
            { step: 'Đã giao tới điểm nhận', time: detail.actualDeliveryDate || '', done: reached >= 3 },
          ],
          podData: {
            packagePhoto: proof.photoUrl || null,
            signaturePhoto: proof.signatureUrl || null,
            deliveredAt: proof.takenAt ? new Date(proof.takenAt).toLocaleString('vi-VN') : '—',
            gpsLocation: proof.locationLat != null ? `${proof.locationLat}, ${proof.locationLng}` : '—',
            receiverName: detail.recipientName || proof.takenBy || '—',
          },
        });
      } catch (error) {
        if (error?.response) setDeliveryInfo(null);
      }
    })();
  }, [orderId]);

  const handleConfirmInspection = async () => {
    const goReview = () => navigation.navigate('ReviewForm', { orderId: isRealOrder ? orderId : undefined, orderNumber });
    if (!isRealOrder) {
      Alert.alert('Chế độ demo', 'Đây là đơn mẫu nên không có xác nhận thật nào được gửi.', [{ text: 'Đánh giá đơn mẫu', onPress: goReview }]);
      return;
    }
    try {
      // POST /orders/{id}/delivery/confirm-receipt
      await orderService.confirmDeliveryReceipt(orderId);
      Alert.alert('Đã xác nhận nhận hàng', 'Đơn hàng hoàn tất. Bạn có thể đánh giá xưởng ngay.', [{ text: 'Đánh giá', onPress: goReview }]);
    } catch (error) {
      Alert.alert('Không xác nhận được', error?.response?.data?.message || 'Vui lòng thử lại.');
    }
  };

  if (!deliveryInfo) {
    return (
      <View style={styles.container}>
        <AppHeader title="Giao hàng" subtitle={orderNumber} showBack onBack={() => navigation.goBack()} />
        <View style={{ alignItems: 'center', padding: 40, gap: 8 }}>
          <Ionicons name="car-outline" size={40} color={COLORS.textMuted} />
          <Text style={{ color: COLORS.textSecondary, textAlign: 'center' }}>Xưởng chưa tạo chuyến giao cho đơn này.</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <AppHeader
        title="Giám Sát Vận Chuyển & PoD"
        subtitle={orderNumber}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Status Card */}
        <View style={styles.statusCard}>
          <View style={styles.statusHeader}>
            <View>
              <Text style={styles.codeText}>{deliveryInfo.trackingCode}</Text>
              <Text style={styles.carrierText}>{deliveryInfo.carrierName}</Text>
            </View>
            <View style={styles.statusTag}>
              <Ionicons name="checkmark-circle" size={14} color="#059669" />
              <Text style={styles.statusLabel}>Đã Bàn Giao</Text>
            </View>
          </View>

          {/* Temperature gauge — demo only; the backend has no temperature data */}
          {deliveryInfo.storageTemp != null && (
          <View style={styles.gaugeContainer}>
            <View style={styles.gaugeHeader}>
              <View style={styles.gaugeTitleWrap}>
                <Ionicons name="snow" size={18} color="#0284C7" />
                <Text style={styles.gaugeTitle}>CẢM BIẾN NHIỆT ĐỘ THÙNG LẠNH IOT</Text>
              </View>
              <View style={styles.tempBadge}>
                <Text style={styles.tempBadgeText}>{deliveryInfo.storageTemp} °C</Text>
              </View>
            </View>

            {/* Gauge Graphic Bar */}
            <View style={styles.barWrap}>
              <View style={styles.barScale}>
                <Text style={styles.scaleLabel}>15°C</Text>
                <Text style={styles.scaleSafeLabel}>Dải an toàn (18°C - 22°C)</Text>
                <Text style={styles.scaleLabel}>25°C</Text>
              </View>
              <View style={styles.gaugeTrack}>
                <View style={styles.safeZone} />
                <View style={[styles.needle, { left: '55%' }]}>
                  <View style={styles.needleDot} />
                  <Ionicons name="caret-up" size={14} color={COLORS.primary} />
                </View>
              </View>
            </View>

            <View style={styles.gaugeFooter}>
              <Ionicons name="shield-checkmark" size={14} color="#059669" />
              <Text style={styles.gaugeFooterText}>
                Nhiệt độ đạt chuẩn bảo quản bánh cao cấp · Không biến dạng kết cấu
              </Text>
            </View>
          </View>
          )}

          {/* Driver Row */}
          {deliveryInfo.driverName ? (
          <View style={styles.driverRow}>
            <View style={styles.driverInfo}>
              <Ionicons name="person-circle-outline" size={32} color={COLORS.accent} />
              <View style={styles.driverTextCol}>
                <Text style={styles.driverName}>{deliveryInfo.driverName} • Biển số: {deliveryInfo.vehiclePlate}</Text>
                <Text style={styles.driverPhone}>SĐT tài xế: {deliveryInfo.driverPhone}</Text>
              </View>
            </View>
            <TouchableOpacity
              style={styles.callBtn}
              onPress={() => Linking.openURL(`tel:${String(deliveryInfo.driverPhone).replace(/\s/g, '')}`).catch(() => {})}
            >
              <Ionicons name="call" size={16} color="#FFF" />
            </TouchableOpacity>
          </View>
          ) : null}
        </View>

        {/* Timeline */}
        <View style={styles.timelineCard}>
          <Text style={styles.cardHeading}>Hành Trình Giao Hàng B2B</Text>
          {deliveryInfo.timeline.map((step, idx) => (
            <View key={idx} style={styles.timelineItem}>
              <View style={styles.stepDot}>
                <Ionicons name="checkmark" size={10} color="#FFF" />
              </View>
              <View style={styles.stepContent}>
                <Text style={styles.stepName}>{step.step}</Text>
                <Text style={styles.stepTime}>{step.time}</Text>
              </View>
            </View>
          ))}
        </View>

        {/* Proof of Delivery (PoD) Section */}
        <View style={styles.podCard}>
          <View style={styles.podHeader}>
            <Ionicons name="document-attach-outline" size={20} color={COLORS.primary} />
            <Text style={styles.podTitle}>Biên Bản Nghiệm Thu & Chữ Ký PoD</Text>
          </View>

          <View style={styles.podGrid}>
            <View style={styles.podCol}>
              <Text style={styles.podLabel}>Ảnh kiện hàng bàn giao:</Text>
              {deliveryInfo.podData.packagePhoto
                ? <Image source={imageSource(deliveryInfo.podData.packagePhoto)} style={styles.podImage} />
                : <View style={[styles.podImage, styles.podEmpty]}><Text style={styles.podEmptyText}>Chưa có ảnh</Text></View>}
            </View>
            <View style={styles.podCol}>
              <Text style={styles.podLabel}>Chữ ký điện tử người nhận:</Text>
              {deliveryInfo.podData.signaturePhoto
                ? <Image source={imageSource(deliveryInfo.podData.signaturePhoto)} style={styles.podImage} resizeMode="contain" />
                : <View style={[styles.podImage, styles.podEmpty]}><Text style={styles.podEmptyText}>Chưa có chữ ký</Text></View>}
            </View>
          </View>

          <View style={styles.podDetailsBox}>
            <Text style={styles.podDetailText}>
              <Text style={styles.bold}>Thời gian bàn giao:</Text> {deliveryInfo.podData.deliveredAt}
            </Text>
            <Text style={styles.podDetailText}>
              <Text style={styles.bold}>Tọa độ GPS:</Text> {deliveryInfo.podData.gpsLocation}
            </Text>
            <Text style={styles.podDetailText}>
              <Text style={styles.bold}>Đại diện ký nhận:</Text> {deliveryInfo.podData.receiverName}
            </Text>
          </View>

          <CustomButton
            title="Xác Nhận Nghiệm Thu & Đánh Giá"
            icon="✅"
            onPress={handleConfirmInspection}
            style={styles.confirmBtn}
          />
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  podEmpty: {
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F6F3EF',
  },
  podEmptyText: {
    color: COLORS.textMuted,
    fontSize: 12,
  },
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  scroll: {
    padding: 16,
    paddingBottom: 40,
  },
  statusCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 14,
  },
  statusHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 14,
  },
  codeText: {
    fontSize: 16,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  carrierText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  statusTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#F6FFED',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#B7EB8F',
  },
  statusLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: '#059669',
  },

  // Gauge styles
  gaugeContainer: {
    backgroundColor: '#F0F9FF',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#BAE6FD',
    padding: 12,
    marginBottom: 14,
  },
  gaugeHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  gaugeTitleWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  gaugeTitle: {
    fontSize: 10,
    fontWeight: '800',
    color: '#0369A1',
    letterSpacing: 0.5,
  },
  tempBadge: {
    backgroundColor: '#0284C7',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
  },
  tempBadgeText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '900',
  },
  barWrap: {
    marginVertical: 4,
  },
  barScale: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 3,
  },
  scaleLabel: {
    fontSize: 9,
    color: COLORS.textMuted,
  },
  scaleSafeLabel: {
    fontSize: 9,
    color: '#0284C7',
    fontWeight: '700',
  },
  gaugeTrack: {
    height: 10,
    backgroundColor: '#E0F2FE',
    borderRadius: 5,
    position: 'relative',
    overflow: 'visible',
  },
  safeZone: {
    position: 'absolute',
    left: '30%',
    width: '40%',
    height: '100%',
    backgroundColor: '#38BDF8',
    borderRadius: 5,
  },
  needle: {
    position: 'absolute',
    top: -4,
    alignItems: 'center',
    width: 14,
    marginLeft: -7,
  },
  needleDot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: COLORS.primary,
  },
  gaugeFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 8,
  },
  gaugeFooterText: {
    fontSize: 10,
    color: '#0369A1',
    fontWeight: '600',
  },

  // Driver Row
  driverRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: '#F5F0E6',
  },
  driverInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  driverTextCol: {
    gap: 2,
  },
  driverName: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  driverPhone: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  callBtn: {
    backgroundColor: COLORS.primary,
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },

  // Timeline
  timelineCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  cardHeading: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 12,
    letterSpacing: 0.5,
  },
  timelineItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 12,
    gap: 10,
  },
  stepDot: {
    width: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: COLORS.accent,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 2,
  },
  stepContent: {
    flex: 1,
  },
  stepName: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  stepTime: {
    fontSize: 10,
    color: COLORS.textMuted,
    marginTop: 1,
  },

  // PoD Card
  podCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
    marginBottom: 14,
  },
  podHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 12,
  },
  podTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  podGrid: {
    flexDirection: 'row',
    gap: 10,
    marginBottom: 12,
  },
  podCol: {
    flex: 1,
  },
  podLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginBottom: 6,
  },
  podImage: {
    width: '100%',
    height: 100,
    borderRadius: 8,
    backgroundColor: '#EAE5DB',
  },
  podDetailsBox: {
    backgroundColor: COLORS.background,
    padding: 10,
    borderRadius: 8,
    gap: 4,
    marginBottom: 14,
  },
  podDetailText: {
    fontSize: 11,
    color: COLORS.textSecondary,
    lineHeight: 16,
  },
  bold: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  confirmBtn: {
    marginTop: 2,
  },
});
