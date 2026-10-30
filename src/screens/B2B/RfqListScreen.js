import React, { useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';

const MOCK_RFQS = [
  {
    id: 'rfq-001',
    rfqNumber: 'RFQ-2026-0042',
    title: 'Đặt 350 Hộp Quà Hoàng Triều Tri Ân Đối Tác VIP',
    targetQuantity: 350,
    budgetRange: '600.000 ₫ – 850.000 ₫ / hộp',
    deliveryDate: '10/08/2026',
    status: 'Open',
    statusLabel: 'Đang mở nhận thầu',
    statusColor: '#D46B08',
    bidsCount: 3,
    deadline: 'Còn 3 ngày',
  },
  {
    id: 'rfq-002',
    rfqNumber: 'RFQ-2026-0018',
    title: '500 Hộp Bánh Dẻo & Bánh Nướng Nhân Thập Cẩm B2B',
    targetQuantity: 500,
    budgetRange: '450.000 ₫ – 600.000 ₫ / hộp',
    deliveryDate: '05/08/2026',
    status: 'Awarded',
    statusLabel: 'Đã chốt xưởng trúng thầu',
    statusColor: '#389E0D',
    bidsCount: 4,
    deadline: 'Đã hoàn tất',
  },
];

export default function RfqListScreen({ navigation }) {
  const [rfqs] = useState(MOCK_RFQS);

  return (
    <View style={styles.container}>
      <AppHeader
        title="Đấu Thầu RFQ Của Tôi"
        subtitle="Quản lý các gói thầu & So sánh báo giá"
        showBack={true}
        onBack={() => navigation.goBack()}
        rightIcon="add-outline"
        onRightPress={() => navigation.navigate('CreateRfq')}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.topActionBanner}>
          <View style={styles.bannerInfo}>
            <Text style={styles.bannerTitle}>Cần mua số lượng trên 200 hộp?</Text>
            <Text style={styles.bannerSub}>Mở thầu để các nghệ nhân trực tiếp chào giá cạnh tranh nhất.</Text>
          </View>
          <TouchableOpacity
            style={styles.newRfqBtn}
            onPress={() => navigation.navigate('CreateRfq')}
          >
            <Ionicons name="add" size={16} color="#FFF" />
            <Text style={styles.newRfqBtnText}>Tạo Mới</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.listHeading}>Danh Sách Gói Thầu ({rfqs.length})</Text>

        {rfqs.map((rfq) => (
          <TouchableOpacity
            key={rfq.id}
            style={styles.rfqCard}
            onPress={() => navigation.navigate('RfqDetailBidding', { rfq })}
            activeOpacity={0.85}
          >
            <View style={styles.cardHeader}>
              <Text style={styles.rfqNum}>{rfq.rfqNumber}</Text>
              <View
                style={[
                  styles.statusTag,
                  { backgroundColor: `${rfq.statusColor}15` },
                ]}
              >
                <Text style={[styles.statusText, { color: rfq.statusColor }]}>
                  {rfq.statusLabel}
                </Text>
              </View>
            </View>

            <Text style={styles.title}>{rfq.title}</Text>

            <View style={styles.detailGrid}>
              <View style={styles.detailItem}>
                <Text style={styles.detailLabel}>Số lượng đặt:</Text>
                <Text style={styles.detailVal}>{rfq.targetQuantity} hộp</Text>
              </View>
              <View style={styles.detailItem}>
                <Text style={styles.detailLabel}>Hạn chốt:</Text>
                <Text style={styles.detailVal}>{rfq.deadline}</Text>
              </View>
              <View style={[styles.detailItem, { width: '100%', marginTop: 6 }]}>
                <Text style={styles.detailLabel}>Khoảng ngân sách:</Text>
                <Text style={[styles.detailVal, { color: COLORS.primary }]}>
                  {rfq.budgetRange}
                </Text>
              </View>
            </View>

            <View style={styles.cardFooter}>
              <View style={styles.bidBadge}>
                <Ionicons name="documents-outline" size={14} color={COLORS.accent} />
                <Text style={styles.bidCountText}>
                  {rfq.bidsCount} xưởng đã nộp Báo Giá (Bid)
                </Text>
              </View>
              <View style={styles.compareBtn}>
                <Text style={styles.compareText}>So sánh giá</Text>
                <Ionicons name="chevron-forward" size={14} color={COLORS.primary} />
              </View>
            </View>
          </TouchableOpacity>
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
  topActionBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 12,
    padding: 14,
    marginBottom: 16,
  },
  bannerInfo: {
    flex: 1,
    marginRight: 10,
  },
  bannerTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#873800',
  },
  bannerSub: {
    fontSize: 11,
    color: '#614700',
    marginTop: 2,
    lineHeight: 16,
  },
  newRfqBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.primary,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
  },
  newRfqBtnText: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '700',
    marginLeft: 4,
  },
  listHeading: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 12,
  },
  rfqCard: {
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
    marginBottom: 6,
  },
  rfqNum: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primary,
  },
  statusTag: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  statusText: {
    fontSize: 11,
    fontWeight: '700',
  },
  title: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    lineHeight: 20,
    marginBottom: 10,
  },
  detailGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    backgroundColor: '#FAFAF8',
    padding: 10,
    borderRadius: 8,
    marginBottom: 10,
  },
  detailItem: {
    width: '50%',
  },
  detailLabel: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  detailVal: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginTop: 2,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
  bidBadge: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  bidCountText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.accent,
    marginLeft: 6,
  },
  compareBtn: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  compareText: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.primary,
    marginRight: 2,
  },
});

