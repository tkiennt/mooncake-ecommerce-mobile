import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  RefreshControl,
  Modal,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { rfqService, RFQ_STATUS, rfqErrorMessage } from '../../services/rfqService';

const formatVND = (value) => `${Number(value || 0).toLocaleString('vi-VN')} ₫`;
const formatDeadline = (value) => {
  if (!value) return 'Chưa có hạn';
  const d = new Date(value);
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')} · ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};
const budgetText = (rfq) => (rfq.budgetRangeMin || rfq.budgetRangeMax
  ? `${formatVND(rfq.budgetRangeMin)} – ${formatVND(rfq.budgetRangeMax)}`
  : 'Chưa đặt ngân sách');

const FILTERS = [
  { key: '', label: 'Tất cả' },
  { key: 'Open', label: 'Đang nhận báo giá' },
  { key: 'InNegotiation', label: 'Chờ xưởng xác nhận' },
  { key: 'Awarded', label: 'Đã chọn xưởng' },
  { key: 'Cancelled', label: 'Đã hủy' },
];

const TONES = {
  info: { bg: '#EEF2F6', fg: '#3E5872' },
  warning: { bg: '#FDF5E8', fg: '#9A5B0B' },
  success: { bg: '#EEF7F1', fg: '#2F7A4A' },
  danger: { bg: '#FBEEEE', fg: COLORS.primary },
  neutral: { bg: '#F3F0EB', fg: COLORS.textSecondary },
};

function StatusTag({ status }) {
  const meta = RFQ_STATUS[status] || { label: status, tone: 'neutral' };
  const tone = TONES[meta.tone];
  return (
    <View style={[styles.statusTag, { backgroundColor: tone.bg }]}>
      <Text style={[styles.statusTagText, { color: tone.fg }]}>{meta.label}</Text>
    </View>
  );
}

/** Customer RFQ list — same flow as the web "So sánh báo giá" page. */
export default function RfqListScreen({ navigation }) {
  const insets = useSafeAreaInsets();
  const [rfqs, setRfqs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [status, setStatus] = useState('');
  const [query, setQuery] = useState('');

  const [inviteFor, setInviteFor] = useState(null);
  const [suppliers, setSuppliers] = useState([]);
  const [picked, setPicked] = useState([]);
  const [inviteBusy, setInviteBusy] = useState(false);

  const load = useCallback(async () => {
    try {
      setRfqs(await rfqService.listMine());
    } catch (error) {
      Alert.alert('Không tải được yêu cầu', rfqErrorMessage(error));
    } finally {
      setLoading(false);
    }
  }, []);

  // Reload whenever the screen regains focus (after creating an RFQ or choosing a supplier).
  useFocusEffect(useCallback(() => { load(); }, [load]));

  const onRefresh = async () => {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  };

  const visible = useMemo(() => {
    const q = query.trim().toLocaleLowerCase('vi-VN');
    return rfqs.filter((rfq) => (!status || rfq.status === status)
      && (!q || `${rfq.rfqNumber} ${rfq.title}`.toLocaleLowerCase('vi-VN').includes(q)));
  }, [rfqs, status, query]);

  const openInvite = async (rfq) => {
    setInviteFor(rfq);
    setPicked([]);
    setSuppliers([]);
    setInviteBusy(true);
    try {
      setSuppliers(await rfqService.suggestedSuppliers(rfq.id));
    } catch (error) {
      Alert.alert('Không tải được danh sách xưởng', rfqErrorMessage(error));
    } finally {
      setInviteBusy(false);
    }
  };

  const sendInvites = async () => {
    setInviteBusy(true);
    try {
      await rfqService.invite(inviteFor.id, picked);
      setInviteFor(null);
      Alert.alert('Đã gửi lời mời', `Đã mời ${picked.length} xưởng tham gia báo giá.`);
      load();
    } catch (error) {
      Alert.alert('Không gửi được lời mời', rfqErrorMessage(error));
    } finally {
      setInviteBusy(false);
    }
  };

  const hasFilters = Boolean(status || query);

  return (
    <View style={styles.container}>
      <View style={[styles.header, { paddingTop: insets.top + 8 }]}>
        <TouchableOpacity style={styles.headerIcon} onPress={() => navigation.goBack()} accessibilityLabel="Quay lại">
          <Ionicons name="arrow-back" size={22} color={COLORS.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Đấu thầu báo giá</Text>
        <TouchableOpacity style={styles.createButton} onPress={() => navigation.navigate('CreateRfq')}>
          <Ionicons name="add" size={16} color={COLORS.textWhite} />
          <Text style={styles.createButtonText}>Tạo yêu cầu</Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        contentContainerStyle={styles.scroll}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={COLORS.primary} />}
        keyboardShouldPersistTaps="handled"
      >
        {/* How it works — the web hero's three steps, compact */}
        <View style={styles.steps}>
          {[
            ['01', 'Tạo yêu cầu', 'Mặt hàng, số lượng, hạn giao'],
            ['02', 'Nhận báo giá', 'Mời xưởng hoặc chờ đề xuất'],
            ['03', 'So sánh & chọn', 'Giá, tiến độ, uy tín'],
          ].map(([no, title, sub]) => (
            <View key={no} style={styles.step}>
              <Text style={styles.stepNo}>{no}</Text>
              <Text style={styles.stepTitle}>{title}</Text>
              <Text style={styles.stepSub}>{sub}</Text>
            </View>
          ))}
        </View>

        <View style={styles.privacy}>
          <Ionicons name="lock-closed-outline" size={14} color={COLORS.textSecondary} />
          <Text style={styles.privacyText}>Báo giá được niêm phong — chỉ bạn xem được toàn bộ báo giá.</Text>
        </View>

        <View style={styles.searchBox}>
          <Ionicons name="search-outline" size={16} color={COLORS.textMuted} />
          <TextInput
            style={styles.searchInput}
            value={query}
            onChangeText={setQuery}
            placeholder="Tìm mã hoặc tiêu đề yêu cầu"
            placeholderTextColor={COLORS.textMuted}
          />
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters}>
          {FILTERS.map((f) => (
            <TouchableOpacity key={f.key || 'all'} style={[styles.filter, status === f.key && styles.filterActive]} onPress={() => setStatus(f.key)}>
              <Text style={[styles.filterText, status === f.key && styles.filterTextActive]}>{f.label}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {loading ? (
          <ActivityIndicator color={COLORS.primary} style={{ marginTop: 32 }} />
        ) : visible.length === 0 ? (
          <View style={styles.empty}>
            <View style={styles.emptyIcon}><Ionicons name="document-text-outline" size={26} color={COLORS.primary} /></View>
            <Text style={styles.emptyTitle}>{hasFilters ? 'Không tìm thấy yêu cầu phù hợp' : 'Bắt đầu với một yêu cầu báo giá'}</Text>
            <Text style={styles.emptySub}>
              {hasFilters
                ? 'Thử đổi từ khóa hoặc trạng thái.'
                : 'Mô tả số lượng, ngân sách và thời gian giao. Các xưởng phù hợp sẽ gửi báo giá để bạn so sánh.'}
            </Text>
            <TouchableOpacity
              style={styles.emptyButton}
              onPress={hasFilters ? () => { setStatus(''); setQuery(''); } : () => navigation.navigate('CreateRfq')}
            >
              <Text style={styles.emptyButtonText}>{hasFilters ? 'Xóa bộ lọc' : 'Tạo yêu cầu đầu tiên'}</Text>
            </TouchableOpacity>
          </View>
        ) : (
          visible.map((rfq) => (
            <View key={rfq.id} style={styles.card}>
              <View style={styles.cardTop}>
                <Text style={styles.rfqNumber}>{rfq.rfqNumber}</Text>
                <StatusTag status={rfq.status} />
              </View>
              <Text style={styles.title}>{rfq.title}</Text>

              <View style={styles.grid}>
                <View style={styles.cell}><Text style={styles.cellLabel}>Mặt hàng</Text><Text style={styles.cellValue}>{rfq.items?.length || 0}</Text></View>
                <View style={styles.cell}><Text style={styles.cellLabel}>Đã nhận</Text><Text style={styles.cellValue}>{rfq.bidCount || 0} báo giá</Text></View>
                <View style={[styles.cell, styles.cellWide]}><Text style={styles.cellLabel}>Ngân sách / đơn vị</Text><Text style={styles.cellValue}>{budgetText(rfq)}</Text></View>
                <View style={[styles.cell, styles.cellWide]}><Text style={styles.cellLabel}>Hạn nhận báo giá</Text><Text style={styles.cellValue}>{formatDeadline(rfq.bidDeadline)}</Text></View>
              </View>

              <View style={styles.actions}>
                {rfq.status === 'Open' && (
                  <TouchableOpacity style={styles.action} onPress={() => openInvite(rfq)}>
                    <Ionicons name="people-outline" size={15} color={COLORS.textPrimary} />
                    <Text style={styles.actionText}>Mời xưởng</Text>
                  </TouchableOpacity>
                )}
                <TouchableOpacity
                  style={[styles.action, styles.actionPrimary, !rfq.bidCount && styles.actionDisabled]}
                  disabled={!rfq.bidCount}
                  onPress={() => navigation.navigate('RfqDetailBidding', { rfq })}
                >
                  <Ionicons name="git-compare-outline" size={15} color={COLORS.textWhite} />
                  <Text style={styles.actionPrimaryText}>So sánh báo giá</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))
        )}
      </ScrollView>

      {/* Invite suppliers sheet */}
      <Modal visible={Boolean(inviteFor)} transparent animationType="slide" onRequestClose={() => setInviteFor(null)}>
        <View style={styles.sheetOverlay}>
          <View style={[styles.sheet, { paddingBottom: insets.bottom + 16 }]}>
            <View style={styles.sheetHandle} />
            <Text style={styles.sheetTitle}>Mời xưởng · {inviteFor?.rfqNumber}</Text>
            <Text style={styles.sheetSub}>Chọn xưởng được gợi ý theo năng lực và khu vực.</Text>
            {inviteBusy && suppliers.length === 0 ? (
              <ActivityIndicator color={COLORS.primary} style={{ marginVertical: 24 }} />
            ) : (
              suppliers.map((s) => {
                const on = picked.includes(s.userId);
                return (
                  <TouchableOpacity
                    key={s.userId}
                    style={styles.supplierRow}
                    onPress={() => setPicked((cur) => (on ? cur.filter((id) => id !== s.userId) : [...cur, s.userId]))}
                  >
                    <Ionicons name={on ? 'checkbox' : 'square-outline'} size={22} color={on ? COLORS.primary : COLORS.textMuted} />
                    <View style={{ flex: 1 }}>
                      <Text style={styles.supplierName}>{s.companyName}</Text>
                      <Text style={styles.supplierMeta}>Uy tín {s.reputationScore}{s.averageRating != null ? ` · ${s.averageRating}★` : ''}{s.address ? ` · ${s.address}` : ''}</Text>
                    </View>
                  </TouchableOpacity>
                );
              })
            )}
            <View style={styles.sheetActions}>
              <TouchableOpacity style={styles.sheetSecondary} onPress={() => setInviteFor(null)}>
                <Text style={styles.sheetSecondaryText}>Hủy</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.sheetPrimary, (!picked.length || inviteBusy) && styles.actionDisabled]}
                disabled={!picked.length || inviteBusy}
                onPress={sendInvites}
              >
                <Text style={styles.sheetPrimaryText}>Gửi lời mời{picked.length ? ` (${picked.length})` : ''}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F4F1EC' },
  header: {
    flexDirection: 'row', alignItems: 'center', gap: 4,
    paddingHorizontal: 8, paddingBottom: 8, backgroundColor: COLORS.surface,
  },
  headerIcon: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  headerTitle: { flex: 1, color: COLORS.textPrimary, fontSize: 18, fontWeight: '600' },
  createButton: {
    flexDirection: 'row', alignItems: 'center', gap: 4, marginRight: 6,
    paddingHorizontal: 12, paddingVertical: 7, borderRadius: 999, backgroundColor: COLORS.primary,
  },
  createButtonText: { color: COLORS.textWhite, fontSize: 13, fontWeight: '600' },
  scroll: { padding: 12, gap: 10, paddingBottom: 32 },

  steps: { flexDirection: 'row', gap: 8 },
  step: { flex: 1, padding: 10, borderRadius: 10, backgroundColor: COLORS.surface },
  stepNo: { color: COLORS.accent, fontSize: 12, fontWeight: '700' },
  stepTitle: { marginTop: 4, color: COLORS.textPrimary, fontSize: 13, fontWeight: '600' },
  stepSub: { marginTop: 2, color: COLORS.textSecondary, fontSize: 11, lineHeight: 15 },

  privacy: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingHorizontal: 4 },
  privacyText: { flex: 1, color: COLORS.textSecondary, fontSize: 12 },

  searchBox: {
    flexDirection: 'row', alignItems: 'center', gap: 8, height: 40,
    paddingHorizontal: 12, borderRadius: 8, backgroundColor: COLORS.surface,
  },
  searchInput: { flex: 1, color: COLORS.textPrimary, fontSize: 14, paddingVertical: 0 },
  filters: { gap: 8 },
  filter: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999, backgroundColor: COLORS.surface },
  filterActive: { backgroundColor: '#FBEEEE' },
  filterText: { color: COLORS.textSecondary, fontSize: 13 },
  filterTextActive: { color: COLORS.primary, fontWeight: '600' },

  card: { padding: 14, gap: 10, borderRadius: 10, backgroundColor: COLORS.surface },
  cardTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  rfqNumber: { color: COLORS.textMuted, fontSize: 12, fontVariant: ['tabular-nums'] },
  statusTag: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 999 },
  statusTagText: { fontSize: 11, fontWeight: '500' },
  title: { color: COLORS.textPrimary, fontSize: 15, fontWeight: '600', lineHeight: 21 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', rowGap: 8, padding: 10, borderRadius: 8, backgroundColor: '#F8F5F0' },
  cell: { width: '50%' },
  cellWide: { width: '100%' },
  cellLabel: { color: COLORS.textMuted, fontSize: 11 },
  cellValue: { marginTop: 1, color: COLORS.textPrimary, fontSize: 13 },
  actions: { flexDirection: 'row', justifyContent: 'flex-end', gap: 8 },
  action: {
    flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 12, paddingVertical: 8,
    borderRadius: 6, borderWidth: 1, borderColor: COLORS.borderDark,
  },
  actionText: { color: COLORS.textPrimary, fontSize: 13 },
  actionPrimary: { borderColor: COLORS.primary, backgroundColor: COLORS.primary },
  actionPrimaryText: { color: COLORS.textWhite, fontSize: 13, fontWeight: '600' },
  actionDisabled: { opacity: 0.45 },

  empty: { alignItems: 'center', gap: 8, paddingVertical: 40, paddingHorizontal: 20 },
  emptyIcon: { width: 52, height: 52, borderRadius: 16, alignItems: 'center', justifyContent: 'center', backgroundColor: '#FBEEEE' },
  emptyTitle: { color: COLORS.textPrimary, fontSize: 15, fontWeight: '600', textAlign: 'center' },
  emptySub: { color: COLORS.textSecondary, fontSize: 13, lineHeight: 19, textAlign: 'center' },
  emptyButton: { marginTop: 6, paddingHorizontal: 16, paddingVertical: 9, borderRadius: 6, backgroundColor: COLORS.primary },
  emptyButtonText: { color: COLORS.textWhite, fontSize: 13, fontWeight: '600' },

  sheetOverlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: 'rgba(0,0,0,0.4)' },
  sheet: { padding: 18, paddingTop: 10, borderTopLeftRadius: 18, borderTopRightRadius: 18, backgroundColor: COLORS.surface },
  sheetHandle: { alignSelf: 'center', width: 40, height: 4, marginBottom: 12, borderRadius: 2, backgroundColor: COLORS.border },
  sheetTitle: { color: COLORS.textPrimary, fontSize: 16, fontWeight: '600' },
  sheetSub: { marginTop: 2, marginBottom: 8, color: COLORS.textSecondary, fontSize: 12 },
  supplierRow: {
    flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: COLORS.border,
  },
  supplierName: { color: COLORS.textPrimary, fontSize: 14 },
  supplierMeta: { marginTop: 2, color: COLORS.textSecondary, fontSize: 12 },
  sheetActions: { flexDirection: 'row', gap: 10, marginTop: 16 },
  sheetSecondary: { flex: 1, alignItems: 'center', paddingVertical: 12, borderRadius: 8, borderWidth: 1, borderColor: COLORS.border },
  sheetSecondaryText: { color: COLORS.textPrimary, fontSize: 14 },
  sheetPrimary: { flex: 1, alignItems: 'center', paddingVertical: 12, borderRadius: 8, backgroundColor: COLORS.primary },
  sheetPrimaryText: { color: COLORS.textWhite, fontSize: 14, fontWeight: '600' },
});
