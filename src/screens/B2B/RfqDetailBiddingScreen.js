import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
  RefreshControl,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { rfqService, RFQ_STATUS, BID_STATUS, rfqErrorMessage } from '../../services/rfqService';

const formatVND = (value) => `${Number(value || 0).toLocaleString('vi-VN')} ₫`;
const formatDate = (value) => {
  if (!value) return '—';
  const d = new Date(value);
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
};

/** Compare sealed bids for one RFQ and choose a supplier (web: compare drawer + bid detail modal). */
export default function RfqDetailBiddingScreen({ route, navigation }) {
  const insets = useSafeAreaInsets();
  const [rfq, setRfq] = useState(route?.params?.rfq || null);
  const [bids, setBids] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [busyBidId, setBusyBidId] = useState(null);
  const [expanded, setExpanded] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  const rfqId = rfq?.id || route?.params?.rfqId;

  const load = useCallback(async () => {
    if (!rfqId) return;
    try {
      const [detail, nextBids, nextSuppliers] = await Promise.all([
        rfqService.get(rfqId),
        rfqService.listBids(rfqId),
        rfqService.suggestedSuppliers(rfqId).catch(() => []),
      ]);
      if (detail?.id) setRfq(detail);
      setBids(nextBids || []);
      setSuppliers(nextSuppliers || []);
    } catch (error) {
      Alert.alert('Không tải được báo giá', rfqErrorMessage(error));
    } finally {
      setLoading(false);
    }
  }, [rfqId]);

  useEffect(() => { load(); }, [load]);

  const bestBidId = useMemo(() => bids
    .filter((b) => !b.isExpired && b.status === 'Submitted')
    .sort((a, b) => Number(a.totalPrice) - Number(b.totalPrice))[0]?.id, [bids]);
  const supplierFor = (bid) => suppliers.find((s) => s.supplierProfileId === bid.supplierId);
  const awardedBid = bids.find((b) => b.id === rfq?.awardedBidId);
  const locked = rfq?.status === 'InNegotiation' || rfq?.status === 'Awarded' || rfq?.status === 'Cancelled';

  const accept = async (bid) => {
    setBusyBidId(bid.id);
    try {
      const result = await rfqService.acceptBid(rfq.id, bid.id, 'Báo giá đáp ứng tiến độ và yêu cầu kỹ thuật.');
      Alert.alert('Đã gửi lựa chọn', result?.message || 'Xưởng sẽ xác nhận; hợp đồng được tạo sau khi xưởng đồng ý.');
      await load();
    } catch (error) {
      Alert.alert('Không chọn được xưởng', rfqErrorMessage(error));
    } finally {
      setBusyBidId(null);
    }
  };

  const confirmAccept = (bid) => {
    const beforeDeadline = rfq?.bidDeadline && new Date(rfq.bidDeadline) > new Date();
    if (!beforeDeadline) return accept(bid);
    Alert.alert(
      'Chọn xưởng trước hạn báo giá?',
      'Yêu cầu sẽ tạm đóng và không nhận thêm báo giá. Hợp đồng chỉ được tạo sau khi xưởng xác nhận.',
      [{ text: 'Xem lại', style: 'cancel' }, { text: 'Gửi yêu cầu chọn', onPress: () => accept(bid) }],
    );
  };

  const statusMeta = RFQ_STATUS[rfq?.status] || { label: rfq?.status };

  return (
    <View style={styles.container}>
      <View style={[styles.header, { paddingTop: insets.top + 8 }]}>
        <TouchableOpacity style={styles.headerIcon} onPress={() => navigation.goBack()} accessibilityLabel="Quay lại">
          <Ionicons name="arrow-back" size={22} color={COLORS.primary} />
        </TouchableOpacity>
        <View style={{ flex: 1 }}>
          <Text style={styles.headerTitle}>So sánh báo giá</Text>
          <Text style={styles.headerSub}>{rfq?.rfqNumber}</Text>
        </View>
      </View>

      <ScrollView
        contentContainerStyle={styles.scroll}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={async () => { setRefreshing(true); await load(); setRefreshing(false); }} tintColor={COLORS.primary} />}
      >
        {/* RFQ summary */}
        <View style={styles.summary}>
          <View style={styles.summaryTop}>
            <Text style={styles.summaryStatus}>{statusMeta.label}</Text>
            <Text style={styles.summaryDeadline}>Hạn báo giá {formatDate(rfq?.bidDeadline)}</Text>
          </View>
          <Text style={styles.summaryTitle}>{rfq?.title}</Text>
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Giao trước</Text><Text style={styles.summaryValue}>{formatDate(rfq?.deliveryDateRequired)}</Text>
          </View>
          {rfq?.items?.map((item) => (
            <View key={item.id || item.productName} style={styles.summaryRow}>
              <Text style={styles.summaryLabel} numberOfLines={1}>{item.productName}</Text>
              <Text style={styles.summaryValue}>{item.quantity} {item.unit}</Text>
            </View>
          ))}
        </View>

        {awardedBid && (
          <View style={styles.awarded}>
            <Ionicons name="checkmark-circle" size={18} color="#2F7A4A" />
            <Text style={styles.awardedText}>
              Bạn đã chọn báo giá của {supplierFor(awardedBid)?.companyName || 'xưởng'}. {rfq?.status === 'Awarded' ? 'Xưởng đã xác nhận.' : 'Xưởng đang xác nhận lựa chọn của bạn.'}
            </Text>
          </View>
        )}

        <Text style={styles.intro}>Đối chiếu tổng giá, thời gian giao và hiệu lực trước khi chọn. Chạm vào báo giá để xem từng mặt hàng.</Text>

        {loading ? (
          <ActivityIndicator color={COLORS.primary} style={{ marginTop: 24 }} />
        ) : bids.length === 0 ? (
          <View style={styles.empty}>
            <Ionicons name="hourglass-outline" size={28} color={COLORS.textMuted} />
            <Text style={styles.emptyText}>Chưa có báo giá cho yêu cầu này.</Text>
          </View>
        ) : (
          bids.map((bid) => {
            const supplier = supplierFor(bid);
            const isBest = bid.id === bestBidId;
            const isAwarded = bid.id === rfq?.awardedBidId;
            const open = expanded === bid.id;
            const canChoose = !locked && bid.status === 'Submitted' && !bid.isExpired;
            return (
              <View key={bid.id} style={[styles.bid, isAwarded && styles.bidAwarded]}>
                <TouchableOpacity activeOpacity={0.8} onPress={() => setExpanded(open ? null : bid.id)}>
                  <View style={styles.bidTop}>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.supplier} numberOfLines={1}>{supplier?.companyName || 'Xưởng cung cấp'}</Text>
                      {supplier?.reputationScore != null && (
                        <Text style={styles.supplierMeta}>Uy tín {supplier.reputationScore}{supplier.averageRating != null ? ` · ${supplier.averageRating}★` : ''}</Text>
                      )}
                    </View>
                    {isAwarded ? (
                      <View style={[styles.pill, styles.pillGreen]}><Text style={[styles.pillText, styles.pillGreenText]}>Đã chọn</Text></View>
                    ) : isBest ? (
                      <View style={[styles.pill, styles.pillGold]}><Text style={[styles.pillText, styles.pillGoldText]}>Giá thấp nhất</Text></View>
                    ) : null}
                  </View>

                  <Text style={[styles.total, isBest && styles.totalBest]}>{formatVND(bid.totalPrice)}</Text>

                  <View style={styles.facts}>
                    <View style={styles.fact}><Ionicons name="car-outline" size={14} color={COLORS.textSecondary} /><Text style={styles.factText}>Giao {bid.estimatedDeliveryDays} ngày</Text></View>
                    <View style={styles.fact}><Ionicons name="time-outline" size={14} color={COLORS.textSecondary} /><Text style={styles.factText}>Hiệu lực {bid.validityDays} ngày</Text></View>
                    <View style={styles.fact}><Ionicons name="ellipse" size={8} color={COLORS.textMuted} /><Text style={styles.factText}>{bid.isExpired ? 'Hết hiệu lực' : (BID_STATUS[bid.status] || bid.status)}</Text></View>
                  </View>

                  {open && (
                    <View style={styles.lines}>
                      {(bid.items || []).map((line) => (
                        <View key={line.rfqItemId || line.productName} style={styles.line}>
                          <Text style={styles.lineName}>{line.productName} × {line.quantity}</Text>
                          <Text style={styles.lineMeta}>
                            {formatVND(line.unitPrice)} / {line.unit} · Thành tiền {formatVND(line.subtotal)}
                          </Text>
                          {line.notes ? <Text style={styles.lineNote}>{line.notes}</Text> : null}
                        </View>
                      ))}
                    </View>
                  )}
                  <View style={styles.expandRow}>
                    <Text style={styles.expandText}>{open ? 'Thu gọn' : 'Xem từng mặt hàng'}</Text>
                    <Ionicons name={open ? 'chevron-up' : 'chevron-down'} size={14} color={COLORS.textSecondary} />
                  </View>
                </TouchableOpacity>

                {canChoose && (
                  <TouchableOpacity style={styles.choose} onPress={() => confirmAccept(bid)} disabled={busyBidId === bid.id}>
                    {busyBidId === bid.id
                      ? <ActivityIndicator color={COLORS.textWhite} />
                      : <Text style={styles.chooseText}>Chọn xưởng này</Text>}
                  </TouchableOpacity>
                )}
              </View>
            );
          })
        )}

        {rfq?.status === 'Awarded' && (
          <TouchableOpacity style={styles.contractLink} onPress={() => navigation.navigate('Contracts')}>
            <Ionicons name="document-text-outline" size={18} color={COLORS.primary} />
            <Text style={styles.contractLinkText}>Xem hợp đồng được tạo từ báo giá này</Text>
            <Ionicons name="chevron-forward" size={16} color={COLORS.textMuted} />
          </TouchableOpacity>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F4F1EC' },
  header: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 8, paddingBottom: 8, backgroundColor: COLORS.surface },
  headerIcon: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  headerTitle: { color: COLORS.textPrimary, fontSize: 18, fontWeight: '600' },
  headerSub: { color: COLORS.textMuted, fontSize: 12 },
  scroll: { padding: 12, gap: 10, paddingBottom: 32 },

  summary: { padding: 14, gap: 6, borderRadius: 10, backgroundColor: COLORS.surface },
  summaryTop: { flexDirection: 'row', justifyContent: 'space-between' },
  summaryStatus: { color: COLORS.primary, fontSize: 12, fontWeight: '600' },
  summaryDeadline: { color: COLORS.textSecondary, fontSize: 12 },
  summaryTitle: { color: COLORS.textPrimary, fontSize: 15, fontWeight: '600', lineHeight: 21 },
  summaryRow: { flexDirection: 'row', justifyContent: 'space-between', gap: 8 },
  summaryLabel: { flex: 1, color: COLORS.textSecondary, fontSize: 13 },
  summaryValue: { color: COLORS.textPrimary, fontSize: 13 },

  awarded: { flexDirection: 'row', alignItems: 'center', gap: 8, padding: 12, borderRadius: 10, backgroundColor: '#EEF7F1' },
  awardedText: { flex: 1, color: '#2F7A4A', fontSize: 13, lineHeight: 18 },
  intro: { paddingHorizontal: 2, color: COLORS.textSecondary, fontSize: 12, lineHeight: 17 },

  bid: { padding: 14, gap: 4, borderRadius: 10, backgroundColor: COLORS.surface, borderWidth: 1, borderColor: 'transparent' },
  bidAwarded: { borderColor: '#BFDCC9' },
  bidTop: { flexDirection: 'row', alignItems: 'flex-start', gap: 8 },
  supplier: { color: COLORS.textPrimary, fontSize: 14, fontWeight: '600' },
  supplierMeta: { marginTop: 1, color: COLORS.textSecondary, fontSize: 12 },
  pill: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 999 },
  pillText: { fontSize: 11, fontWeight: '500' },
  pillGold: { backgroundColor: '#FDF3DD' },
  pillGoldText: { color: '#9A6408' },
  pillGreen: { backgroundColor: '#EEF7F1' },
  pillGreenText: { color: '#2F7A4A' },
  total: { marginTop: 8, color: COLORS.textPrimary, fontSize: 22, fontWeight: '600', fontVariant: ['tabular-nums'] },
  totalBest: { color: COLORS.primary },
  bidNumber: { color: COLORS.textMuted, fontSize: 12 },
  facts: { flexDirection: 'row', flexWrap: 'wrap', gap: 12, marginTop: 8 },
  fact: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  factText: { color: COLORS.textSecondary, fontSize: 12 },
  lines: { marginTop: 10, gap: 8, padding: 10, borderRadius: 8, backgroundColor: '#F8F5F0' },
  line: { gap: 2 },
  lineName: { color: COLORS.textPrimary, fontSize: 13 },
  lineMeta: { color: COLORS.textSecondary, fontSize: 12 },
  lineNote: { color: COLORS.textMuted, fontSize: 12, fontStyle: 'italic' },
  expandRow: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 8 },
  expandText: { color: COLORS.textSecondary, fontSize: 12 },
  choose: { alignItems: 'center', marginTop: 10, paddingVertical: 11, borderRadius: 8, backgroundColor: COLORS.primary },
  chooseText: { color: COLORS.textWhite, fontSize: 14, fontWeight: '600' },

  empty: { alignItems: 'center', gap: 8, paddingVertical: 32 },
  emptyText: { color: COLORS.textSecondary, fontSize: 13 },
  contractLink: { flexDirection: 'row', alignItems: 'center', gap: 8, padding: 14, borderRadius: 10, backgroundColor: COLORS.surface },
  contractLinkText: { flex: 1, color: COLORS.textPrimary, fontSize: 14 },
});
