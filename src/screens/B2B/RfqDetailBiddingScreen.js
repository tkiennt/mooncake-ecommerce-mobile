import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import CustomButton from '../../components/common/CustomButton';
import { apiClient } from '../../api/apiClient';
import { ENDPOINTS } from '../../api/endpoints';

const MOCK_BIDS = [
  {
    id: 'bid-101',
    bidNumber: 'BID-2026-0812',
    supplierName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
    reputationScore: 98,
    badge: 'Đối Tác Vàng',
    unitPrice: 680000,
    totalPrice: 238000000,
    deliveryDays: '12 ngày kể từ khi ký HĐ',
    validityDays: 'Hết hạn sau 5 ngày',
    customPackagingNotes: 'Miễn phí in ép kim logo công ty 2 màu, tặng kèm 350 thiệp chúc mừng dập nổi.',
    penaltyTerms: 'Phạt 2% mỗi ngày trễ hạn, tối đa 12% giá trị hợp đồng.',
    isRecommended: true,
  },
  {
    id: 'bid-102',
    bidNumber: 'BID-2026-0814',
    supplierName: 'Tiệm Bánh Thủ Công An Lạc',
    reputationScore: 92,
    badge: 'Xưởng Uy Tín',
    unitPrice: 650000,
    totalPrice: 227500000,
    deliveryDays: '15 ngày kể từ khi ký HĐ',
    validityDays: 'Hết hạn sau 3 ngày',
    customPackagingNotes: 'Hộp nắp gập cao cấp, logo in lụa kim tuyến.',
    penaltyTerms: 'Phạt 1.5% mỗi ngày trễ hạn.',
    isRecommended: false,
  },
  {
    id: 'bid-103',
    bidNumber: 'BID-2026-0819',
    supplierName: 'Bảo Ngọc Đường',
    reputationScore: 88,
    badge: 'Xưởng Uy Tín',
    unitPrice: 720000,
    totalPrice: 252000000,
    deliveryDays: '10 ngày kể từ khi ký HĐ',
    validityDays: 'Hết hạn sau 7 ngày',
    customPackagingNotes: 'Hộp gỗ sơn mài thủ công, logo khắc laser tinh xảo.',
    penaltyTerms: 'Bồi thường 100% nếu sản phẩm lỗi kỹ thuật hoặc trễ hạn.',
    isRecommended: false,
  },
];

