import React from 'react';
import { View, Text, Image, StyleSheet, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';
import { imageSource } from '../../utils/imageSource';

const formatSold = (count = 0) => (count >= 1000 ? `${(count / 1000).toFixed(1).replace('.0', '')}k+` : `${count}`);
const formatPrice = (value = 0) => `${Number(value).toLocaleString('vi-VN')} ₫`;

/**
 * Compact two-column feed card: image first, then a short name, a prominent price and
 * one line of logistics info. Keeps the home feed airy instead of stacking full-width cards.
 */
export default function ProductGridCard({ product, onPress, imageRatio = 1 }) {
  const topDiscount = Math.max(0, ...(product.tierPricing || []).map((t) => t.discountPercent || 0));

  return (
    <TouchableOpacity style={styles.card} activeOpacity={0.9} onPress={() => onPress?.(product)}>
      <View style={[styles.imageFrame, { aspectRatio: imageRatio }]}>
        <Image source={imageSource(product.coverImage)} style={styles.image} resizeMode="cover" />
        {topDiscount > 0 && (
          <View style={styles.discount}>
            <Text style={styles.discountText}>-{topDiscount}%</Text>
          </View>
        )}
        {product.isCustomPackagingSupported && (
          <View style={styles.logoRibbon}>
            <Ionicons name="color-wand-outline" size={10} color={COLORS.primary} />
            <Text style={styles.logoRibbonText}>In logo</Text>
          </View>
        )}
      </View>

      <View style={styles.body}>
        {product.rating >= 4.8 && (
          <View style={styles.tag}>
            <Ionicons name="checkmark-circle" size={11} color={COLORS.primary} />
            <Text style={styles.tagText}>Xưởng uy tín</Text>
          </View>
        )}
        <Text style={styles.name} numberOfLines={2}>{product.name}</Text>

        <View style={styles.priceRow}>
          <Text style={styles.price} numberOfLines={1}>{formatPrice(product.basePrice)}</Text>
          {product.soldCount > 0 && <Text style={styles.sold}>Đã bán {formatSold(product.soldCount)}</Text>}
        </View>

        <View style={styles.metaRow}>
          <Ionicons name="cube-outline" size={12} color={COLORS.textMuted} />
          <Text style={styles.meta} numberOfLines={1}>Từ {product.minOrderQty} hộp</Text>
          {product.shopCity && (
            <>
              <Text style={styles.metaDivider}>|</Text>
              <Ionicons name="location-outline" size={12} color={COLORS.textMuted} />
              <Text style={[styles.meta, styles.metaCity]} numberOfLines={1}>{product.shopCity}</Text>
            </>
          )}
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 6,
    overflow: 'hidden',
    marginBottom: 8,
  },
  // The frame owns the aspect ratio; aspectRatio on <Image> itself is ignored by react-native-web.
  imageFrame: {
    width: '100%',
    backgroundColor: COLORS.surfaceHover,
  },
  image: {
    ...StyleSheet.absoluteFillObject,
    width: '100%',
    height: '100%',
  },
  // Soft pills floating on the image instead of solid blocks glued to the corners.
  discount: {
    position: 'absolute',
    top: 6,
    right: 6,
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 999,
    backgroundColor: 'rgba(255, 255, 255, 0.92)',
  },
  discountText: {
    color: COLORS.primary,
    fontSize: 11,
    fontWeight: '600',
  },
  logoRibbon: {
    position: 'absolute',
    left: 6,
    bottom: 6,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 999,
    backgroundColor: 'rgba(255, 255, 255, 0.92)',
  },
  logoRibbonText: {
    color: COLORS.primaryDark,
    fontSize: 10,
    fontWeight: '500',
  },
  body: {
    paddingHorizontal: 8,
    paddingTop: 6,
    paddingBottom: 8,
    gap: 6,
  },
  name: {
    color: COLORS.textPrimary,
    fontSize: 13,
    lineHeight: 18,
  },
  tag: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 3,
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 999,
    backgroundColor: '#FBEEEE',
  },
  tagText: {
    color: COLORS.primary,
    fontSize: 10,
    fontWeight: '500',
  },
  priceRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    gap: 4,
  },
  price: {
    flexShrink: 1,
    color: COLORS.primary,
    fontSize: 16,
    fontWeight: '600',
  },
  sold: {
    color: COLORS.textSecondary,
    fontSize: 11,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  meta: {
    color: COLORS.textMuted,
    fontSize: 11,
  },
  metaCity: {
    flexShrink: 1,
  },
  metaDivider: {
    color: COLORS.border,
    fontSize: 11,
    marginHorizontal: 2,
  },
});
