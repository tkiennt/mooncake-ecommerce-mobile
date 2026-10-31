import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { ANTD_TOKENS } from '../../theme/tokens';

export default function AntdSteps({
  current = 0,
  items = [
    { title: 'Thiết lập', desc: 'Chọn mẫu & SL' },
    { title: 'Nhận Bid', desc: 'So sánh báo giá' },
    { title: 'Ký Hợp Đồng', desc: 'Cọc M1 30%' },
  ],
  direction = 'horizontal',
}) {
  return (
    <View style={[styles.container, direction === 'vertical' && styles.containerVertical]}>
      {items.map((item, index) => {
        const isFinish = index < current;
        const isProcess = index === current;
        const isWait = index > current;

        return (
          <View
            key={index}
            style={[
              styles.stepItem,
              direction === 'horizontal' ? styles.stepItemHorizontal : styles.stepItemVertical,
            ]}
          >
            {/* Step Icon & Connecting Line */}
            <View style={direction === 'horizontal' ? styles.indicatorRow : styles.indicatorCol}>
              <View
                style={[
                  styles.stepCircle,
                  isFinish && styles.circleFinish,
                  isProcess && styles.circleProcess,
                  isWait && styles.circleWait,
                ]}
              >
                {isFinish ? (
                  <Ionicons name="checkmark" size={14} color={COLORS.textWhite} />
                ) : (
                  <Text
                    style={[
                      styles.stepNumber,
                      isProcess && styles.stepNumberProcess,
                      isWait && styles.stepNumberWait,
                    ]}
                  >
                    {index + 1}
                  </Text>
                )}
              </View>

              {/* Connecting Line */}
              {index < items.length - 1 && (
                <View
                  style={[
                    direction === 'horizontal' ? styles.lineHorizontal : styles.lineVertical,
                    isFinish ? styles.lineFinish : styles.lineWait,
                  ]}
                />
              )}
            </View>

            {/* Label & Description */}
            <View style={[styles.textWrap, direction === 'horizontal' && styles.textWrapHorizontal]}>
              <Text
                style={[
                  styles.stepTitle,
                  isProcess && styles.stepTitleProcess,
                  isFinish && styles.stepTitleFinish,
                  isWait && styles.stepTitleWait,
                ]}
                numberOfLines={1}
              >
                {item.title}
              </Text>
              {item.desc ? (
                <Text style={styles.stepDesc} numberOfLines={1}>
                  {item.desc}
                </Text>
              ) : null}
            </View>
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    paddingVertical: 12,
    paddingHorizontal: 8,
  },
  containerVertical: {
    flexDirection: 'column',
  },
  stepItem: {
    alignItems: 'center',
  },
  stepItemHorizontal: {
    flex: 1,
  },
  stepItemVertical: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  indicatorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    width: '100%',
    justifyContent: 'center',
    position: 'relative',
  },
  indicatorCol: {
    alignItems: 'center',
    marginRight: 12,
  },
  stepCircle: {
    width: 26,
    height: 26,
    borderRadius: 13,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 2,
  },
  circleFinish: {
    backgroundColor: COLORS.accent, // Gold completed
  },
  circleProcess: {
    backgroundColor: COLORS.primary, // Crimson active
    borderWidth: 2,
    borderColor: '#E8D2A3',
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
    elevation: 3,
  },
  circleWait: {
    backgroundColor: COLORS.background,
    borderWidth: 1.5,
    borderColor: COLORS.border,
  },
  stepNumber: {
    fontSize: 12,
    fontWeight: '700',
  },
  stepNumberProcess: {
    color: COLORS.textWhite,
  },
  stepNumberWait: {
    color: COLORS.textMuted,
  },
  lineHorizontal: {
    position: 'absolute',
    top: 13,
    left: '50%',
    width: '100%',
    height: 2,
    zIndex: 1,
  },
  lineVertical: {
    width: 2,
    height: 30,
    marginTop: 4,
  },
  lineFinish: {
    backgroundColor: COLORS.accent,
  },
  lineWait: {
    backgroundColor: COLORS.border,
  },
  textWrap: {
    marginTop: 6,
  },
  textWrapHorizontal: {
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  stepTitle: {
    fontSize: 11,
    fontWeight: '600',
    textAlign: 'center',
  },
  stepTitleProcess: {
    color: COLORS.primary,
    fontWeight: '800',
  },
  stepTitleFinish: {
    color: COLORS.textPrimary,
    fontWeight: '700',
  },
  stepTitleWait: {
    color: COLORS.textMuted,
  },
  stepDesc: {
    fontSize: 9,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: 2,
  },
});

