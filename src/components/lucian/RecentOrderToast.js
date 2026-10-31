import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Animated,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { LUCIAN_TOKENS } from '../../theme/tokens';

const ACTIVITIES = [
  {
    company: 'FPT Software Corp',
    action: 'vừa chốt đơn 350 Hộp Nguyệt Viên Tri Kỷ',
    time: '2 phút trước',
    badge: 'Đơn Sẵn Kho',
    icon: 'bag-check',
    color: '#059669',
  },
  {
    company: 'Techcombank Thăng Long',
    action: 'vừa mở thầu RFQ 500 hộp gỗ sơn mài',
    time: '5 phút trước',
    badge: 'Đấu Thầu RFQ',
    icon: 'hammer',
    color: COLORS.accent,
  },
  {
    company: 'Vingroup Retail',
    action: 'đã ký nghiệm thu xe lạnh PoD',
    time: '8 phút trước',
    badge: 'Xe Lạnh PoD',
    icon: 'shield-checkmark',
    color: '#1D4ED8',
  },
  {
    company: 'Vinamilk Corporation',
    action: 'vừa ký kết hợp đồng e-Contract 400 hộp',
    time: '12 phút trước',
    badge: 'Ký Số OTP',
    icon: 'document-text',
    color: COLORS.primary,
  },
];

export default function RecentOrderToast({ autoPlay = true }) {
  const [index, setIndex] = useState(0);
  const [visible, setVisible] = useState(true);
  const translateY = useRef(new Animated.Value(100)).current;
  const opacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (!autoPlay) return;

    // Show initial
    showToast();

    const interval = setInterval(() => {
      hideToast(() => {
        setIndex((prev) => (prev + 1) % ACTIVITIES.length);
        showToast();
      });
    }, 6000);

    return () => clearInterval(interval);
  }, [autoPlay]);

  const showToast = () => {
    Animated.parallel([
      Animated.spring(translateY, {
        toValue: 0,
        friction: 6,
        useNativeDriver: true,
      }),
      Animated.timing(opacity, {
        toValue: 1,
        duration: 300,
        useNativeDriver: true,
      }),
    ]).start();
  };

  const hideToast = (callback) => {
    Animated.parallel([
      Animated.timing(translateY, {
        toValue: 40,
        duration: 250,
        useNativeDriver: true,
      }),
      Animated.timing(opacity, {
        toValue: 0,
        duration: 200,
        useNativeDriver: true,
      }),
    ]).start(() => {
      if (callback) callback();
    });
  };

  if (!visible) return null;

  const current = ACTIVITIES[index];

  return (
    <Animated.View
      style={[
        styles.toastWrapper,
        {
          transform: [{ translateY }],
          opacity,
        },
      ]}
    >
      <View style={styles.toastContainer}>
        <View style={[styles.iconBox, { backgroundColor: current.color + '15' }]}>
          <Ionicons name={current.icon} size={18} color={current.color} />
        </View>

        <View style={styles.infoCol}>
          <View style={styles.topRow}>
            <Text style={styles.companyName} numberOfLines={1}>
              {current.company}
            </Text>
            <View style={[styles.badgePill, { backgroundColor: current.color + '18' }]}>
              <Text style={[styles.badgeText, { color: current.color }]}>
                {current.badge}
              </Text>
            </View>
          </View>
          <Text style={styles.actionText} numberOfLines={1}>
            {current.action}
          </Text>
          <Text style={styles.timeText}>{current.time}</Text>
        </View>

        <TouchableOpacity
          onPress={() => setVisible(false)}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          style={styles.closeBtn}
        >
          <Ionicons name="close" size={14} color={COLORS.textMuted} />
        </TouchableOpacity>
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  toastWrapper: {
    position: 'absolute',
    bottom: 20,
    left: 16,
    right: 16,
    zIndex: 999,
  },
  toastContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    borderRadius: 14,
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
    padding: 10,
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.16,
    shadowRadius: 10,
    elevation: 6,
  },
  iconBox: {
    width: 38,
    height: 38,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 10,
  },
  infoCol: {
    flex: 1,
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 2,
  },
  companyName: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primaryDark,
    flex: 1,
    marginRight: 6,
  },
  badgePill: {
    paddingHorizontal: 5,
    paddingVertical: 1,
    borderRadius: 4,
  },
  badgeText: {
    fontSize: 8,
    fontWeight: '700',
  },
  actionText: {
    fontSize: 11,
    color: COLORS.textPrimary,
  },
  timeText: {
    fontSize: 9,
    color: COLORS.textMuted,
    marginTop: 2,
  },
  closeBtn: {
    marginLeft: 6,
    padding: 2,
  },
});

