import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  Image,
  StyleSheet,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';

export default function DeliveryPoDScreen({ route, navigation }) {
  const { orderId, orderNumber = 'ORD-2026-8711' } = route.params || {};

  const [deliveryInfo] = useState({
    trackingCode: 'VNP-COLD-2026-9941',
    carrierName: 'Nguyệt Phố Express (Đội xe lạnh chuyên dụng)',
    driverName: 'Trần Văn Mạnh',
    driverPhone: '0988 123 456',
    vehiclePlate: '29C-892.44',
    storageTemp: '20.5 °C (Tiêu chuẩn bảo quản bánh cao cấp)',
    estimatedArrival: '18/10/2026 - 16:30',
    status: 'Delivered', // InTransit | Delivered
    destination: 'Tòa nhà Landmark 81, 720A Điện Biên Phủ, P.22, Bình Thạnh, TP.HCM',
    timeline: [
      { step: 'Đã đóng gói hoàn tất tại xưởng', time: '18/10/2026 08:30', done: true },
      { step: 'Bàn giao xe lạnh chuyên dụng kiểm soát nhiệt', time: '18/10/2026 10:15', done: true },
      { step: 'Đang vận chuyển liên tỉnh', time: '18/10/2026 13:45', done: true },
      { step: 'Đã giao tới điểm nhận & Nghiệm thu PoD', time: '18/10/2026 16:30', done: true },
    ],
    podData: {
      packagePhoto: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=800&auto=format&fit=crop&q=80',
      signaturePhoto: 'https://images.unsplash.com/photo-1450133064473-71024230f91b?w=800&auto=format&fit=crop&q=80',
      deliveredAt: '18/10/2026 16:30:15 GMT+7',
      gpsLocation: '10.7951° N, 106.7218° E (Landmark 81, TP.HCM)',
      receiverName: 'Nguyễn Văn An (Kế toán trưởng ký nhận)',
    },
  });

  const handleConfirmInspection = () => {
    Alert.alert(
      'Nghiệm Thu Thành Công',
      'Bạn đã xác nhận biên bản bàn giao PoD hợp lệ. Đơn hàng chính thức hoàn tất và lưu trữ hồ sơ kế toán.'
    );
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Giám Sát Vận Chuyển & PoD"
        subtitle={orderNumber}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* Status Card */}
        <View style={styles.statusCard}>
          <View style={styles.statusHeader}>
            <View>
              <Text style={styles.codeText}>{deliveryInfo.trackingCode}</Text>
              <Text style={styles.carrierText}>{deliveryInfo.carrierName}</Text>
            </View>
            <View style={styles.statusTag}>
              <Ionicons name="checkmark-circle" size={14} color="#389E0D" />
              <Text style={styles.statusLabel}>Đã Bàn Giao</Text>
            </View>
          </View>

          <View style={styles.tempBanner}>
            <Ionicons name="snow" size={16} color={COLORS.primary} />
            <Text style={styles.tempText}>Nhiệt độ thùng xe: <Text style={styles.tempVal}>{deliveryInfo.storageTemp}</Text></Text>
          </View>

          <View style={styles.driverRow}>
            <View style={styles.driverInfo}>
              <Ionicons name="person-circle-outline" size={24} color={COLORS.accent} />
              <View style={styles.driverTextCol}>
                <Text style={styles.driverName}>{deliveryInfo.driverName} • {deliveryInfo.vehiclePlate}</Text>
                <Text style={styles.driverPhone}>SĐT: {deliveryInfo.driverPhone}</Text>
              </View>
            </View>
            <TouchableOpacity
              style={styles.callBtn}
              onPress={() => Alert.alert('Gọi điện', `Đang kết nối tới tài xế: ${deliveryInfo.driverPhone}`)}
            >
              <Ionicons name="call" size={16} color="#FFF" />
            </TouchableOpacity>
          </View>
        </View>

        {/* Timeline */}
        <View style={styles.timelineCard}>
          <Text style={styles.cardHeading}>Hành Trình Giao Hàng B2B</Text>
          {deliveryInfo.timeline.map((step, idx) => (
            <View key={idx} style={styles.timelineItem}>
              <View style={styles.timelineDotBox}>
                <View style={[styles.timelineDot, step.done && styles.timelineDotDone]} />
                {idx !== deliveryInfo.timeline.length - 1 && <View style={styles.timelineLine} />}
              </View>
              <View style={styles.timelineContent}>
                <Text style={[styles.timelineStep, step.done && styles.timelineStepDone]}>
                  {step.step}
                </Text>
                <Text style={styles.timelineTime}>{step.time}</Text>
              </View>
            </View>
          ))}
        </View>

        {/* Proof of Delivery (PoD) Section */}
        <View style={styles.podCard}>
          <View style={styles.podHeader}>
            <Ionicons name="camera" size={20} color={COLORS.accent} />
            <Text style={styles.podHeading}>Bằng Chứng Giao Nhận (Proof of Delivery)</Text>
          </View>
          <Text style={styles.podDesc}>
            Hình ảnh kiện hàng thực tế và chữ ký xác nhận tại điểm giao hàng của quý doanh nghiệp.
          </Text>

          <View style={styles.photoGrid}>
            <View style={styles.photoCol}>
              <Image source={{ uri: deliveryInfo.podData.packagePhoto }} style={styles.podImage} />
              <Text style={styles.photoCaption}>Kiện hàng nguyên niêm phong</Text>
            </View>
            <View style={styles.photoCol}>
              <Image source={{ uri: deliveryInfo.podData.signaturePhoto }} style={styles.podImage} />
              <Text style={styles.photoCaption}>Biên bản ký nhận bàn giao</Text>
            </View>
          </View>

          <View style={styles.metadataBox}>
            <View style={styles.metaRow}>
              <Ionicons name="time-outline" size={14} color={COLORS.textMuted} />
              <Text style={styles.metaText}>Thời gian: <Text style={styles.bold}>{deliveryInfo.podData.deliveredAt}</Text></Text>
            </View>
            <View style={styles.metaRow}>
              <Ionicons name="location-outline" size={14} color={COLORS.textMuted} />
              <Text style={styles.metaText}>Tọa độ GPS: <Text style={styles.bold}>{deliveryInfo.podData.gpsLocation}</Text></Text>
            </View>
            <View style={styles.metaRow}>
              <Ionicons name="person-outline" size={14} color={COLORS.textMuted} />
              <Text style={styles.metaText}>Người nhận: <Text style={styles.bold}>{deliveryInfo.podData.receiverName}</Text></Text>
            </View>
          </View>

          <CustomButton
            title="Xác Nhận Nghiệm Thu Hàng Đạt Chuẩn"
            icon="✓"
            onPress={handleConfirmInspection}
            size="medium"
            style={styles.confirmBtn}
          />
        </View>
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
  statusCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
  },
  statusHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  codeText: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.primary,
  },
  carrierText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  statusTag: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F6FFED',
    borderWidth: 1,
    borderColor: '#B7EB8F',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  statusLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: '#389E0D',
    marginLeft: 4,
  },
  tempBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(140, 21, 36, 0.05)',
    padding: 10,
    borderRadius: 8,
    marginBottom: 14,
  },
  tempText: {
    fontSize: 12,
    color: COLORS.textPrimary,
    marginLeft: 8,
  },
  tempVal: {
    fontWeight: '700',
    color: COLORS.primary,
  },
  driverRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#FAFAF8',
    padding: 10,
    borderRadius: 8,
  },
  driverInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  driverTextCol: {
    marginLeft: 8,
  },
  driverName: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  driverPhone: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  callBtn: {
    backgroundColor: COLORS.success,
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
  },
  timelineCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
  },
  cardHeading: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.textPrimary,
    marginBottom: 14,
  },
  timelineItem: {
    flexDirection: 'row',
    marginBottom: 14,
  },
  timelineDotBox: {
    alignItems: 'center',
    width: 20,
    marginRight: 10,
  },
  timelineDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: COLORS.border,
  },
  timelineDotDone: {
    backgroundColor: COLORS.primary,
  },
  timelineLine: {
    width: 2,
    flex: 1,
    backgroundColor: COLORS.border,
    marginTop: 2,
  },
  timelineContent: {
    flex: 1,
    paddingBottom: 4,
  },
  timelineStep: {
    fontSize: 13,
    color: COLORS.textSecondary,
  },
  timelineStepDone: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  timelineTime: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  podCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 20,
  },
  podHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  podHeading: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.textPrimary,
    marginLeft: 8,
  },
  podDesc: {
    fontSize: 12,
    color: COLORS.textMuted,
    marginBottom: 14,
    lineHeight: 18,
  },
  photoGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 14,
  },
  photoCol: {
    width: '48%',
  },
  podImage: {
    width: '100%',
    height: 120,
    borderRadius: 8,
    backgroundColor: '#F0ECE4',
  },
  photoCaption: {
    fontSize: 11,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: 6,
    fontWeight: '600',
  },
  metadataBox: {
    backgroundColor: '#FAFAF8',
    padding: 12,
    borderRadius: 8,
    marginBottom: 14,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },
  metaText: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginLeft: 6,
  },
  bold: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  confirmBtn: {
    width: '100%',
  },
});

