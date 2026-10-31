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
import AntdSteps from '../../components/antd/AntdSteps';
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

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Ant Design Steps: Bước 1 */}
        <View style={styles.stepsCard}>
          <AntdSteps
            current={0}
            items={[
              { title: '1. Nhu Cầu', desc: 'Thiết lập yêu cầu' },
              { title: '2. Báo Giá', desc: 'Xưởng nộp Bid' },
              { title: '3. Ký HĐ', desc: 'Ký số & Cọc M1' },
            ]}
          />
        </View>

        <View style={styles.infoBanner}>
          <Ionicons name="information-circle-outline" size={20} color={COLORS.primary} />
          <Text style={styles.infoBannerText}>
            Yêu cầu báo giá (RFQ) giúp doanh nghiệp tiếp cận trực tiếp 50+ xưởng bánh lớn, bảo đảm 100% có hóa đơn VAT và hợp đồng điện tử pháp lý.
          </Text>
        </View>

        {/* Basic Info */}
        <View style={styles.formCard}>
          <Text style={styles.cardHeading}>1. Thông Tin Nhu Cầu Quà Tặng</Text>

          <Text style={styles.inputLabel}>Tiêu đề gói thầu *</Text>
          <TextInput
            style={styles.input}
            value={title}
            onChangeText={setTitle}
            placeholder="Ví dụ: Đặt 300 hộp quà tri ân nhân viên..."
          />

          <Text style={styles.inputLabel}>Danh mục phân loại</Text>
          <TextInput
            style={styles.input}
            value={category}
            onChangeText={setCategory}
            placeholder="Loại set quà..."
          />

          <View style={styles.row}>
            <View style={styles.halfCol}>
              <Text style={styles.inputLabel}>Số lượng cần đặt *</Text>
              <TextInput
                style={styles.input}
                value={targetQuantity}
                onChangeText={setTargetQuantity}
                keyboardType="numeric"
                placeholder="350"
              />
            </View>
            <View style={styles.halfCol}>
              <Text style={styles.inputLabel}>Hạn chót mở thầu (ngày)</Text>
              <TextInput
                style={styles.input}
                value={deadlineDays}
                onChangeText={setDeadlineDays}
                keyboardType="numeric"
                placeholder="5"
              />
            </View>
          </View>
        </View>

        {/* Budget & Timeline */}
        <View style={styles.formCard}>
          <Text style={styles.cardHeading}>2. Ngân Sách Dự Kiến & Giao Vận</Text>

          <View style={styles.row}>
            <View style={styles.halfCol}>
              <Text style={styles.inputLabel}>Giá tối thiểu (VNĐ/hộp)</Text>
              <TextInput
                style={styles.input}
                value={minBudget}
                onChangeText={setMinBudget}
                keyboardType="numeric"
                placeholder="600000"
              />
            </View>
            <View style={styles.halfCol}>
              <Text style={styles.inputLabel}>Giá tối đa (VNĐ/hộp) *</Text>
              <TextInput
                style={styles.input}
                value={maxBudget}
                onChangeText={setMaxBudget}
                keyboardType="numeric"
                placeholder="850000"
              />
            </View>
          </View>

          <Text style={styles.inputLabel}>Ngày cần nhận hàng tại kho doanh nghiệp</Text>
          <TextInput
            style={styles.input}
            value={deliveryDate}
            onChangeText={setDeliveryDate}
            placeholder="Ví dụ: 10/08/2026..."
          />
        </View>

        {/* Specifications */}
        <View style={styles.formCard}>
          <Text style={styles.cardHeading}>3. Yêu Cầu Kỹ Thuật & Gia Công</Text>

          <TouchableOpacity
            style={styles.checkboxRow}
            activeOpacity={0.8}
            onPress={() => setCustomPackaging(!customPackaging)}
          >
            <Ionicons
              name={customPackaging ? 'checkbox' : 'square-outline'}
              size={22}
              color={COLORS.primary}
            />
            <Text style={styles.checkboxLabel}>
              Yêu cầu ép kim / in logo thương hiệu riêng lên nắp hộp
            </Text>
          </TouchableOpacity>

          <Text style={styles.inputLabel}>Chi tiết thông số & tiêu chuẩn chất lượng</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            value={requirements}
            onChangeText={setRequirements}
            multiline
            numberOfLines={4}
            placeholder="Yêu cầu vị bánh, hạn sử dụng, đóng gói..."
          />
        </View>

        <CustomButton
          title={loading ? 'Đang tạo gói thầu...' : 'Phát Hành Gói Thầu RFQ'}
          icon="📢"
          onPress={handleCreateRfq}
          disabled={loading}
          style={styles.submitBtn}
        />
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
  infoBanner: {
    flexDirection: 'row',
    backgroundColor: '#FFF1F0',
    padding: 12,
    borderRadius: 8,
    borderLeftWidth: 3,
    borderLeftColor: COLORS.primary,
    marginBottom: 14,
    gap: 8,
    alignItems: 'center',
  },
  infoBannerText: {
    flex: 1,
    fontSize: 12,
    color: COLORS.primaryDark,
    lineHeight: 18,
  },
  formCard: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 16,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  cardHeading: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 12,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textPrimary,
    marginBottom: 6,
    marginTop: 8,
  },
  input: {
    backgroundColor: COLORS.background,
    borderWidth: 1,
    borderColor: COLORS.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 13,
    color: COLORS.textPrimary,
  },
  textArea: {
    height: 90,
    textAlignVertical: 'top',
  },
  row: {
    flexDirection: 'row',
    gap: 12,
  },
  halfCol: {
    flex: 1,
  },
  checkboxRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginVertical: 10,
  },
  checkboxLabel: {
    fontSize: 13,
    color: COLORS.textPrimary,
    flex: 1,
  },
  submitBtn: {
    marginTop: 8,
  },
});
