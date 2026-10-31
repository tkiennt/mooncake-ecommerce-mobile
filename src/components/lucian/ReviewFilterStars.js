import React, { useState } from 'react';
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

const CRITERIA = [
  { key: 'taste', label: 'Chất lượng bánh & Vị' },
  { key: 'packaging', label: 'Quy cách hộp & Logo' },
  { key: 'delivery', label: 'Đúng hẹn & Xe lạnh' },
  { key: 'contract', label: 'Hóa đơn VAT & HĐ' },
];

const LABELS = ['', 'Cần cải thiện', 'Đạt yêu cầu', 'Khá tốt', 'Rất hài lòng', 'Xuất sắc tuyệt đối'];

export default function ReviewFilterStars({
  initialScores = { taste: 5, packaging: 5, delivery: 5, contract: 5 },
  readOnly = false,
  onChange,
}) {
  const [scores, setScores] = useState(initialScores);

  const handleRate = (criterionKey, star) => {
    if (readOnly) return;
    const nextScores = { ...scores, [criterionKey]: star };
    setScores(nextScores);
    if (onChange) onChange(nextScores);
  };

  const calculateOverall = () => {
    const values = Object.values(scores);
    const sum = values.reduce((a, b) => a + b, 0);
    return (sum / values.length).toFixed(1);
  };

  return (
    <View style={styles.container}>
      {/* Header Summary */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>ĐÁNH GIÁ 4 TIÊU CHÍ CHẤT LƯỢNG B2B</Text>
          <Text style={styles.headerSubtitle}>Theo chuẩn nghiệm thu thu mua doanh nghiệp</Text>
        </View>
        <View style={styles.overallBadge}>
          <Ionicons name="star" size={14} color={COLORS.accent} />
          <Text style={styles.overallText}>{calculateOverall()} / 5.0</Text>
        </View>
      </View>

      {/* Criteria Rows */}
      {CRITERIA.map((item) => {
        const currentScore = scores[item.key] || 5;
        return (
          <View key={item.key} style={styles.criteriaRow}>
            <View style={styles.labelCol}>
              <Text style={styles.criterionName}>{item.label}</Text>
              <Text style={styles.criterionScoreLabel}>
                {LABELS[currentScore]}
              </Text>
            </View>

            <View style={styles.starsCol}>
              {[1, 2, 3, 4, 5].map((star) => {
                const filled = star <= currentScore;
                return (
                  <TouchableOpacity
                    key={star}
                    disabled={readOnly}
                    onPress={() => handleRate(item.key, star)}
                    style={styles.starTouch}
                    activeOpacity={0.7}
                  >
                    <Ionicons
                      name={filled ? 'star' : 'star-outline'}
                      size={20}
                      color={filled ? COLORS.accent : '#D8D0C5'}
                    />
                  </TouchableOpacity>
                );
              })}
            </View>
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    padding: 14,
    marginVertical: 8,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#F0EBE1',
    paddingBottom: 10,
    marginBottom: 10,
  },
  headerTitle: {
    fontSize: 11,
    fontWeight: '800',
    color: COLORS.primaryDark,
    letterSpacing: 0.5,
  },
  headerSubtitle: {
    fontSize: 10,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  overallBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: COLORS.accentGoldBg,
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: '#E8D2A3',
  },
  overallText: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.accent,
  },
  criteriaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 0.5,
    borderBottomColor: '#F5F1E9',
  },
  labelCol: {
    flex: 1,
  },
  criterionName: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  criterionScoreLabel: {
    fontSize: 10,
    color: COLORS.accent,
    fontWeight: '500',
    marginTop: 2,
  },
  starsCol: {
    flexDirection: 'row',
    gap: 4,
  },
  starTouch: {
    padding: 2,
  },
});

