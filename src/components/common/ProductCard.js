import React from 'react';
import { View, Text, Image, StyleSheet, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';

export default function ProductCard({ product, onPress }) {
  const formatVND = (price) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'currency',
      currency: 'VND',
    }).format(price);
  };

  const maxDiscount = product.tierPricing && product.tierPricing.length > 0
    ? Math.max(...product.tierPricing.map((t) => t.discountPercent))
    : 0;

  return (
    <TouchableOpacity
      style={styles.card}
      onPress={() => onPress && onPress(product)}
      activeOpacity={0.9}
    >
      <View style={styles.imageContainer}>
        <Image
          source={{ uri: product.coverImage }}
          style={styles.image}
          resizeMode="cover"
        />
        {maxDiscount > 0 && (
          <View style={styles.discountBadge}>
            <Text style={styles.discountText}>Giảm đến -{maxDiscount}%</Text>
          </View>
        )}
        {product.isCustomPackagingSupported && (
          <View style={styles.packagingBadge}>
            <Text style={styles.packagingText}>In Logo</Text>
          </View>
        )}
      </View>

      <View style={styles.content}>
        <Text style={styles.shopName} numberOfLines={1}>
          <Ionicons name="storefront-outline" size={12} color={COLORS.accent} /> {product.shopName}
        </Text>
        <Text style={styles.title} numberOfLines={2}>
          {product.name}
        </Text>

        <View style={styles.metaRow}>
          <View style={styles.ratingBox}>
            <Ionicons name="star" size={12} color="#FAAD14" />
            <Text style={styles.ratingText}>{product.rating} ({product.reviewCount})</Text>
          </View>
          <Text style={styles.moqText}>Tối thiểu: {product.minOrderQty} hộp</Text>
        </View>

        <View style={styles.footerRow}>
          <View>
            <Text style={styles.priceLabel}>Giá cơ bản từ</Text>
            <Text style={styles.price}>{formatVND(product.basePrice)}</Text>
          </View>
          <View style={styles.actionBtn}>
            <Ionicons name="arrow-forward" size={16} color={COLORS.primary} />
          </View>
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 16,
    overflow: 'hidden',
    shadowColor: COLORS.shadowColor,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
  },
  imageContainer: {
    position: 'relative',
    height: 180,
    backgroundColor: '#F0ECE4',
  },
  image: {
    width: '100%',
    height: '100%',
  },
  discountBadge: {
    position: 'absolute',
    top: 10,
    left: 10,
    backgroundColor: COLORS.primary,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  discountText: {
    color: '#FFF',
    fontSize: 11,
    fontWeight: '700',
  },
  packagingBadge: {
    position: 'absolute',
    top: 10,
    right: 10,
    backgroundColor: 'rgba(31, 31, 31, 0.85)',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 4,
  },
  packagingText: {
    color: COLORS.accentGoldLight,
    fontSize: 11,
    fontWeight: '600',
  },
  content: {
    padding: 14,
  },
  shopName: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginBottom: 4,
  },
  title: {
    fontSize: 15,
    fontWeight: '700',
    color: COLORS.textPrimary,
    lineHeight: 20,
    minHeight: 40,
    marginBottom: 8,
  },
  metaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  ratingBox: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  ratingText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginLeft: 4,
    fontWeight: '600',
  },
  moqText: {
    fontSize: 12,
    color: COLORS.textMuted,
  },
  footerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    borderTopWidth: 1,
    borderTopColor: COLORS.border,
    paddingTop: 10,
  },
  priceLabel: {
    fontSize: 11,
    color: COLORS.textMuted,
  },
  price: {
    fontSize: 16,
    fontWeight: '800',
    color: COLORS.primary,
  },
  actionBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: 'rgba(140, 21, 36, 0.08)',
    justifyContent: 'center',
    alignItems: 'center',
  },
});
