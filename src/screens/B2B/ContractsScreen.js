import React, { useCallback, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Modal,
  Linking,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import AppHeader from '../../components/common/AppHeader';
import { contractService } from '../../services/api/contractService';
import { paymentService } from '../../services/api/paymentService';
import { toMobileContract } from '../../api/mappers';

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
  const [contracts, setContracts] = useState(MOCK_CONTRACTS);
  const [paying, setPaying] = useState(false);

  // GET /contracts/mine (+ milestones); the demo contracts stay only when the backend is unreachable.
  const loadContracts = useCallback(async () => {
    try {
      const list = await contractService.listMine();
      const items = Array.isArray(list) ? list : list?.items || [];
      const withMilestones = await Promise.all(items.map(async (c) => {
        const milestones = c.milestones?.length ? c.milestones : await contractService.getMilestones(c.id).catch(() => []);
        return toMobileContract(c, milestones || []);
      }));
      setContracts(withMilestones);
    } catch (error) {
      if (error?.response) setContracts([]);
    }
  }, []);
  useFocusEffect(useCallback(() => { loadContracts(); }, [loadContracts]));
  const [selectedPayTarget, setSelectedPayTarget] = useState(null);
  const [paymentMethod, setPaymentMethod] = useState('vietqr');

  const formatVND = (num) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(num);
  };

  const handleOpenPayment = (contract, milestone) => {
    setSelectedPayTarget({ contract, milestone });
  };

  const handleConfirmEscrowPayment = async () => {
    const { contract, milestone } = selectedPayTarget || {};
    if (!contract?.isFromApi) {
      setSelectedPayTarget(null);
      Alert.alert('Chế độ demo', 'Đây là hợp đồng mẫu nên không có giao dịch thật nào được tạo.');
      return;
    }
    setPaying(true);
    try {
      // POST /payments/vnpay/create-url → open the VNPay page; VNPay returns to nguyetpho://thanh-toan/ket-qua.
      const result = await paymentService.createContractVnPayUrl(contract.id, milestone.id);
      setSelectedPayTarget(null);
      if (!result?.paymentUrl) throw new Error('Không nhận được đường dẫn thanh toán.');
      await Linking.openURL(result.paymentUrl);
    } catch (error) {
      Alert.alert('Không tạo được thanh toán', error?.response?.data?.message || error?.message || 'Vui lòng thử lại.');
    } finally {
      setPaying(false);
    }
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Hợp đồng"
        subtitle="Ký kết, đặt cọc và tiến độ từng mốc"
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
                            onPress={() => handleOpenPayment(contract, m)}
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
              {contract.needsCustomerSignature ? (
                <Text style={styles.signedText}>Xưởng đã gửi hợp đồng · chờ bạn ký</Text>
              ) : (
                <View style={styles.signedInfo}>
                  <Ionicons name="shield-checkmark" size={14} color="#059669" />
                  <Text style={styles.signedText}>Đã ký ngày {contract.signedDate}</Text>
                </View>
              )}
              {contract.needsCustomerSignature && (
                <TouchableOpacity style={styles.pdfBtn} onPress={() => navigation.navigate('ContractSign', { contract })}>
                  <Ionicons name="create-outline" size={14} color={COLORS.primary} />
                  <Text style={styles.pdfBtnText}>Ký hợp đồng</Text>
                </TouchableOpacity>
              )}
            </View>
          </View>
        ))}
        <View style={{ height: 40 }} />
      </ScrollView>

      {/* RF-04: SafeTrade Escrow Payment Modal (Checklist Design Standard) */}
      <Modal
        visible={Boolean(selectedPayTarget)}
        transparent
        animationType="slide"
        onRequestClose={() => setSelectedPayTarget(null)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.paymentModal}>
            <View style={styles.sheetHandle} />

            {/* Seal & Heading */}
            <View style={styles.escrowHeader}>
              <View style={styles.escrowSeal}>
                <Ionicons name="shield-checkmark" size={26} color={COLORS.accent} />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.escrowTitle}>BẢO CHỨNG KÝ QUỸ SAFETRADE</Text>
                <Text style={styles.escrowSub}>Tiền cọc được giữ an toàn tại tài khoản trung gian ngân hàng</Text>
              </View>
            </View>

            {/* Payment Summary */}
            <View style={styles.paymentSummaryBox}>
              <View style={styles.paySummaryRow}>
                <Text style={styles.paySummaryLabel}>Hợp đồng kinh tế:</Text>
                <Text style={styles.paySummaryContract}>{selectedPayTarget?.contract?.contractNumber}</Text>
              </View>
              <View style={styles.paySummaryRow}>
                <Text style={styles.paySummaryLabel}>Mục tiêu thanh toán:</Text>
                <Text style={styles.paySummaryVal}>{selectedPayTarget?.milestone?.name}</Text>
              </View>
              <View style={styles.summaryDivider} />
              <View style={styles.paySummaryRow}>
                <Text style={styles.payTotalLabel}>Số tiền ký quỹ (30%):</Text>
                <Text style={styles.payTotalVal}>
                  {formatVND(selectedPayTarget?.milestone?.amount || 0)}
                </Text>
              </View>
            </View>

            {/* Gateway Badges Selection */}
            <Text style={styles.methodTitle}>Phương thức thanh toán bảo chứng:</Text>
            <View style={styles.methodsRow}>
              {[
                { id: 'vietqr', label: 'VietQR Doanh Nghiệp', icon: 'qr-code-outline' },
                { id: 'vnpay', label: 'VNPay B2B Gateway', icon: 'card-outline' },
                { id: 'napas', label: 'Napas 24/7 Escrow', icon: 'swap-horizontal-outline' },
              ].map((m) => {
                const isActive = paymentMethod === m.id;
                return (
                  <TouchableOpacity
                    key={m.id}
                    style={[styles.methodCard, isActive && styles.methodCardActive]}
                    onPress={() => setPaymentMethod(m.id)}
                  >
                    <Ionicons name={m.icon} size={18} color={isActive ? COLORS.primary : COLORS.textMuted} />
                    <Text style={[styles.methodCardText, isActive && styles.methodCardTextActive]}>
                      {m.label}
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            {/* Actions */}
            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => setSelectedPayTarget(null)}
              >
                <Text style={styles.cancelBtnText}>Để sau</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.confirmPayBtn}
                onPress={handleConfirmEscrowPayment}
                disabled={paying}
              >
                <Text style={styles.confirmPayText}>Xác Nhận Ký Quỹ</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
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

  // RF-04 Modal Styles
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.55)',
    justifyContent: 'flex-end',
  },
  paymentModal: {
    backgroundColor: COLORS.surface,
    borderTopLeftRadius: 22,
    borderTopRightRadius: 22,
    padding: 20,
    borderTopWidth: 2,
    borderTopColor: COLORS.accent,
  },
  sheetHandle: {
    width: 36,
    height: 4,
    backgroundColor: '#D1C8B8',
    borderRadius: 2,
    alignSelf: 'center',
    marginBottom: 14,
  },
  escrowHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 16,
  },
  escrowSeal: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: COLORS.accentGoldBg,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1.5,
    borderColor: '#E8D2A3',
  },
  escrowTitle: {
    fontSize: 13,
    fontWeight: '900',
    color: COLORS.primaryDark,
    letterSpacing: 0.5,
  },
  escrowSub: {
    fontSize: 11,
    color: COLORS.textSecondary,
    lineHeight: 16,
    marginTop: 2,
  },
  paymentSummaryBox: {
    backgroundColor: COLORS.background,
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    borderColor: '#EFE7DA',
    marginBottom: 14,
  },
  paySummaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  paySummaryLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  paySummaryContract: {
    fontSize: 11,
    fontWeight: '800',
    color: COLORS.primary,
  },
  paySummaryVal: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.textPrimary,
  },
  summaryDivider: {
    height: 1,
    backgroundColor: '#E5DAC8',
    marginVertical: 6,
  },
  payTotalLabel: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  payTotalVal: {
    fontSize: 16,
    fontWeight: '900',
    color: COLORS.primary,
  },
  methodTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 8,
  },
  methodsRow: {
    gap: 6,
    marginBottom: 16,
  },
  methodCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    borderRadius: 8,
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
    gap: 10,
  },
  methodCardActive: {
    backgroundColor: '#FFF1F0',
    borderColor: COLORS.primary,
    borderWidth: 1.5,
  },
  methodCardText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textSecondary,
  },
  methodCardTextActive: {
    color: COLORS.primary,
    fontWeight: '800',
  },
  modalActions: {
    flexDirection: 'row',
    gap: 10,
  },
  cancelBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cancelBtnText: {
    color: COLORS.textSecondary,
    fontSize: 13,
    fontWeight: '600',
  },
  confirmPayBtn: {
    flex: 2,
    backgroundColor: COLORS.primary,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  confirmPayText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '800',
  },
});
