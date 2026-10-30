import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
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

export default function CreateRfqScreen({ navigation }) {
  const [title, setTitle] = useState('Thu mua 350 hộp bánh Trung Thu cao cấp tri ân đối tác VIP');
  const [category, setCategory] = useState('Hộp Quà Cao Cấp (4 Bánh + Trà)');
  const [targetQuantity, setTargetQuantity] = useState('350');
  const [minBudget, setMinBudget] = useState('600000');
  const [maxBudget, setMaxBudget] = useState('850000');
  const [deliveryDate, setDeliveryDate] = useState('10/08/2026 (Trước Rằm 5 ngày)');
  const [deadlineDays, setDeadlineDays] = useState('5');
  const [requirements, setRequirements] = useState(
    'Bánh nghệ nhân ít ngọt, hạn dùng tối thiểu 45 ngày, đầy đủ chứng nhận ATTP và ISO 22000. Hộp nắp âm dương cao cấp kèm túi xách đồng bộ.'
  );
  const [customPackaging, setCustomPackaging] = useState(true);
  const [loading, setLoading] = useState(false);

  const handleCreateRfq = async () => {
    if (!title || !targetQuantity || !maxBudget) {
      Alert.alert('Thiếu thông tin', 'Vui lòng nhập tiêu đề gói thầu, số lượng và ngân sách dự kiến.');
      return;
    }

    setLoading(true);
    const payload = {
      title,
      category,
      targetQuantity: parseInt(targetQuantity, 10),
      minBudget: parseInt(minBudget, 10),
      maxBudget: parseInt(maxBudget, 10),
      deliveryDate,
      bidDeadlineDays: parseInt(deadlineDays, 10),
      specifications: requirements,
      isCustomPackagingRequired: customPackaging,
    };

    try {
      await apiClient.post(ENDPOINTS.CREATE_RFQ, payload);
      Alert.alert(
        'Mở Thầu RFQ Thành Công!',
        'Gói thầu của bạn đã được gửi tới hệ thống các xưởng bánh đạt chuẩn. Bạn sẽ nhận thông báo ngay khi có xưởng gửi báo giá (Bid).',
        [
          {
            text: 'Xem gói thầu của tôi',
            onPress: () => navigation.navigate('RfqList'),
          },
        ]
      );
    } catch (e) {
      // Demo fallback
      Alert.alert(
        'Mở Thầu Thành Công (Mẫu Demo)',
        'Đã tạo gói thầu số RFQ-2026-0099. Hệ thống đang mời các xưởng nghệ nhân nộp báo giá.',
        [
          {
            text: 'Đến danh sách RFQ',
            onPress: () => navigation.navigate('RfqList'),
          },
        ]
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <AppHeader
        title="Tạo Yêu Cầu Báo Giá (RFQ)"
        subtitle="Mở thầu B2B nhận giá cạnh tranh từ các xưởng"
        showBack={true}
        onBack={() => navigation.goBack()}
      />

      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.infoBanner}>
          <Ionicons name="information-circle-outline" size={20} color={COLORS.primary} />
          <Text style={styles.infoBannerText}>
            Yêu cầu báo giá (RFQ) giúp doanh nghiệp tiếp cận trực tiếp 50+ xưởng bánh sản xuất lớn, bảo đảm có hóa đơn VAT và hợp đồng pháp lý đầy đủ.
          </Text>
        </View>

        {/* Basic Info */}
        <View style={styles.formCard}>
          <Text style={styles.cardHeading}>1. Thông Tin Nhu Cầu Quà Tặng</Text>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Tiêu đề gói thầu RFQ</Text>
            <TextInput
              style={styles.input}
              value={title}
              onChangeText={setTitle}
              placeholder="Ví dụ: Đặt 200 hộp quà cho cán bộ nhân viên"
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Quy cách loại hộp dự kiến</Text>
            <TextInput
              style={styles.input}
              value={category}
              onChangeText={setCategory}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Số lượng đặt mua dự kiến (Hộp)</Text>
            <TextInput
              style={styles.input}
              value={targetQuantity}
              onChangeText={setTargetQuantity}
              keyboardType="number-pad"
            />
          </View>
        </View>

        {/* Budget & Timeline */}
        <View style={styles.formCard}>
          <Text style={styles.cardHeading}>2. Ngân Sách & Thời Gian</Text>

          <View style={styles.row}>
            <View style={[styles.inputGroup, { flex: 1, marginRight: 8 }]}>
              <Text style={styles.label}>Ngân sách tối thiểu (VNĐ)</Text>
              <TextInput
                style={styles.input}
                value={minBudget}
                onChangeText={setMinBudget}
                keyboardType="numeric"
              />
            </View>
            <View style={[styles.inputGroup, { flex: 1, marginLeft: 8 }]}>
              <Text style={styles.label}>Ngân sách tối đa (VNĐ)</Text>
              <TextInput
                style={styles.input}
                value={maxBudget}
                onChangeText={setMaxBudget}
                keyboardType="numeric"
              />
            </View>
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Ngày cần nhận hàng tại kho</Text>
            <TextInput
              style={styles.input}
              value={deliveryDate}
              onChangeText={setDeliveryDate}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Thời hạn nhận báo giá (Ngày)</Text>
            <TextInput
              style={styles.input}
              value={deadlineDays}
              onChangeText={setDeadlineDays}
              keyboardType="number-pad"
            />
          </View>
        </View>

        {/* Custom Requirements */}
        <View style={styles.formCard}>
          <Text style={styles.cardHeading}>3. Yêu Cầu Kỹ Thuật & Đóng Gói</Text>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>Mô tả chi tiết yêu cầu kỹ thuật</Text>
            <TextInput
              style={[styles.input, styles.multiline]}
              value={requirements}
              onChangeText={setRequirements}
              multiline
            />
          </View>

          <TouchableOpacity
            style={styles.checkRow}
            onPress={() => setCustomPackaging(!customPackaging)}
          >
            <Ionicons
              name={customPackaging ? 'checkbox' : 'square-outline'}
              size={22}
              color={COLORS.primary}
            />
            <Text style={styles.checkText}>
              Yêu cầu xưởng hỗ trợ in ép kim Logo & thiệp chúc mừng doanh nghiệp
            </Text>
          </TouchableOpacity>
        </View>

        <CustomButton
          title="Phát Hành Gói Thầu RFQ"
          icon="📢"
          onPress={handleCreateRfq}
          loading={loading}
          size="large"
          style={styles.submitBtn}
        />
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
  infoBanner: {
    flexDirection: 'row',
    backgroundColor: '#FFFBE6',
    borderWidth: 1,
    borderColor: '#FFE58F',
    borderRadius: 10,
    padding: 12,
    marginBottom: 16,
  },
  infoBannerText: {
    flex: 1,
    marginLeft: 8,
    fontSize: 12,
    color: '#873800',
    lineHeight: 18,
  },
  formCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 16,
    marginBottom: 16,
  },
  cardHeading: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 14,
  },
  inputGroup: {
    marginBottom: 12,
  },
  label: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: COLORS.textPrimary,
    backgroundColor: '#FAFAF8',
  },
  multiline: {
    minHeight: 70,
    textAlignVertical: 'top',
  },
  row: {
    flexDirection: 'row',
  },
  checkRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 6,
  },
  checkText: {
    fontSize: 13,
    color: COLORS.textPrimary,
    marginLeft: 8,
    flex: 1,
    lineHeight: 18,
  },
  submitBtn: {
    marginTop: 8,
    marginBottom: 20,
  },
});

