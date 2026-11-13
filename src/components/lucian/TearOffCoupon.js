import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Alert,
  Clipboard,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { LUCIAN_TOKENS } from '../../theme/tokens';

export default function TearOffCoupon({
  code = 'B2BMOON2026',
  discountText = 'GIẢM 500.000₫',
  conditionText = 'Đơn doanh nghiệp từ 30 hộp',
  initialSeconds = 5 * 3600 + 42 * 60 + 15,
  onApply,
}) {
  const [secondsLeft, setSecondsLeft] = useState(initialSeconds);
  const [isTorn, setIsTorn] = useState(false);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const timer = setInterval(() => {
      setSecondsLeft((prev) => Math.max(0, prev - 1));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTime = (totalSecs) => {
    const h = Math.floor(totalSecs / 3600);
    const m = Math.floor((totalSecs % 3600) / 60);
    const s = totalSecs % 60;
    const pad = (n) => (n < 10 ? `0${n}` : `${n}`);
    return `${pad(h)}:${pad(m)}:${pad(s)}`;
  };

  const handleTearOff = () => {
    setIsTorn(true);
    if (onApply) onApply(code);
  };

  const handleCopyCode = () => {
    try {
      Clipboard.setString(code);
    } catch {}
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  return (
    <View style={styles.wrapper}>
      {/* Header Countdown */}
      <View style={styles.timerBar}>
        <Ionicons name="time-outline" size={14} color={COLORS.accent} />
        <Text style={styles.timerLabel}>Ưu đãi mùa vụ kết thúc sau: </Text>
        <Text style={styles.timerValue}>{formatTime(secondsLeft)}</Text>
      </View>

      {/* Ticket Body */}
      <View style={styles.ticketCard}>
        {/* Left Side: Offer Info */}
        <View style={styles.ticketMain}>
          <View style={styles.subBadge}>
            <Text style={styles.subBadgeText}>Đặc quyền doanh nghiệp</Text>
          </View>
          <Text style={styles.discountTitle}>{discountText}</Text>
          <Text style={styles.conditionText}>{conditionText}</Text>

          {isTorn ? (
            <View style={styles.couponCodeRow}>
              <Text style={styles.couponCodeText}>{code}</Text>
              <TouchableOpacity
                onPress={handleCopyCode}
                style={[styles.copyBtn, copied && styles.copyBtnSuccess]}
              >
                <Ionicons
                  name={copied ? 'checkmark' : 'copy-outline'}
                  size={12}
                  color={copied ? '#FFFFFF' : COLORS.primary}
                />
                <Text style={[styles.copyBtnText, copied && styles.copyBtnTextSuccess]}>
                  {copied ? 'Đã chép' : 'Sao chép'}
                </Text>
              </TouchableOpacity>
            </View>
          ) : (
            <Text style={styles.promptText}>Bấm bên phải để xé phiếu & nhận mã</Text>
          )}
        </View>

        {/* Notches & Perforation Line */}
        <View style={styles.perforationWrap}>
          <View style={[styles.notch, styles.topNotch]} />
          <View style={styles.dashLine} />
          <View style={[styles.notch, styles.bottomNotch]} />
        </View>

        {/* Right Side: Tear Action Stub */}
        <View style={[styles.ticketStub, isTorn && styles.ticketStubTorn]}>
          {isTorn ? (
            <View style={styles.appliedWrap}>
              <Ionicons name="gift-outline" size={24} color={COLORS.accent} />
              <Text style={styles.appliedText}>Đã nhận</Text>
              <Text style={styles.appliedSub}>Sẵn sàng dùng</Text>
            </View>
          ) : (
            <TouchableOpacity
              activeOpacity={0.8}
              onPress={handleTearOff}
              style={styles.tearBtn}
            >
              <Ionicons name="cut-outline" size={20} color={COLORS.textWhite} />
              <Text style={styles.tearBtnText}>Xé phiếu</Text>
              <Text style={styles.tearBtnSub}>Nhận ngay</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    marginHorizontal: 16,
    marginVertical: 10,
  },
  timerBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 6,
    gap: 4,
  },
  timerLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  timerValue: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.accent,
  },
  ticketCard: {
    flexDirection: 'row',
    backgroundColor: '#FFFDF9',
    borderRadius: 12,
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
    overflow: 'hidden',
    shadowColor: COLORS.accent,
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.12,
    shadowRadius: 8,
    elevation: 3,
  },
  ticketMain: {
    flex: 1,
    padding: 14,
    justifyContent: 'center',
  },
  subBadge: {
    alignSelf: 'flex-start',
    backgroundColor: COLORS.accentGoldBg,
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
    marginBottom: 6,
  },
  subBadgeText: {
    fontSize: 9,
    fontWeight: '800',
    color: COLORS.accent,
    letterSpacing: 0.5,
  },
  discountTitle: {
    fontSize: 17,
    fontWeight: '900',
    color: COLORS.primaryDark,
    marginBottom: 2,
  },
  conditionText: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginBottom: 8,
  },
  promptText: {
    fontSize: 10,
    fontStyle: 'italic',
    color: COLORS.textMuted,
  },
  couponCodeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  couponCodeText: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primary,
    backgroundColor: '#FFF1F0',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
    letterSpacing: 1,
  },
  copyBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    borderWidth: 1,
    borderColor: COLORS.primary,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
  },
  copyBtnSuccess: {
    backgroundColor: '#059669',
    borderColor: '#059669',
  },
  copyBtnText: {
    fontSize: 10,
    fontWeight: '700',
    color: COLORS.primary,
  },
  copyBtnTextSuccess: {
    color: '#FFFFFF',
  },

  // Perforation
  perforationWrap: {
    width: 20,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  notch: {
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: COLORS.background, // Match canvas background
    position: 'absolute',
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
  },
  topNotch: {
    top: -9,
  },
  bottomNotch: {
    bottom: -9,
  },
  dashLine: {
    height: '60%',
    width: 1,
    borderStyle: 'dashed',
    borderWidth: 1,
    borderColor: '#D4C5AD',
  },

  // Ticket Stub
  ticketStub: {
    width: 95,
    backgroundColor: COLORS.primary,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 10,
  },
  ticketStubTorn: {
    backgroundColor: '#F7F2E7',
    borderLeftWidth: 1,
    borderLeftColor: '#E8D2A3',
  },
  tearBtn: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  tearBtnText: {
    color: COLORS.textWhite,
    fontSize: 12,
    fontWeight: '800',
    marginTop: 4,
  },
  tearBtnSub: {
    color: '#FFD8D8',
    fontSize: 9,
    marginTop: 1,
  },
  appliedWrap: {
    alignItems: 'center',
  },
  appliedText: {
    fontSize: 11,
    fontWeight: '800',
    color: COLORS.accent,
    marginTop: 2,
  },
  appliedSub: {
    fontSize: 9,
    color: COLORS.textSecondary,
    marginTop: 1,
  },
});

