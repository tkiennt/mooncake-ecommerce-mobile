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
      { name: 'M1: Đặt cọc 30%', amount: 71400000, status: 'Pending', dueDate: '05/08/2026', isMandatory: true, desc: 'Kích hoạt hợp đồng và xuất hóa đơn VAT đợt 1' },
      { name: 'M2: Giao hàng đợt 1 (50%)', amount: 119000000, status: 'Upcoming', dueDate: '15/08/2026', desc: 'Vận chuyển xe lạnh chuyên dụng kiểm định PoD' },
      { name: 'M3: Nghiệm thu & Thanh toán 20%', amount: 47600000, status: 'Upcoming', dueDate: '25/08/2026', desc: 'Hoàn tất giải ngân ký quỹ SafeTrade' },
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
      { name: 'M1: Đặt cọc 30%', amount: 54000000, status: 'Completed', dueDate: '18/10/2026', desc: 'Đã thanh toán qua Ký quỹ Ngân hàng Escrow' },
      { name: 'M2: Giao hàng đợt 1 (50%)', amount: 90000000, status: 'InProgress', dueDate: '02/11/2026', desc: 'Đang đóng gói và kiểm định chất lượng bao bì' },
      { name: 'M3: Nghiệm thu 20%', amount: 36000000, status: 'Upcoming', dueDate: '15/11/2026', desc: 'Nghiệm thu thực tế tại địa điểm giao nhận' },
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
      `Hợp đồng: ${contract.contractNumber}\nSố tiền cọc: ${formatVND(milestone.amount)} (30% giá trị hợp đồng).\n\nKhoản thanh toán được bảo chứng an toàn qua SafeTrade Escrow / VNPay B2B. Sau khi hoàn tất, xưởng sẽ lập tức đưa vào dây chuyền sản xuất.`,
      [
        { text: 'Để sau', style: 'cancel' },
        {
          text: 'Xác Nhận Thanh Toán Ký Quỹ',
          onPress: () => {
            Alert.alert(
              'Giao Dịch Đặt Cọc Thành Công!',
              'Hệ thống đã ghi nhận tiền cọc M1 vào tài khoản SafeTrade Escrow và chuyển trạng thái hợp đồng sang "Active - Đang sản xuất".'
            );
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

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {contracts.map((contract) => (
          <View key={contract.id} style={styles.contractCard}>
            {/* Header info */}
            <View style={styles.cardHeader}>
              <View>
                <Text style={styles.contractNumber}>{contract.contractNumber}</Text>
                <Text style={styles.supplierName}>{contract.supplierName}</Text>
              </View>
              <View style={[styles.statusBadge, { backgroundColor: contract.statusColor + '15' }]}>
                <Text style={[styles.statusText, { color: contract.statusColor }]}>
                  {contract.statusLabel}
                </Text>
              </View>
            </View>

            <View style={styles.valueRow}>
              <Text style={styles.valueLabel}>Tổng giá trị hợp đồng:</Text>
              <Text style={styles.valueText}>{formatVND(contract.totalValue)}</Text>
            </View>

            {/* Ant Design Timeline Milestones */}
            <View style={styles.timelineSection}>
              <View style={styles.timelineHeader}>
                <Ionicons name="git-network-outline" size={16} color={COLORS.primary} />
                <Text style={styles.timelineTitle}>Lộ Trình Giải Ngân & Milestones</Text>
              </View>

              <View style={styles.timelineList}>
                {contract.milestones.map((m, idx) => {
                  const isCompleted = m.status === 'Completed';
                  const isPending = m.status === 'Pending';
                  const isLast = idx === contract.milestones.length - 1;

                  return (
                    <View key={idx} style={styles.timelineItem}>
                      {/* Left: Indicator & connecting line */}
                      <View style={styles.indicatorCol}>
                        <View
                          style={[
                            styles.timelineDot,
                            isCompleted && styles.dotCompleted,
                            isPending && styles.dotPending,
                          ]}
                        >
                          {isCompleted ? (
                            <Ionicons name="checkmark" size={10} color="#FFFFFF" />
                          ) : (
                            <View style={styles.dotCenter} />
                          )}
                        </View>
                        {!isLast && <View style={[styles.timelineLine, isCompleted && styles.lineCompleted]} />}
                      </View>

                      {/* Right: Content */}
                      <View style={styles.contentCol}>
                        <View style={styles.milestoneTop}>
                          <Text style={[styles.milestoneName, isPending && styles.milestoneNamePending]}>
                            {m.name}
                          </Text>
                          <Text style={styles.milestoneAmount}>{formatVND(m.amount)}</Text>
                        </View>

                        <Text style={styles.milestoneDesc}>{m.desc}</Text>
                        <Text style={styles.milestoneDueDate}>Hạn giải ngân: {m.dueDate}</Text>

                        {isPending && (
                          <TouchableOpacity
                            style={styles.payBtn}
                            onPress={() => handlePayDeposit(contract, m)}
                          >
                            <Ionicons name="card-outline" size={14} color="#FFFFFF" />
                            <Text style={styles.payBtnText}>Thanh Toán Đặt Cọc M1 (30%)</Text>
                          </TouchableOpacity>
                        )}
                      </View>
                    </View>
                  );
                })}
              </View>
            </View>

            {/* Bottom Actions */}
            <View style={styles.cardFooter}>
              <View style={styles.signedInfo}>
                <Ionicons name="shield-checkmark" size={14} color="#059669" />
                <Text style={styles.signedText}>Ký số OTP ngày {contract.signedDate}</Text>
              </View>
              <TouchableOpacity
                style={styles.pdfBtn}
                onPress={() => Alert.alert('Tải Hợp Đồng', 'Đang kết xuất bản PDF hợp đồng có đóng dấu thời gian số...')}
              >
                <Ionicons name="download-outline" size={14} color={COLORS.primary} />
                <Text style={styles.pdfBtnText}>Tải file PDF</Text>
              </TouchableOpacity>
            </View>
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
  contractCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    borderBottomWidth: 1,
    borderBottomColor: '#F5F0E6',
    paddingBottom: 10,
    marginBottom: 10,
  },
  contractNumber: {
    fontSize: 15,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  supplierName: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  statusBadge: {
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
    marginBottom: 14,
  },
  valueLabel: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  valueText: {
    fontSize: 16,
    fontWeight: '900',
    color: COLORS.primary,
  },
  timelineSection: {
    backgroundColor: COLORS.background,
    borderRadius: 10,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#EFE7DA',
  },
  timelineHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 12,
  },
  timelineTitle: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
    letterSpacing: 0.5,
  },
  timelineList: {
    paddingLeft: 4,
  },
  timelineItem: {
    flexDirection: 'row',
    marginBottom: 12,
  },
  indicatorCol: {
    alignItems: 'center',
    width: 20,
    marginRight: 10,
  },
  timelineDot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: COLORS.surface,
    borderWidth: 2,
    borderColor: COLORS.borderDark,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 2,
  },
  dotCompleted: {
    backgroundColor: COLORS.accent, // Imperial Gold
    borderColor: '#E8D2A3',
  },
  dotPending: {
    backgroundColor: COLORS.primary, // Crimson Luxury
    borderColor: '#FFCCD0',
  },
  dotCenter: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: COLORS.textMuted,
  },
  timelineLine: {
    width: 2,
    flex: 1,
    backgroundColor: COLORS.border,
    marginVertical: 2,
  },
  lineCompleted: {
    backgroundColor: COLORS.accent,
  },
  contentCol: {
    flex: 1,
  },
  milestoneTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  milestoneName: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  milestoneNamePending: {
    color: COLORS.primary,
  },
  milestoneAmount: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  milestoneDesc: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  milestoneDueDate: {
    fontSize: 10,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  payBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: COLORS.primary,
    borderRadius: 6,
    paddingVertical: 7,
    paddingHorizontal: 12,
    marginTop: 8,
    alignSelf: 'flex-start',
    gap: 6,
  },
  payBtnText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F5F0E6',
  },
  signedInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  signedText: {
    fontSize: 11,
    color: '#059669',
    fontWeight: '600',
  },
  pdfBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderWidth: 1,
    borderColor: COLORS.primary,
    borderRadius: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
  },
  pdfBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.primary,
  },
});
