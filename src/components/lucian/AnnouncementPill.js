import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
  Modal,
  ScrollView,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { LUCIAN_TOKENS } from '../../theme/tokens';

const ANNOUNCEMENTS = [
  'Mở cổng phân phối vụ mùa 2026 · Chiết khấu tới 35%',
  'Miễn phí in logo & thiệp thương hiệu từ 30 hộp',
  'Hỗ trợ gửi 01 hộp mẫu thử nguyên seal tận nơi 24h',
  'Ký quỹ SafeTrade · 100% xuất hóa đơn VAT điện tử',
];

const DETAIL_LOGS = [
  {
    tag: 'MỚI NHẤT',
    title: 'Chính sách chiết khấu bậc thang 2026',
    desc: 'Áp dụng mức 10% - 35% cho đơn từ 20 đến 500+ hộp. Bảo hộ giá độc quyền theo hợp đồng B2B.',
  },
  {
    tag: 'ĐẶC QUYỀN',
    title: 'Gia công thương hiệu riêng',
    desc: 'Ép kim hoặc khắc laser logo doanh nghiệp lên nắp hộp gỗ sơn mài, kèm thiệp chúc thư pháp.',
  },
  {
    tag: 'CAM KẾT',
    title: 'Bảo hành & Xe lạnh PoD',
    desc: 'Giao hàng bằng xe lạnh chuyên dụng 20-25°C. Đổi mới 100% trong 12h nếu phát sinh móp méo.',
  },
];

export default function AnnouncementPill({ onNavigate }) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [modalVisible, setModalVisible] = useState(false);
  const translateY = useRef(new Animated.Value(0)).current;
  const pulseAnim = useRef(new Animated.Value(1)).current;

  // Auto-scroll ticker
  useEffect(() => {
    const interval = setInterval(() => {
      Animated.sequence([
        Animated.timing(translateY, {
          toValue: -20,
          duration: 350,
          useNativeDriver: true,
        }),
        Animated.timing(translateY, {
          toValue: 20,
          duration: 0,
          useNativeDriver: true,
        }),
        Animated.timing(translateY, {
          toValue: 0,
          duration: 350,
          useNativeDriver: true,
        }),
      ]).start();

      setCurrentIndex((prev) => (prev + 1) % ANNOUNCEMENTS.length);
    }, 4500);

    return () => clearInterval(interval);
  }, [translateY]);

  // Subtle breathing pulse for gold crown
  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.08,
          duration: 1200,
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 1200,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [pulseAnim]);

  return (
    <View style={styles.wrapper}>
      <TouchableOpacity
        activeOpacity={0.85}
        onPress={() => setModalVisible(true)}
        style={styles.pillContainer}
      >
        <Animated.View style={[styles.badgeIcon, { transform: [{ scale: pulseAnim }] }]}>
          <Ionicons name="sparkles" size={13} color={COLORS.accent} />
        </Animated.View>

        <View style={styles.textTrack}>
          <Animated.View style={{ transform: [{ translateY }] }}>
            <Text style={styles.tickerText} numberOfLines={1}>
              {ANNOUNCEMENTS[currentIndex]}
            </Text>
          </Animated.View>
        </View>

        <View style={styles.arrowWrap}>
          <Ionicons name="chevron-forward" size={14} color={COLORS.accent} />
        </View>
      </TouchableOpacity>

      {/* Modal chi tiết thông cáo */}
      <Modal
        visible={modalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <View style={styles.modalHeaderTitleWrap}>
                <Ionicons name="megaphone-outline" size={20} color={COLORS.primary} />
                <Text style={styles.modalHeaderTitle}>Thông Cáo Vụ Mùa B2B</Text>
              </View>
              <TouchableOpacity onPress={() => setModalVisible(false)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                <Ionicons name="close-circle-outline" size={24} color={COLORS.textSecondary} />
              </TouchableOpacity>
            </View>

            <ScrollView style={styles.modalBody} showsVerticalScrollIndicator={false}>
              {DETAIL_LOGS.map((item, idx) => (
                <View key={idx} style={styles.logCard}>
                  <View style={styles.logTag}>
                    <Text style={styles.logTagText}>{item.tag}</Text>
                  </View>
                  <Text style={styles.logTitle}>{item.title}</Text>
                  <Text style={styles.logDesc}>{item.desc}</Text>
                </View>
              ))}
            </ScrollView>

            <TouchableOpacity
              style={styles.modalBtn}
              onPress={() => setModalVisible(false)}
            >
              <Text style={styles.modalBtnText}>Đã hiểu thông điệp</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    marginHorizontal: 16,
    marginVertical: 6,
  },
  pillContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    borderWidth: 1.2,
    borderColor: '#E8D2A3', // Gold rim
    borderRadius: LUCIAN_TOKENS.radiusPill,
    paddingVertical: 8,
    paddingHorizontal: 12,
    shadowColor: COLORS.accent,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.12,
    shadowRadius: 6,
    elevation: 2,
  },
  badgeIcon: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: COLORS.accentGoldBg,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
  },
  textTrack: {
    flex: 1,
    height: 20,
    overflow: 'hidden',
    justifyContent: 'center',
  },
  tickerText: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.primaryDark,
  },
  arrowWrap: {
    paddingLeft: 6,
  },

  // Modal styles
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  modalContent: {
    width: '100%',
    maxHeight: '75%',
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: COLORS.accent,
    padding: 18,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
    paddingBottom: 12,
  },
  modalHeaderTitleWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  modalHeaderTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: COLORS.primary,
  },
  modalBody: {
    marginVertical: 14,
  },
  logCard: {
    backgroundColor: COLORS.background,
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
    borderLeftWidth: 3,
    borderLeftColor: COLORS.primary,
  },
  logTag: {
    alignSelf: 'flex-start',
    backgroundColor: COLORS.accentGoldBg,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    marginBottom: 4,
  },
  logTagText: {
    fontSize: 10,
    fontWeight: '700',
    color: COLORS.accent,
  },
  logTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: 4,
  },
  logDesc: {
    fontSize: 12,
    color: COLORS.textSecondary,
    lineHeight: 18,
  },
  modalBtn: {
    backgroundColor: COLORS.primary,
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
  },
  modalBtnText: {
    color: COLORS.textWhite,
    fontSize: 14,
    fontWeight: '700',
  },
});

