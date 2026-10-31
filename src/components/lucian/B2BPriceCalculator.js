import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Switch,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { LUCIAN_TOKENS } from '../../theme/tokens';

const TIERS = [
  { name: 'Đơn Khởi Điểm', min: 20, max: 49, discount: 10, label: '20 - 49 hộp' },
  { name: 'Doanh Nghiệp Vừa', min: 50, max: 199, discount: 20, label: '50 - 199 hộp' },
  { name: 'Tập Đoàn VIP', min: 200, max: 500, discount: 35, label: '200+ hộp' },
];

const SLIDER_STOPS = [20, 50, 100, 200, 350, 500];

export default function B2BPriceCalculator({
  baseRetailPrice = 450000,
  initialQuantity = 80,
  onApplyTier,
}) {
  const [quantity, setQuantity] = useState(initialQuantity);
  const [isEarlyBird, setIsEarlyBird] = useState(false);

  // Determine Tier
  const tierIndex = quantity >= 200 ? 2 : quantity >= 50 ? 1 : 0;
  const currentTier = TIERS[tierIndex];

  // Effective discount
  const effectiveDiscount = currentTier.discount + (isEarlyBird ? 5 : 0);
  const discountedUnitPrice = Math.round(baseRetailPrice * (1 - effectiveDiscount / 100));
  const totalCost = discountedUnitPrice * quantity;
  const totalSavings = (baseRetailPrice - discountedUnitPrice) * quantity;

  const handleAdjust = (delta) => {
    setQuantity((prev) => {
      const next = prev + delta;
      if (next < 20) return 20;
      if (next > 500) return 500;
      return next;
    });
  };

  const handleSelectTier = (minQty) => {
    setQuantity(minQty);
  };

  // Tính phần trăm slider fill
  const sliderPercentage = Math.min(100, Math.max(0, ((quantity - 20) / (500 - 20)) * 100));

  return (
    <View style={styles.container}>
      {/* Title & Badge */}
      <View style={styles.header}>
        <View style={styles.headerTitleWrap}>
          <Ionicons name="calculator-outline" size={20} color={COLORS.primary} />
          <Text style={styles.headerTitle}>BẢNG TÍNH GIÁ SỈ B2B TỰ ĐỘNG</Text>
        </View>
        <View style={styles.liveBadge}>
          <Text style={styles.liveBadgeText}>CHIẾT KHẤU TỨC THÌ</Text>
        </View>
      </View>

      {/* Tier Selector Chips */}
      <View style={styles.tierSelector}>
        {TIERS.map((tier, idx) => {
          const isActive = idx === tierIndex;
          return (
            <TouchableOpacity
              key={tier.name}
              onPress={() => handleSelectTier(tier.min)}
              style={[styles.tierChip, isActive && styles.tierChipActive]}
            >
              <Text style={[styles.tierChipTitle, isActive && styles.tierChipTitleActive]}>
                {tier.label}
              </Text>
              <Text style={[styles.tierChipDiscount, isActive && styles.tierChipDiscountActive]}>
                -{tier.discount}%
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {/* RF-03: Interactive Slider Visual Track & Stops (Checklist Design Standard) */}
      <View style={styles.sliderSection}>
        <View style={styles.sliderHeaderRow}>
          <Text style={styles.sliderSubText}>Kéo chọn mốc số lượng hộp:</Text>
          <Text style={styles.sliderCurrentBadge}>{quantity} hộp</Text>
        </View>

        {/* Progress Track */}
        <View style={styles.sliderTrackContainer}>
          <View style={styles.sliderTrackBg} />
          <View style={[styles.sliderTrackFill, { width: `${sliderPercentage}%` }]} />
          <View style={[styles.sliderThumb, { left: `${sliderPercentage}%` }]}>
            <View style={styles.sliderThumbInner} />
          </View>
        </View>

        {/* Stops Buttons */}
        <View style={styles.sliderStopsRow}>
          {SLIDER_STOPS.map((stop) => {
            const isMatch = quantity === stop;
            return (
              <TouchableOpacity
                key={stop}
                style={[styles.stopPill, isMatch && styles.stopPillActive]}
                onPress={() => setQuantity(stop)}
              >
                <Text style={[styles.stopText, isMatch && styles.stopTextActive]}>
                  {stop}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>

      {/* Interactive Stepper / Counter */}
      <View style={styles.stepperContainer}>
        <Text style={styles.stepperLabel}>Tinh chỉnh số lượng đặt mua:</Text>
        <View style={styles.stepperRow}>
          <TouchableOpacity
            style={styles.stepBtn}
            onPress={() => handleAdjust(-10)}
            disabled={quantity <= 20}
          >
            <Ionicons name="remove" size={20} color={quantity <= 20 ? COLORS.textMuted : COLORS.primary} />
          </TouchableOpacity>

          <View style={styles.qtyDisplay}>
            <Text style={styles.qtyNumber}>{quantity}</Text>
            <Text style={styles.qtyUnit}>hộp</Text>
          </View>

          <TouchableOpacity
            style={styles.stepBtn}
            onPress={() => handleAdjust(10)}
            disabled={quantity >= 500}
          >
            <Ionicons name="add" size={20} color={quantity >= 500 ? COLORS.textMuted : COLORS.primary} />
          </TouchableOpacity>
        </View>
      </View>

      {/* Early Bird Switch */}
      <View style={styles.switchRow}>
        <View style={styles.switchTextWrap}>
          <Ionicons name="ribbon-outline" size={16} color={COLORS.accent} />
          <Text style={styles.switchLabel}>Ưu đãi đặt sớm (Ký trước 15/07):</Text>
        </View>
        <View style={styles.switchAction}>
          <Text style={styles.switchExtraText}>+5% off</Text>
          <Switch
            value={isEarlyBird}
            onValueChange={setIsEarlyBird}
            trackColor={{ false: '#E0DACF', true: COLORS.accentGoldLight }}
            thumbColor={isEarlyBird ? COLORS.accent : '#FFFFFF'}
          />
        </View>
      </View>

      {/* Calculation Results Card */}
      <View style={styles.calcResultCard}>
        <View style={styles.resultRow}>
          <Text style={styles.resultLabel}>Đơn giá gốc niêm yết:</Text>
          <Text style={styles.resultOldPrice}>
            {baseRetailPrice.toLocaleString('vi-VN')} ₫/hộp
          </Text>
        </View>

        <View style={styles.resultRow}>
          <Text style={styles.resultLabel}>Mức chiết khấu áp dụng:</Text>
          <View style={styles.discountBadge}>
            <Text style={styles.discountBadgeText}>Giảm {effectiveDiscount}%</Text>
          </View>
        </View>

        <View style={styles.resultRow}>
          <Text style={styles.resultLabel}>Đơn giá sau chiết khấu:</Text>
          <Text style={styles.resultPriceHighlight}>
            {discountedUnitPrice.toLocaleString('vi-VN')} ₫/hộp
          </Text>
        </View>

        <View style={styles.divider} />

        <View style={styles.totalRow}>
          <View>
            <Text style={styles.totalLabel}>TỔNG DỰ TOÁN ĐƠN HÀNG</Text>
            <Text style={styles.savingsText}>
              Tiết kiệm: {totalSavings.toLocaleString('vi-VN')} ₫
            </Text>
          </View>
          <Text style={styles.totalValue}>
            {totalCost.toLocaleString('vi-VN')} ₫
          </Text>
        </View>
      </View>

      {/* Action CTA */}
      <TouchableOpacity
        style={styles.ctaBtn}
        onPress={() => {
          if (onApplyTier) {
            onApplyTier({
              quantity,
              effectiveDiscount,
              discountedUnitPrice,
              totalCost,
              totalSavings,
            });
          }
        }}
      >
        <Ionicons name="cart-outline" size={18} color={COLORS.textWhite} />
        <Text style={styles.ctaBtnText}>Áp dụng mức giá này ({quantity} hộp)</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginHorizontal: 16,
    marginVertical: 12,
    backgroundColor: COLORS.surface,
    borderRadius: 14,
    borderWidth: 1.2,
    borderColor: '#E8D2A3',
    padding: 16,
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  headerTitleWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  headerTitle: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primary,
    letterSpacing: 0.5,
  },
  liveBadge: {
    backgroundColor: COLORS.accentGoldBg,
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  liveBadgeText: {
    fontSize: 9,
    fontWeight: '700',
    color: COLORS.accent,
  },
  tierSelector: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 14,
    gap: 6,
  },
  tierChip: {
    flex: 1,
    backgroundColor: COLORS.background,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: COLORS.border,
    paddingVertical: 8,
    alignItems: 'center',
  },
  tierChipActive: {
    backgroundColor: '#FFF1F0',
    borderColor: COLORS.primary,
    borderWidth: 1.5,
  },
  tierChipTitle: {
    fontSize: 10,
    fontWeight: '600',
    color: COLORS.textSecondary,
  },
  tierChipTitleActive: {
    color: COLORS.primary,
    fontWeight: '700',
  },
  tierChipDiscount: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.accent,
    marginTop: 2,
  },
  tierChipDiscountActive: {
    color: COLORS.primary,
  },

  // RF-03 Slider Section
  sliderSection: {
    backgroundColor: COLORS.background,
    borderRadius: 10,
    padding: 12,
    marginBottom: 12,
  },
  sliderHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  sliderSubText: {
    fontSize: 11,
    color: COLORS.textSecondary,
    fontWeight: '600',
  },
  sliderCurrentBadge: {
    fontSize: 12,
    fontWeight: '800',
    color: COLORS.primary,
    backgroundColor: '#FFF1F0',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
  },
  sliderTrackContainer: {
    height: 24,
    justifyContent: 'center',
    position: 'relative',
    marginHorizontal: 8,
  },
  sliderTrackBg: {
    height: 8,
    backgroundColor: '#EAE3D5',
    borderRadius: 4,
    width: '100%',
  },
  sliderTrackFill: {
    position: 'absolute',
    left: 0,
    height: 8,
    backgroundColor: COLORS.accent,
    borderRadius: 4,
  },
  sliderThumb: {
    position: 'absolute',
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: COLORS.primary,
    borderWidth: 2,
    borderColor: '#FFFFFF',
    marginLeft: -11,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 3,
    elevation: 3,
  },
  sliderThumbInner: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#FFFFFF',
  },
  sliderStopsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8,
  },
  stopPill: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
    backgroundColor: COLORS.surface,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  stopPillActive: {
    backgroundColor: COLORS.primary,
    borderColor: COLORS.primary,
  },
  stopText: {
    fontSize: 10,
    fontWeight: '700',
    color: COLORS.textSecondary,
  },
  stopTextActive: {
    color: '#FFFFFF',
  },

  stepperContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: COLORS.background,
    borderRadius: 10,
    padding: 10,
    marginBottom: 12,
  },
  stepperLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: COLORS.textPrimary,
  },
  stepperRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  stepBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: COLORS.surface,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  qtyDisplay: {
    flexDirection: 'row',
    alignItems: 'baseline',
    gap: 3,
    minWidth: 55,
    justifyContent: 'center',
  },
  qtyNumber: {
    fontSize: 18,
    fontWeight: '900',
    color: COLORS.primary,
  },
  qtyUnit: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  switchRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
    paddingHorizontal: 4,
  },
  switchTextWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  switchLabel: {
    fontSize: 12,
    color: COLORS.textPrimary,
    fontWeight: '500',
  },
  switchAction: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  switchExtraText: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.accent,
  },
  calcResultCard: {
    backgroundColor: '#FAF7F0',
    borderRadius: 10,
    padding: 12,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: '#EFE7D8',
  },
  resultRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  resultLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
  },
  resultOldPrice: {
    fontSize: 11,
    color: COLORS.textMuted,
    textDecorationLine: 'line-through',
  },
  discountBadge: {
    backgroundColor: '#FFE58F',
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 1,
  },
  discountBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#874D00',
  },
  resultPriceHighlight: {
    fontSize: 13,
    fontWeight: '800',
    color: COLORS.primary,
  },
  divider: {
    height: 1,
    backgroundColor: '#E5DAC8',
    marginVertical: 8,
  },
  totalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  totalLabel: {
    fontSize: 10,
    fontWeight: '800',
    color: COLORS.textSecondary,
    letterSpacing: 0.5,
  },
  savingsText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#059669',
    marginTop: 2,
  },
  totalValue: {
    fontSize: 18,
    fontWeight: '900',
    color: COLORS.primaryDark,
  },
  ctaBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: COLORS.primary,
    borderRadius: 10,
    paddingVertical: 12,
    gap: 8,
  },
  ctaBtnText: {
    color: COLORS.textWhite,
    fontSize: 13,
    fontWeight: '700',
  },
});
