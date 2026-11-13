import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, StatusBar } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { COLORS } from '../../theme/colors';

/**
 * Compact white header shared by every stack/tab screen — same look as the redesigned
 * home, orders and RFQ screens (white bar, brand-red icons, sentence-case title).
 * Props are unchanged so existing screens keep working.
 */
export default function AppHeader({
  title,
  subtitle,
  showBack = false,
  onBack,
  rightIcon,
  onRightPress,
  rightLabel,
}) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top + 8 }]}>
      <StatusBar barStyle="dark-content" backgroundColor={COLORS.surface} />
      {showBack ? (
        <TouchableOpacity onPress={onBack} style={styles.iconButton} accessibilityLabel="Quay lại" hitSlop={6}>
          <Ionicons name="arrow-back" size={22} color={COLORS.primary} />
        </TouchableOpacity>
      ) : (
        <View style={styles.leadingSpacer} />
      )}

      <View style={styles.titleBlock}>
        <Text style={styles.title} numberOfLines={1}>{title}</Text>
        {subtitle ? <Text style={styles.subtitle} numberOfLines={1}>{subtitle}</Text> : null}
      </View>

      {rightIcon ? (
        <TouchableOpacity onPress={onRightPress} style={styles.iconButton} accessibilityLabel={rightLabel || title} hitSlop={6}>
          <Ionicons name={rightIcon} size={22} color={COLORS.primary} />
        </TouchableOpacity>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingBottom: 8,
    backgroundColor: COLORS.surface,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: COLORS.border,
  },
  iconButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  leadingSpacer: {
    width: 8,
  },
  titleBlock: {
    flex: 1,
    minWidth: 0,
  },
  title: {
    color: COLORS.textPrimary,
    fontSize: 18,
    fontWeight: '600',
  },
  subtitle: {
    marginTop: 1,
    color: COLORS.textMuted,
    fontSize: 12,
  },
});
