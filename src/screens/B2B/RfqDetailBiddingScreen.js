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
import AntdSteps from '../../components/antd/AntdSteps';
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
  const rfq = route?.params?.rfq || {
    id: 'rfq-001',
    rfqNumber: 'RFQ-2026-0042',
    title: 'Đặt 350 Hộp Quà Hoàng Triều Tri Ân Đối Tác VIP',
    targetQuantity: 350,
    deliveryDate: '10/08/2026',
  };
  const [bids] = useState(MOCK_BIDS);
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
                    text: 'Chuyển sang Ký Hợp Đồng Ngay',
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
        title="So Sánh Báo Giá Đấu Thầu"
        subtitle={rfq.rfqNumber || 'RFQ-2026-0042'}
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Ant Design Steps: Bước 2 */}
        <View style={styles.stepsCard}>
          <AntdSteps
            current={1}
            items={[
              { title: '1. Nhu Cầu', desc: 'Đã hoàn tất' },
              { title: '2. Báo Giá', desc: 'So sánh & Chọn' },
              { title: '3. Ký HĐ', desc: 'Ký số & Cọc M1' },
            ]}
          />
        </View>

        {/* RFQ Brief Info */}
        <View style={styles.briefCard}>
          <Text style={styles.briefTitle}>{rfq.title}</Text>
          <View style={styles.briefMeta}>
            <View style={styles.metaCol}>
              <Text style={styles.metaLabel}>Số lượng đặt:</Text>
              <Text style={styles.metaVal}>{rfq.targetQuantity} hộp</Text>
            </View>
            <View style={styles.metaCol}>
              <Text style={styles.metaLabel}>Hạn giao hàng:</Text>
              <Text style={styles.metaVal}>{rfq.deliveryDate}</Text>
            </View>
            <View style={styles.metaCol}>
              <Text style={styles.metaLabel}>Số xưởng nộp Bid:</Text>
              <Text style={styles.metaHighlight}>{bids.length} báo giá</Text>
            </View>
          </View>
        </View>

        {/* Bids Section Heading */}
        <View style={styles.sectionHeader}>
          <Ionicons name="git-compare" size={18} color={COLORS.primary} />
          <Text style={styles.sectionTitle}>Danh Sách Báo Giá Side-by-Side</Text>
        </View>

        {/* Lucian Comparison Cards */}
        {bids.map((bid) => (
          <View
            key={bid.id}
            style={[
              styles.bidCard,
              bid.isRecommended && styles.bidCardRecommended,
            ]}
          >
            {bid.isRecommended && (
              <View style={styles.ribbon}>
                <Ionicons name="sparkles" size={12} color="#FFFFFF" />
                <Text style={styles.ribbonText}>👑 ĐỀ XUẤT TỐI ƯU · ĐIỂM TÍN NHIỆM 98/100</Text>
              </View>
            )}

            <View style={styles.cardHeader}>
              <View style={styles.supplierWrap}>
                <Text style={styles.supplierName}>{bid.supplierName}</Text>
                <View style={styles.scoreBadge}>
                  <Ionicons name="shield-checkmark" size={12} color={COLORS.primary} />
                  <Text style={styles.scoreText}>{bid.badge} ({bid.reputationScore}đ)</Text>
                </View>
              </View>
              <Text style={styles.bidNumber}>{bid.bidNumber}</Text>
            </View>

            {/* Price Box */}
            <View style={styles.priceContainer}>
              <View>
                <Text style={styles.priceSub}>Đơn giá sản xuất:</Text>
                <Text style={styles.unitPriceText}>{formatVND(bid.unitPrice)}/hộp</Text>
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Text style={styles.priceSub}>Tổng gói thầu:</Text>
                <Text style={styles.totalPriceText}>{formatVND(bid.totalPrice)}</Text>
              </View>
            </View>

            {/* Terms Details */}
            <View style={styles.detailsList}>
              <View style={styles.detailItem}>
                <Ionicons name="time-outline" size={14} color={COLORS.accent} />
                <Text style={styles.detailText}>
                  Thời gian sản xuất: <Text style={styles.bold}>{bid.deliveryDays}</Text>
                </Text>
              </View>
              <View style={styles.detailItem}>
                <Ionicons name="gift-outline" size={14} color={COLORS.accent} />
                <Text style={styles.detailText}>
                  Gia công hộp: <Text style={styles.bold}>{bid.customPackagingNotes}</Text>
                </Text>
              </View>
              <View style={styles.detailItem}>
                <Ionicons name="shield-outline" size={14} color={COLORS.accent} />
                <Text style={styles.detailText}>
                  Cam kết bảo lãnh: <Text style={styles.bold}>{bid.penaltyTerms}</Text>
                </Text>
              </View>
            </View>

            {/* Action Accept Button */}
            <TouchableOpacity
              style={[
                styles.acceptBtn,
                bid.isRecommended ? styles.acceptBtnPrimary : styles.acceptBtnOutline,
              ]}
              onPress={() => handleAcceptBid(bid)}
              disabled={loadingBidId === bid.id}
            >
              <Ionicons
                name="checkmark-circle"
                size={18}
                color={bid.isRecommended ? '#FFFFFF' : COLORS.primary}
              />
              <Text
                style={[
                  styles.acceptBtnText,
                  bid.isRecommended ? styles.acceptBtnTextPrimary : styles.acceptBtnTextOutline,
                ]}
              >
                {loadingBidId === bid.id ? 'Đang kích hoạt...' : 'Chấp Thuận & Ký Hợp Đồng e-Contract'}
              </Text>
            </TouchableOpacity>
          </View>
        ))}

        <View style={{ height: 40 }} />
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
  stepsCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 12,
  },
  briefCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 14,
    borderLeftWidth: 4,
    borderLeftColor: COLORS.primary,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  briefTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 10,
  },
  briefMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: COLORS.background,
    padding: 10,
    borderRadius: 8,
  },
  metaCol: {
    alignItems: 'center',
  },
  metaLabel: {
    fontSize: 10,
    color: COLORS.textSecondary,
    marginBottom: 2,
  },
  metaVal: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  metaHighlight: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primary,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  bidCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 5,
    elevation: 2,
  },
  bidCardRecommended: {
    borderColor: COLORS.accent,
    borderWidth: 1.5,
    backgroundColor: '#FFFDF9',
  },
  ribbon: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: COLORS.accent,
    marginHorizontal: -16,
    marginTop: -16,
    paddingVertical: 5,
    paddingHorizontal: 12,
    borderTopLeftRadius: 10,
    borderTopRightRadius: 10,
    marginBottom: 12,
  },
  ribbonText: {
    color: '#FFF',
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  supplierWrap: {
    flex: 1,
  },
  supplierName: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 4,
  },
  scoreBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFF1F0',
    alignSelf: 'flex-start',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  scoreText: {
    fontSize: 10,
    fontWeight: '700',
    color: COLORS.primary,
  },
  bidNumber: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  priceContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: COLORS.background,
    padding: 12,
    borderRadius: 8,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#EFEAE1',
  },
  priceSub: {
    fontSize: 10,
    color: COLORS.textSecondary,
    marginBottom: 2,
  },
  unitPriceText: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.primary,
  },
  totalPriceText: {
    fontSize: 16,
    fontWeight: '900',
    color: COLORS.primaryDark,
  },
  detailsList: {
    gap: 8,
    marginBottom: 14,
  },
  detailItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 6,
  },
  detailText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    flex: 1,
    lineHeight: 17,
  },
  bold: {
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  acceptBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8,
    paddingVertical: 12,
    gap: 6,
  },
  acceptBtnPrimary: {
    backgroundColor: COLORS.primary,
  },
  acceptBtnOutline: {
    borderWidth: 1.5,
    borderColor: COLORS.primary,
    backgroundColor: COLORS.surface,
  },
  acceptBtnText: {
    fontSize: 13,
    fontWeight: '700',
  },
  acceptBtnTextPrimary: {
    color: '#FFFFFF',
  },
  acceptBtnTextOutline: {
    color: COLORS.primary,
  },
});
