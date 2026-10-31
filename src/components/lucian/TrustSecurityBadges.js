import React, { useState, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  Modal,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { LUCIAN_TOKENS } from '../../theme/tokens';

const BADGES = [
  {
    id: 'iso',
    code: 'ISO 22000',
    title: 'AT Thực Phẩm',
    scope: 'Chứng nhận VSATTP quốc tế',
    desc: '100% xưởng sản xuất đối tác trên nền tảng đạt chứng nhận ISO 22000 & HACCP còn hiệu lực.',
    icon: 'shield-checkmark',
    color: '#059669',
  },
  {
    id: 'safetrade',
    code: 'SafeTrade',
    title: 'Ký Quỹ Ngân Hàng',
    scope: 'Bảo chứng tài khoản Escrow',
    desc: 'Tiền cọc và thanh toán được ký quỹ an toàn, chỉ giải ngân cho xưởng khi doanh nghiệp ký PoD.',
    icon: 'lock-closed',
    color: COLORS.primary,
  },
  {
    id: 'contract',
    code: 'e-Contract',
    title: 'Hợp Đồng Số & VAT',
    scope: 'Ký số OTP 6 số pháp lý 100%',
    desc: 'Hợp đồng điện tử có giá trị pháp lý tương đương văn bản giấy. Xuất hóa đơn VAT điện tử trong 24h.',
    icon: 'document-text',
    color: COLORS.accent,
  },
  {
    id: 'coldchain',
    code: 'Xe Lạnh PoD',
    title: 'Nhiệt Độ 20-25°C',
    scope: 'Giao vận bảo ôn kiểm định',
    desc: 'Vận chuyển bằng xe lạnh chuyên dụng giữ nguyên kết cấu bánh, cam kết đổi mới 100% nếu phát sinh lỗi.',
    icon: 'snow',
    color: '#1D4ED8',
  },
];

export default function TrustSecurityBadges() {
  const [selectedBadge, setSelectedBadge] = useState(null);
  const scaleAnims = useRef(BADGES.map(() => new Animated.Value(1))).current;

  const handlePressIn = (index) => {
    Animated.spring(scaleAnims[index], {
      toValue: 0.94,
      useNativeDriver: true,
    }).start();
  };

  const handlePressOut = (index, badge) => {
    Animated.spring(scaleAnims[index], {
      toValue: 1,
      friction: 4,
      useNativeDriver: true,
    }).start();
    setSelectedBadge(badge);
  };

  return (
    <View style={styles.container}>
      <View style={styles.headerRow}>
        <View style={styles.goldLine} />
        <Text style={styles.sectionTitle}>BẢO CHỨNG B2B TIÊU CHUẨN HOÀNG GIA</Text>
        <View style={styles.goldLine} />
      </View>

      <View style={styles.badgesGrid}>
        {BADGES.map((badge, idx) => (
          <Animated.View
            key={badge.id}
            style={[
              styles.badgeItemWrap,
              { transform: [{ scale: scaleAnims[idx] }] },
            ]}
          >
            <TouchableOpacity
              activeOpacity={0.9}
              onPressIn={() => handlePressIn(idx)}
              onPressOut={() => handlePressOut(idx, badge)}
              style={styles.badgeItem}
            >
              <View style={[styles.iconCircle, { backgroundColor: badge.color + '15' }]}>
                <Ionicons name={badge.icon} size={18} color={badge.color} />
              </View>
              <Text style={styles.badgeCode}>{badge.code}</Text>
              <Text style={styles.badgeTitle} numberOfLines={1}>
                {badge.title}
              </Text>
            </TouchableOpacity>
          </Animated.View>
        ))}
      </View>

      {/* Modal bảo chứng chi tiết */}
      <Modal
        visible={!!selectedBadge}
        transparent
        animationType="fade"
        onRequestClose={() => setSelectedBadge(null)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            {selectedBadge && (
              <>
                <View style={[styles.modalIconCircle, { backgroundColor: selectedBadge.color + '18' }]}>
                  <Ionicons name={selectedBadge.icon} size={32} color={selectedBadge.color} />
                </View>

                <Text style={styles.modalCode}>{selectedBadge.code}</Text>
                <Text style={styles.modalTitle}>{selectedBadge.scope}</Text>

                <View style={styles.infoBox}>
                  <Text style={styles.modalDesc}>{selectedBadge.desc}</Text>
                </View>

                <View style={styles.verifiedTag}>
                  <Ionicons name="checkmark-circle" size={16} color="#059669" />
                  <Text style={styles.verifiedText}>Đã kiểm định & bảo chứng trên hệ thống</Text>
                </View>

                <TouchableOpacity
                  style={styles.closeBtn}
                  onPress={() => setSelectedBadge(null)}
                >
                  <Text style={styles.closeBtnText}>Xác nhận & Đóng</Text>
                </TouchableOpacity>
              </>
            )}
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginHorizontal: 16,
    marginVertical: 10,
    backgroundColor: COLORS.surface,
    borderRadius: LUCIAN_TOKENS.radiusLg,
    padding: 14,
    borderWidth: 1,
    borderColor: COLORS.border,
    shadowColor: '#1F1F1F',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 2,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
    gap: 8,
  },
  goldLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#E8D2A3',
  },
  sectionTitle: {
    fontSize: 10,
    fontWeight: '700',
    color: COLORS.accent,
    letterSpacing: 0.8,
  },
  badgesGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  badgeItemWrap: {
    width: '23.5%',
  },
  badgeItem: {
    backgroundColor: COLORS.background,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#EFEAE1',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 4,
  },
  iconCircle: {
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 6,
  },
  badgeCode: {
    fontSize: 10,
    fontWeight: '800',
    color: COLORS.textPrimary,
    textAlign: 'center',
  },
  badgeTitle: {
    fontSize: 9,
    fontWeight: '500',
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: 2,
  },

  // Modal styles
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  modalContent: {
    width: '100%',
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: COLORS.accent,
    padding: 20,
    alignItems: 'center',
  },
  modalIconCircle: {
    width: 60,
    height: 60,
    borderRadius: 30,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  modalCode: {
    fontSize: 18,
    fontWeight: '800',
    color: COLORS.primary,
    marginBottom: 2,
  },
  modalTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: COLORS.accent,
    marginBottom: 14,
  },
  infoBox: {
    backgroundColor: COLORS.background,
    borderRadius: 10,
    padding: 14,
    borderLeftWidth: 3,
    borderLeftColor: COLORS.primary,
    marginBottom: 16,
    width: '100%',
  },
  modalDesc: {
    fontSize: 13,
    color: COLORS.textPrimary,
    lineHeight: 20,
  },
  verifiedTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 16,
  },
  verifiedText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#059669',
  },
  closeBtn: {
    backgroundColor: COLORS.primary,
    width: '100%',
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  closeBtnText: {
    color: COLORS.textWhite,
    fontSize: 14,
    fontWeight: '700',
  },
});

