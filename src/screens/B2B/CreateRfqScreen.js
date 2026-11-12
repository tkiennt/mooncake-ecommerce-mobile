import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Switch,
  Alert,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { rfqService, rfqErrorMessage } from '../../services/rfqService';

const DELIVERY_OPTIONS = [7, 14, 21, 30];
const DEADLINE_OPTIONS = [1, 3, 5, 7];

const digitsOnly = (text) => text.replace(/\D/g, '');
const formatMoneyInput = (digits) => (digits ? Number(digits).toLocaleString('vi-VN') : '');
const addDays = (days, hour) => {
  const d = new Date();
  d.setDate(d.getDate() + days);
  if (hour != null) d.setHours(hour, 0, 0, 0);
  return d;
};
const toDateOnly = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const labelDate = (d) => `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;

const emptyItem = () => ({ productName: '', quantity: '100', unit: 'Hộp', targetPrice: '', specifications: '', needsCustomPackaging: false });

function Field({ label, required, hint, children }) {
  return (
    <View style={styles.field}>
      <Text style={styles.label}>{label}{required ? <Text style={styles.required}> *</Text> : null}</Text>
      {children}
      {hint ? <Text style={styles.hint}>{hint}</Text> : null}
    </View>
  );
}

function Chips({ options, value, onChange, render }) {
  return (
    <View style={styles.chips}>
      {options.map((opt) => (
        <TouchableOpacity key={opt} style={[styles.chip, value === opt && styles.chipActive]} onPress={() => onChange(opt)}>
          <Text style={[styles.chipText, value === opt && styles.chipTextActive]}>{render(opt)}</Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

/** Create + publish an RFQ with the same fields and rules as the web portal. */
export default function CreateRfqScreen({ navigation }) {
  const insets = useSafeAreaInsets();
  const [title, setTitle] = useState('');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [description, setDescription] = useState('');
  const [deliveryInDays, setDeliveryInDays] = useState(14);
  const [deadlineInDays, setDeadlineInDays] = useState(3);
  const [budgetMin, setBudgetMin] = useState('');
  const [budgetMax, setBudgetMax] = useState('');
  const [items, setItems] = useState([emptyItem()]);
  const [submitting, setSubmitting] = useState(false);

  const updateItem = (index, patch) => setItems((cur) => cur.map((it, i) => (i === index ? { ...it, ...patch } : it)));

  const validate = () => {
    if (title.trim().length < 5) return 'Tiêu đề cần ít nhất 5 ký tự.';
    if (deliveryAddress.trim().length < 10) return 'Địa chỉ giao cần ít nhất 10 ký tự.';
    if (deadlineInDays > deliveryInDays) return 'Hạn nhận báo giá không được sau ngày giao hàng.';
    if (budgetMin && budgetMax && Number(budgetMin) > Number(budgetMax)) return 'Ngân sách tối thiểu đang lớn hơn tối đa.';
    const bad = items.findIndex((it) => !it.productName.trim() || !(Number(it.quantity) > 0) || !it.unit.trim());
    if (bad >= 0) return `Mặt hàng ${bad + 1} cần tên sản phẩm, số lượng và đơn vị.`;
    return null;
  };

  const submit = async () => {
    const problem = validate();
    if (problem) {
      Alert.alert('Kiểm tra lại thông tin', problem);
      return;
    }
    setSubmitting(true);
    try {
      const rfq = await rfqService.createAndPublish({
        title: title.trim(),
        description: description.trim() || null,
        deliveryAddress: deliveryAddress.trim(),
        deliveryDateRequired: toDateOnly(addDays(deliveryInDays)),
        budgetRangeMin: budgetMin ? Number(budgetMin) : null,
        budgetRangeMax: budgetMax ? Number(budgetMax) : null,
        bidDeadline: addDays(deadlineInDays, 17).toISOString(),
        items: items.map((it) => ({
          productName: it.productName.trim(),
          description: null,
          quantity: Number(it.quantity),
          unit: it.unit.trim(),
          targetPrice: it.targetPrice ? Number(it.targetPrice) : null,
          specifications: it.specifications.trim() || null,
          packagingRequirements: null,
          needsCustomPackaging: it.needsCustomPackaging,
        })),
      });
      Alert.alert(
        rfq.isDemo ? 'Đã tạo (chế độ demo)' : 'Đã phát hành yêu cầu',
        rfq.isDemo
          ? `Không kết nối được máy chủ nên ${rfq.rfqNumber} chỉ được lưu tạm trên máy.`
          : `${rfq.rfqNumber} đã được gửi tới các xưởng phù hợp. Bạn sẽ nhận thông báo khi có báo giá.`,
        [{ text: 'Xem danh sách', onPress: () => navigation.navigate('RfqList') }],
      );
    } catch (error) {
      Alert.alert('Không tạo được yêu cầu', rfqErrorMessage(error));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <KeyboardAvoidingView style={styles.container} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <View style={[styles.header, { paddingTop: insets.top + 8 }]}>
        <TouchableOpacity style={styles.headerIcon} onPress={() => navigation.goBack()} accessibilityLabel="Quay lại">
          <Ionicons name="close" size={24} color={COLORS.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Tạo yêu cầu báo giá</Text>
      </View>

      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Thông tin chung</Text>
          <Field label="Tiêu đề" required>
            <TextInput style={styles.input} value={title} onChangeText={setTitle} placeholder="VD: 350 hộp quà tri ân đối tác" placeholderTextColor={COLORS.textMuted} />
          </Field>
          <Field label="Địa chỉ giao" required>
            <TextInput style={styles.input} value={deliveryAddress} onChangeText={setDeliveryAddress} placeholder="Số nhà, đường, quận, tỉnh/thành" placeholderTextColor={COLORS.textMuted} />
          </Field>
          <Field label="Mô tả">
            <TextInput style={[styles.input, styles.textarea]} value={description} onChangeText={setDescription} multiline maxLength={5000} placeholder="Yêu cầu về hộp, logo, thiệp, cách đóng gói…" placeholderTextColor={COLORS.textMuted} />
          </Field>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Thời gian & ngân sách</Text>
          <Field label="Giao hàng sau" required hint={`Ngày giao: ${labelDate(addDays(deliveryInDays))}`}>
            <Chips options={DELIVERY_OPTIONS} value={deliveryInDays} onChange={setDeliveryInDays} render={(d) => `${d} ngày`} />
          </Field>
          <Field label="Hạn nhận báo giá" required hint={`Đóng nhận báo giá lúc 17:00 ngày ${labelDate(addDays(deadlineInDays))}`}>
            <Chips
              options={DEADLINE_OPTIONS.filter((d) => d <= deliveryInDays)}
              value={deadlineInDays}
              onChange={setDeadlineInDays}
              render={(d) => `${d} ngày`}
            />
          </Field>
          <View style={styles.row}>
            <View style={{ flex: 1 }}>
              <Field label="Ngân sách từ">
                <TextInput style={styles.input} keyboardType="number-pad" value={formatMoneyInput(budgetMin)} onChangeText={(t) => setBudgetMin(digitsOnly(t))} placeholder="0" placeholderTextColor={COLORS.textMuted} />
              </Field>
            </View>
            <View style={{ flex: 1 }}>
              <Field label="Đến">
                <TextInput style={styles.input} keyboardType="number-pad" value={formatMoneyInput(budgetMax)} onChangeText={(t) => setBudgetMax(digitsOnly(t))} placeholder="0" placeholderTextColor={COLORS.textMuted} />
              </Field>
            </View>
          </View>
          <Text style={styles.hint}>Nhập bằng đồng, không phải nghìn hay triệu. VD: 1.000.000 = một triệu đồng.</Text>
        </View>

        {items.map((item, index) => (
          <View key={index} style={styles.section}>
            <View style={styles.itemHead}>
              <Text style={styles.sectionTitle}>Mặt hàng {index + 1}</Text>
              {items.length > 1 && (
                <TouchableOpacity onPress={() => setItems((cur) => cur.filter((_, i) => i !== index))}>
                  <Text style={styles.remove}>Xóa</Text>
                </TouchableOpacity>
              )}
            </View>
            <Field label="Sản phẩm" required>
              <TextInput style={styles.input} value={item.productName} onChangeText={(t) => updateItem(index, { productName: t })} placeholder="VD: Hộp 4 bánh nướng + trà" placeholderTextColor={COLORS.textMuted} />
            </Field>
            <View style={styles.row}>
              <View style={{ flex: 1 }}>
                <Field label="Số lượng" required>
                  <TextInput style={styles.input} keyboardType="number-pad" value={item.quantity} onChangeText={(t) => updateItem(index, { quantity: digitsOnly(t) })} />
                </Field>
              </View>
              <View style={{ flex: 1 }}>
                <Field label="Đơn vị" required>
                  <TextInput style={styles.input} value={item.unit} onChangeText={(t) => updateItem(index, { unit: t })} />
                </Field>
              </View>
            </View>
            <Field label="Giá mục tiêu / đơn vị">
              <TextInput style={styles.input} keyboardType="number-pad" value={formatMoneyInput(item.targetPrice)} onChangeText={(t) => updateItem(index, { targetPrice: digitsOnly(t) })} placeholder="Không bắt buộc" placeholderTextColor={COLORS.textMuted} />
            </Field>
            <Field label="Quy cách">
              <TextInput style={styles.input} value={item.specifications} onChangeText={(t) => updateItem(index, { specifications: t })} placeholder="Vị, trọng lượng, loại vỏ…" placeholderTextColor={COLORS.textMuted} />
            </Field>
            <View style={styles.switchRow}>
              <Text style={styles.switchLabel}>Cần in logo / bao bì riêng</Text>
              <Switch
                value={item.needsCustomPackaging}
                onValueChange={(v) => updateItem(index, { needsCustomPackaging: v })}
                trackColor={{ true: COLORS.primary, false: COLORS.border }}
                thumbColor={COLORS.surface}
              />
            </View>
          </View>
        ))}

        <TouchableOpacity style={styles.addItem} onPress={() => setItems((cur) => [...cur, { ...emptyItem(), quantity: '1' }])}>
          <Ionicons name="add-circle-outline" size={18} color={COLORS.primary} />
          <Text style={styles.addItemText}>Thêm mặt hàng</Text>
        </TouchableOpacity>
      </ScrollView>

      <View style={[styles.footer, { paddingBottom: insets.bottom + 10 }]}>
        <TouchableOpacity style={styles.submit} onPress={submit} disabled={submitting}>
          {submitting ? <ActivityIndicator color={COLORS.textWhite} /> : <Text style={styles.submitText}>Phát hành RFQ</Text>}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F4F1EC' },
  header: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 8, paddingBottom: 8, backgroundColor: COLORS.surface },
  headerIcon: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  headerTitle: { flex: 1, color: COLORS.textPrimary, fontSize: 18, fontWeight: '600' },
  scroll: { padding: 12, gap: 10, paddingBottom: 24 },
  section: { padding: 14, gap: 12, borderRadius: 10, backgroundColor: COLORS.surface },
  sectionTitle: { color: COLORS.textPrimary, fontSize: 15, fontWeight: '600' },
  field: { gap: 6 },
  label: { color: COLORS.textSecondary, fontSize: 13 },
  required: { color: COLORS.primary },
  hint: { color: COLORS.textMuted, fontSize: 12, lineHeight: 17 },
  input: {
    minHeight: 42, paddingHorizontal: 12, paddingVertical: 10, borderRadius: 8,
    borderWidth: 1, borderColor: COLORS.border, color: COLORS.textPrimary, fontSize: 14, backgroundColor: COLORS.surface,
  },
  textarea: { minHeight: 80, textAlignVertical: 'top' },
  row: { flexDirection: 'row', gap: 10 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: { paddingHorizontal: 14, paddingVertical: 7, borderRadius: 999, borderWidth: 1, borderColor: COLORS.border },
  chipActive: { borderColor: COLORS.primary, backgroundColor: '#FBEEEE' },
  chipText: { color: COLORS.textPrimary, fontSize: 13 },
  chipTextActive: { color: COLORS.primary, fontWeight: '600' },
  itemHead: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  remove: { color: COLORS.primary, fontSize: 13 },
  switchRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  switchLabel: { color: COLORS.textPrimary, fontSize: 14 },
  addItem: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 6, paddingVertical: 12, borderRadius: 10, borderWidth: 1, borderStyle: 'dashed', borderColor: COLORS.primary },
  addItemText: { color: COLORS.primary, fontSize: 14, fontWeight: '500' },
  footer: { paddingHorizontal: 12, paddingTop: 10, backgroundColor: COLORS.surface, borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: COLORS.border },
  submit: { alignItems: 'center', paddingVertical: 13, borderRadius: 8, backgroundColor: COLORS.primary },
  submitText: { color: COLORS.textWhite, fontSize: 15, fontWeight: '600' },
});
