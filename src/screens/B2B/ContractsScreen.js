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

const MOCK_CONTRACTS = [
  {
    id: 'contract-001',
    contractNumber: 'HĐ-2026-0812',
    supplierName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
    totalValue: 238000000,
    status: 'Pending_Deposit',
    statusLabel: 'Chờ thanh toán cọc M1',
    statusColor: '#D46B08',
    signedDate: '30/10/2026',
    milestones: [
      { name: 'M1: Đặt cọc 30%', amount: 71400000, status: 'Pending', dueDate: '05/08/2026', isMandatory: true },
      { name: 'M2: Giao hàng đợt 1 (50%)', amount: 119000000, status: 'Upcoming', dueDate: '15/08/2026' },
      { name: 'M3: Nghiệm thu & Thanh toán 20%', amount: 47600000, status: 'Upcoming', dueDate: '25/08/2026' },
    ],
  },
  {
    id: 'contract-002',
    contractNumber: 'HĐ-2026-0640',
    supplierName: 'Tiệm Bánh Thủ Công An Lạc',
    totalValue: 180000000,
    status: 'Active',
    statusLabel: 'Đang sản xuất',
    statusColor: '#0958D9',
    signedDate: '15/10/2026',
    milestones: [
      { name: 'M1: Đặt cọc 30%', amount: 54000000, status: 'Completed', dueDate: '18/10/2026' },
      { name: 'M2: Giao hàng đợt 1 (50%)', amount: 90000000, status: 'InProgress', dueDate: '02/11/2026' },
      { name: 'M3: Nghiệm thu 20%', amount: 36000000, status: 'Upcoming', dueDate: '15/11/2026' },
    ],
  },
];

export default function ContractsScreen({ navigation }) {
  const [contracts] = useState(MOCK_CONTRACTS);

  const formatVND = (num) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(num);
  };

  const handlePayDeposit = (contract, milestone) => {
    Alert.alert(
      'Thanh Toán Đặt Cọc M1',
      `Số tiền cọc: ${formatVND(milestone.amount)} (30% giá trị hợp đồng).\n\nSau khi thanh toán qua SafeTrade Escrow / VNPay, hợp đồng sẽ chính thức kích hoạt chuyển sang trạng thái Active để xưởng làm bánh.`,
      [
        { text: 'Hủy', style: 'cancel' },
        {
          text: 'Thanh Toán Ngay',
          onPress: () => {
            Alert.alert('Thành công', 'Đã ghi nhận giao dịch đặt cọc M1 qua cổng thanh toán!');
          },
        },
      ]
    );
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Hợp Đồng Điện Tử (e-Contract)"
        subtitle="Quản lý cam kết pháp lý & Tiến độ Milestone"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.noticeCard}>
          <Ionicons name="shield-checkmark" size={20} color={COLORS.accent} />
          <Text style={styles.noticeText}>
            Hợp đồng điện tử trên Nguyệt Phố B2B có giá trị pháp lý tương đương văn bản giấy theo Luật Giao dịch Điện tử, bảo vệ quyền lợi 100% người mua hàng.
          </Text>
        </View>

        {contracts.map((item) => (
          <View key={item.id} style={styles.contractCard}>
            <View style={styles.headerRow}>
              <View>
                <Text style={styles.contractNum}>{item.contractNumber}</Text>
                <Text style={styles.supplierText}>{item.supplierName}</Text>
              </View>
              <View
                style={[
                  styles.statusTag,
                  { backgroundColor: `${item.statusColor}15` },
                ]}
              >
                <Text style={[styles.statusText, { color: item.statusColor }]}>
                  {item.statusLabel}
                </Text>
              </View>
            </View>

            <View style={styles.valueRow}>
              <Text style={styles.valueLabel}>Tổng giá trị hợp đồng:</Text>
              <Text style={styles.valueNumber}>{formatVND(item.totalValue)}</Text>
            </View>

            <View style={styles.divider} />

            <Text style={styles.milestoneTitle}>
              <Ionicons name="flag-outline" size={14} color={COLORS.primary} /> Các Mốc Tiến Độ Thanh Toán:
            </Text>

            {item.milestones.map((m, idx) => (
              <View key={idx} style={styles.milestoneRow}>
                <View style={styles.mLeft}>
                  <Ionicons
                    name={
                      m.status === 'Completed'
                        ? 'checkmark-circle'
                        : m.status === 'Pending'
                        ? 'time'
                        : 'radio-button-off'
                    }
                    size={16}
                    color={
                      m.status === 'Completed'
                        ? COLORS.success
                        : m.status === 'Pending'
                        ? COLORS.warning
                        : COLORS.textMuted
                    }
                  />
                  <View style={styles.mInfo}>
                    <Text style={styles.mName}>{m.name}</Text>
                    <Text style={styles.mDue}>Hạn: {m.dueDate}</Text>
                  </View>
                </View>

                <View style={styles.mRight}>
                  <Text style={styles.mAmount}>{formatVND(m.amount)}</Text>
                  {m.status === 'Pending' && (
                    <TouchableOpacity
                      style={styles.payBtn}
                      onPress={() => handlePayDeposit(item, m)}
                    >
                      <Text style={styles.payBtnText}>Đặt cọc ngay</Text>
                    </TouchableOpacity>
                  )}
                </View>
              </View>
            ))}

            <View style={styles.cardActions}>
              <TouchableOpacity
                style={styles.actionBtn}
                onPress={() =>
                  Alert.alert('PDF Hợp Đồng', 'Đang tải bản PDF hợp đồng có chữ ký số điện tử...')
                }
              >
                <Ionicons name="document-text-outline" size={16} color={COLORS.primary} />
                <Text style={styles.actionBtnText}>Xem File PDF Hợp Đồng</Text>
              </TouchableOpacity>
            </View>
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
  noticeCard: {
    flexDirection: 'row',
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 10,
    padding: 12,
    marginBottom: 16,
  },
  noticeText: {
    flex: 1,
    marginLeft: 8,
    fontSize: 12,
    color: '#873800',
    lineHeight: 18,
  },
  contractCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  contractNum: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primary,
  },
  supplierText: {
    fontSize: 12,
    color: COLORS.textSecondary,
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
  valueRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#FAFAF8',
    padding: 10,
    borderRadius: 8,
    marginTop: 12,
  },
  valueLabel: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  valueNumber: {
    fontSize: 16,
    fontWeight: '800',
    color: COLORS.primary,
  },
  divider: {
    height: 1,
    backgroundColor: COLORS.border,
    marginVertical: 12,
  },
  milestoneTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 10,
  },
  milestoneRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#F5F3EF',
  },
  mLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  mInfo: {
    marginLeft: 8,
  },
  mName: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  mDue: {
    fontSize: 11,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  mRight: {
    alignItems: 'flex-end',
  },
  mAmount: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  payBtn: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
    marginTop: 4,
  },
  payBtnText: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: '700',
  },
  cardActions: {
    marginTop: 14,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 6,
  },
  actionBtnText: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.primary,
    marginLeft: 6,
  },
});