export default function RfqDetailBiddingScreen({ route, navigation }) {
  const { rfq } = route.params;
  const [bids, setBids] = useState(MOCK_BIDS);
  const [loadingBidId, setLoadingBidId] = useState(null);

  const formatVND = (num) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(num);
  };

  const handleAcceptBid = (bid) => {
    Alert.alert(
      'Xác nhận chọn Báo Giá?',
      `Bạn đang chọn báo giá của [${bid.supplierName}] với tổng giá trị ${formatVND(bid.totalPrice)}.\n\nSau khi chấp thuận, hệ thống sẽ tự động kích hoạt Dự thảo Hợp đồng điện tử e-Contract.`,
      [
        { text: 'Suy nghĩ thêm', style: 'cancel' },
        {
          text: 'Chấp Nhận & Tạo HĐ',
          onPress: async () => {
            setLoadingBidId(bid.id);
            try {
              // Gọi API backend
              await apiClient.post(ENDPOINTS.ACCEPT_BID(rfq.id, bid.id));
            } catch (e) {
              // demo fallback
            } finally {
              setLoadingBidId(null);
              Alert.alert(
                'Đã Chọn Nhà Cung Cấp Thành Công!',
                `Dự thảo Hợp đồng số HĐ-2026-0812 đã được tự động khởi tạo. Vui lòng ký số bằng OTP để kích hoạt mốc đặt cọc.`,
                [
                  {
                    text: 'Xem & Ký Hợp Đồng Ngay',
                    onPress: () =>
                      navigation.navigate('ContractSign', {
                        bid,
                        rfq,
                        contractNumber: 'HĐ-2026-0812',
                      }),
                  },
                ]
              );
            }
          },
        },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="So Sánh Báo Giá Thầu"
        subtitle={rfq.rfqNumber}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        {/* RFQ Summary Card */}
        <View style={styles.rfqCard}>
          <Text style={styles.rfqTitle}>{rfq.title}</Text>
          <View style={styles.rfqMetaRow}>
            <Text style={styles.rfqMeta}>Số lượng: <Text style={styles.bold}>{rfq.targetQuantity} hộp</Text></Text>
            <Text style={styles.rfqMeta}>Cần giao: <Text style={styles.bold}>{rfq.deliveryDate}</Text></Text>
          </View>
        </View>

        <Text style={styles.bidsHeading}>
          Có <Text style={styles.highlight}>{bids.length} xưởng</Text> nộp báo giá cạnh tranh
        </Text>

        {bids.map((bid) => (
          <View
            key={bid.id}
            style={[styles.bidCard, bid.isRecommended && styles.recommendedCard]}
          >
            {bid.isRecommended && (
              <View style={styles.recBadge}>
                <Ionicons name="sparkles" size={12} color="#FFF" />
                <Text style={styles.recBadgeText}>ĐỀ XUẤT TỐI ƯU NHẤT</Text>
              </View>
            )}

            <View style={styles.bidHeader}>
              <View style={styles.supplierCol}>
                <Text style={styles.supplierName}>{bid.supplierName}</Text>
                <View style={styles.scoreRow}>
                  <View style={styles.badgeTag}>
                    <Text style={styles.badgeText}>{bid.badge}</Text>
                  </View>
                  <Text style={styles.scoreText}>Điểm uy tín: {bid.reputationScore}/100</Text>
                </View>
              </View>
              <Text style={styles.bidNumber}>{bid.bidNumber}</Text>
            </View>

            <View style={styles.pricingBox}>
              <View>
                <Text style={styles.priceSub}>Đơn giá chào thầu</Text>
                <Text style={styles.unitPrice}>{formatVND(bid.unitPrice)} <Text style={styles.perBox}>/hộp</Text></Text>
              </View>
              <View style={styles.totalBox}>
                <Text style={styles.priceSub}>Tổng giá trị thầu</Text>
                <Text style={styles.totalPrice}>{formatVND(bid.totalPrice)}</Text>
              </View>
            </View>

            <View style={styles.bidDetails}>
              <View style={styles.detailRow}>
                <Ionicons name="time-outline" size={16} color={COLORS.textSecondary} />
                <Text style={styles.detailText}>Thời gian giao: <Text style={styles.bold}>{bid.deliveryDays}</Text></Text>
              </View>
              <View style={styles.detailRow}>
                <Ionicons name="gift-outline" size={16} color={COLORS.textSecondary} />
                <Text style={styles.detailText}>Đóng gói & In ấn: {bid.customPackagingNotes}</Text>
              </View>
              <View style={styles.detailRow}>
                <Ionicons name="shield-outline" size={16} color={COLORS.textSecondary} />
                <Text style={styles.detailText}>Chế tài phạt: {bid.penaltyTerms}</Text>
              </View>
            </View>

            <CustomButton
              title="Chấp Thuận Báo Giá Này"
              icon="✓"
              onPress={() => handleAcceptBid(bid)}
              loading={loadingBidId === bid.id}
              variant={bid.isRecommended ? 'primary' : 'outline'}
              size="medium"
              style={styles.acceptBtn}
            />
          </View>
        ))}
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
  rfqCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 14,
    marginBottom: 16,
  },
  rfqTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    lineHeight: 20,
    marginBottom: 8,
  },
  rfqMetaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  rfqMeta: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  bold: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  bidsHeading: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 12,
  },
  highlight: {
    color: COLORS.primary,
  },
  bidCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
    position: 'relative',
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  recommendedCard: {
    borderColor: COLORS.accent,
    borderWidth: 1.5,
  },
  recBadge: {
    position: 'absolute',
    top: -10,
    left: 14,
    backgroundColor: COLORS.accent,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 10,
  },
  recBadgeText: {
    color: '#FFF',
    fontSize: 10,
    fontWeight: '800',
    marginLeft: 4,
  },
  bidHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
    marginBottom: 12,
  },
  supplierCol: {
    flex: 1,
  },
  supplierName: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.textPrimary,
  },
  scoreRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  badgeTag: {
    backgroundColor: 'rgba(212, 136, 6, 0.12)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    marginRight: 6,
  },
  badgeText: {
    color: COLORS.accent,
    fontSize: 10,
    fontWeight: '700',
  },
  scoreText: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  bidNumber: {
    fontSize: 11,
    color: COLORS.textMuted,
    fontWeight: '600',
  },
  pricingBox: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#FAFAF8',
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
  },
  priceSub: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  unitPrice: {
    fontSize: 17,
    fontWeight: '800',
    color: COLORS.primary,
    marginTop: 2,
  },
  perBox: {
    fontSize: 12,
    fontWeight: '500',
    color: COLORS.textMuted,
  },
  totalBox: {
    alignItems: 'flex-end',
  },
  totalPrice: {
    fontSize: 17,
    fontWeight: '800',
    color: COLORS.textPrimary,
    marginTop: 2,
  },
  bidDetails: {
    marginBottom: 14,
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 6,
  },
  detailText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginLeft: 8,
    flex: 1,
    lineHeight: 18,
  },
  acceptBtn: {
    width: '100%',
  },
});

