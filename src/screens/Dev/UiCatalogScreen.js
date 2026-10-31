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
import AnnouncementPill from '../../components/lucian/AnnouncementPill';
import TrustSecurityBadges from '../../components/lucian/TrustSecurityBadges';
import TearOffCoupon from '../../components/lucian/TearOffCoupon';
import B2BPriceCalculator from '../../components/lucian/B2BPriceCalculator';
import ReviewFilterStars from '../../components/lucian/ReviewFilterStars';
import RecentOrderToast from '../../components/lucian/RecentOrderToast';
import AntdSteps from '../../components/antd/AntdSteps';
import AntdOtpInput from '../../components/antd/AntdOtpInput';

export default function UiCatalogScreen({ navigation }) {
  const [currentStep, setCurrentStep] = useState(1);
  const [submittedOtp, setSubmittedOtp] = useState('');

  return (
    <View style={styles.screen}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
        >
          <Ionicons name="arrow-back" size={24} color={COLORS.textWhite} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>UI Showcase · AntD & Lucian</Text>
        <View style={{ width: 24 }} />
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent}>
        {/* Intro */}
        <View style={styles.introCard}>
          <Text style={styles.introTitle}>Hệ Thống Component Hoàng Gia B2B</Text>
          <Text style={styles.introDesc}>
            Kết hợp chuẩn cấu trúc Ant Design với vi tương tác tinh tế của Lucian Labs. Bảo tồn 100% theme Crimson (#8C1524) & Imperial Gold (#D48806).
          </Text>
        </View>

        {/* 1. Lucian Announcement Pill */}
        <View style={styles.section}>
          <Text style={styles.sectionHeader}>1. Lucian Announcement Pill (#012)</Text>
          <AnnouncementPill />
        </View>

        {/* 2. Lucian Trust Security Badges */}
        <View style={styles.section}>
          <Text style={styles.sectionHeader}>2. Lucian Trust Security Badges (#064)</Text>
          <TrustSecurityBadges />
        </View>

        {/* 3. Lucian Tear-Off Coupon */}
        <View style={styles.section}>
          <Text style={styles.sectionHeader}>3. Lucian Tear-Off Coupon (#088)</Text>
          <TearOffCoupon
            onApply={(code) => Alert.alert('Áp dụng mã', `Mã coupon ${code} đã kích hoạt!`)}
          />
        </View>

        {/* 4. Lucian B2B Price Calculator */}
        <View style={styles.section}>
          <Text style={styles.sectionHeader}>4. Lucian B2B Price Calculator (#278)</Text>
          <B2BPriceCalculator
            onApplyTier={(calc) =>
              Alert.alert(
                'Đã chọn mức giá',
                `Số lượng: ${calc.quantity} hộp\nChiết khấu: ${calc.effectiveDiscount}%\nĐơn giá: ${calc.discountedUnitPrice.toLocaleString('vi-VN')} ₫\nTổng: ${calc.totalCost.toLocaleString('vi-VN')} ₫`
              )
            }
          />
        </View>

        {/* 5. Lucian Review Filter Stars */}
        <View style={styles.section}>
          <Text style={styles.sectionHeader}>5. Lucian Review Filter Stars (#112)</Text>
          <ReviewFilterStars />
        </View>

        {/* 6. Ant Design Steps */}
        <View style={styles.section}>
          <Text style={styles.sectionHeader}>6. Ant Design Steps (Tiến trình thầu & ký HĐ)</Text>
          <AntdSteps
            current={currentStep}
            items={[
              { title: 'Tạo RFQ', desc: 'Chọn 500 hộp' },
              { title: 'Đấu thầu', desc: '3 xưởng gửi bid' },
              { title: 'Ký e-Contract', desc: 'Cọc M1 30%' },
            ]}
          />
          <View style={styles.stepControls}>
            <TouchableOpacity
              style={styles.stepBtn}
              onPress={() => setCurrentStep((prev) => Math.max(0, prev - 1))}
            >
              <Text style={styles.stepBtnText}>Bước trước</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.stepBtn, styles.stepBtnPrimary]}
              onPress={() => setCurrentStep((prev) => Math.min(2, prev + 1))}
            >
              <Text style={[styles.stepBtnText, styles.stepBtnTextPrimary]}>Bước sau</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* 7. Ant Design OTP Input */}
        <View style={styles.section}>
          <Text style={styles.sectionHeader}>7. Ant Design OTP Input (Xác thực ký số)</Text>
          <AntdOtpInput
            onComplete={(code) => {
              setSubmittedOtp(code);
              Alert.alert('Xác thực OTP', `Đã nhập mã ký số: ${code}`);
            }}
          />
          {submittedOtp ? (
            <Text style={styles.otpSuccess}>Mã đã nhập: {submittedOtp}</Text>
          ) : null}
        </View>

        <View style={{ height: 100 }} />
      </ScrollView>

      {/* 8. Lucian Recent Order Toast floating */}
      <RecentOrderToast />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: COLORS.primaryDark,
    paddingTop: 48,
    paddingBottom: 14,
    paddingHorizontal: 16,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: COLORS.textWhite,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: 40,
  },
  introCard: {
    margin: 16,
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    padding: 14,
    borderLeftWidth: 4,
    borderLeftColor: COLORS.accent,
  },
  introTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: COLORS.primaryDark,
    marginBottom: 4,
  },
  introDesc: {
    fontSize: 12,
    color: COLORS.textSecondary,
    lineHeight: 18,
  },
  section: {
    marginBottom: 16,
  },
  sectionHeader: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primary,
    marginHorizontal: 16,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  stepControls: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
    marginTop: 8,
  },
  stepBtn: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: COLORS.border,
    backgroundColor: COLORS.surface,
  },
  stepBtnPrimary: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  stepBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  stepBtnTextPrimary: {
    color: COLORS.textWhite,
  },
  otpSuccess: {
    textAlign: 'center',
    fontSize: 12,
    color: '#059669',
    fontWeight: '700',
    marginTop: 6,
  },
});

