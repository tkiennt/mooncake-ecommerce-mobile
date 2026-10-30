import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { COLORS } from '../../theme/colors';

export default function CustomButton({
  title,
  onPress,
  variant = 'primary', // primary | secondary | outline
  size = 'medium',     // small | medium | large
  loading = false,
  disabled = false,
  icon,
  style,
}) {
  const getBackgroundColor = () => {
    if (disabled) return COLORS.border;
    if (variant === 'primary') return COLORS.primary;
    if (variant === 'secondary') return COLORS.accent;
    if (variant === 'outline') return 'transparent';
    return COLORS.primary;
  };

  const getTextColor = () => {
    if (disabled) return COLORS.textMuted;
    if (variant === 'outline') return COLORS.primary;
    if (variant === 'secondary') return '#FFFFFF';
    return COLORS.textWhite;
  };

  return (
    <TouchableOpacity
      style={[
        styles.button,
        styles[size],
        {
          backgroundColor: getBackgroundColor(),
          borderColor: variant === 'outline' ? COLORS.primary : 'transparent',
          borderWidth: variant === 'outline' ? 1.5 : 0,
        },
        style,
      ]}
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.8}
    >
      {loading ? (
        <ActivityIndicator color={getTextColor()} size="small" />
      ) : (
        <>
          {icon ? <Text style={styles.icon}>{icon}</Text> : null}
          <Text style={[styles.text, { color: getTextColor() }]}>{title}</Text>
        </>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  small: {
    paddingVertical: 8,
    paddingHorizontal: 14,
  },
  medium: {
    paddingVertical: 12,
    paddingHorizontal: 18,
  },
  large: {
    paddingVertical: 15,
    paddingHorizontal: 24,
  },
  text: {
    fontWeight: '700',
    fontSize: 15,
    letterSpacing: 0.3,
  },
  icon: {
    marginRight: 8,
  },
});

