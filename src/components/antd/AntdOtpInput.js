import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { ANTD_TOKENS } from '../../theme/tokens';

export default function AntdOtpInput({
  length = 6,
  onComplete,
  countdownSeconds = 60,
  onResend,
}) {
  const [digits, setDigits] = useState(new Array(length).fill(''));
  const [timeLeft, setTimeLeft] = useState(countdownSeconds);
  const [canResend, setCanResend] = useState(false);
  const inputRefs = useRef([]);

  useEffect(() => {
    if (timeLeft <= 0) {
      setCanResend(true);
      return;
    }
    const timer = setInterval(() => {
      setTimeLeft((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(timer);
  }, [timeLeft]);

  const handleChangeText = (text, index) => {
    const cleanText = text.replace(/[^0-9]/g, '');
    const newDigits = [...digits];

    if (cleanText.length > 1) {
      // User pasted full OTP
      const pasted = cleanText.slice(0, length).split('');
      pasted.forEach((char, i) => {
        newDigits[i] = char;
      });
      setDigits(newDigits);
      const lastIdx = Math.min(pasted.length - 1, length - 1);
      inputRefs.current[lastIdx]?.focus();

      if (pasted.length === length && onComplete) {
        onComplete(pasted.join(''));
      }
      return;
    }

    newDigits[index] = cleanText;
    setDigits(newDigits);

    if (cleanText && index < length - 1) {
      inputRefs.current[index + 1]?.focus();
    }

    const fullCode = newDigits.join('');
    if (fullCode.length === length && onComplete) {
      onComplete(fullCode);
    }
  };

  const handleKeyPress = (e, index) => {
    if (e.nativeEvent.key === 'Backspace' && !digits[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handleResendClick = () => {
    if (!canResend) return;
    setDigits(new Array(length).fill(''));
    setTimeLeft(countdownSeconds);
    setCanResend(false);
    inputRefs.current[0]?.focus();
    if (onResend) onResend();
  };

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Nhập mã xác thực OTP ({length} số):</Text>

      {/* 6 Digit Boxes */}
      <View style={styles.boxRow}>
        {digits.map((digit, idx) => {
          const isFilled = digit.length > 0;
          return (
            <TextInput
              key={idx}
              ref={(ref) => (inputRefs.current[idx] = ref)}
              style={[
                styles.otpBox,
                isFilled && styles.otpBoxFilled,
              ]}
              keyboardType="number-pad"
              maxLength={1}
              value={digit}
              onChangeText={(text) => handleChangeText(text, idx)}
              onKeyPress={(e) => handleKeyPress(e, idx)}
              selectTextOnFocus
              textAlign="center"
            />
          );
        })}
      </View>

      {/* Countdown & Resend Button */}
      <View style={styles.footerRow}>
        {canResend ? (
          <TouchableOpacity
            style={styles.resendBtn}
            onPress={handleResendClick}
          >
            <Ionicons name="refresh" size={14} color={COLORS.primary} />
            <Text style={styles.resendText}>Gửi lại mã OTP mới</Text>
          </TouchableOpacity>
        ) : (
          <View style={styles.countdownWrap}>
            <Ionicons name="timer-outline" size={14} color={COLORS.textSecondary} />
            <Text style={styles.countdownText}>
              Gửi lại sau <Text style={styles.countdownHighlight}>{timeLeft}s</Text>
            </Text>
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginVertical: 12,
    alignItems: 'center',
  },
  label: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginBottom: 12,
  },
  boxRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
  },
  otpBox: {
    width: 44,
    height: 52,
    backgroundColor: COLORS.surface,
    borderWidth: 1.5,
    borderColor: COLORS.border,
    borderRadius: 8,
    fontSize: 22,
    fontWeight: '800',
    color: COLORS.primaryDark,
    shadowColor: '#1F1F1F',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  otpBoxFilled: {
    borderColor: COLORS.accent, // Gold active border
    backgroundColor: '#FFFDF8',
  },
  footerRow: {
    marginTop: 14,
    alignItems: 'center',
  },
  countdownWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  countdownText: {
    fontSize: 12,
    color: COLORS.textSecondary,
  },
  countdownHighlight: {
    fontWeight: '700',
    color: COLORS.primary,
  },
  resendBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: 4,
    paddingHorizontal: 8,
  },
  resendText: {
    fontSize: 12,
    fontWeight: '700',
    color: COLORS.primary,
    textDecorationLine: 'underline',
  },
});

