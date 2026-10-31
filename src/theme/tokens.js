/**
 * Nguyệt Phố B2B - Unified Design Tokens
 * Bridge giữa Ant Design v5 Component Tokens và Lucian UX/UI Micro-tokens
 * Giữ nguyên 100% theme Hoàng Gia: Crimson Luxury (#8C1524) & Imperial Gold (#D48806)
 */

import { COLORS } from './colors';

export const ANTD_TOKENS = {
  // Brand Base
  colorPrimary: COLORS.primary,
  colorPrimaryHover: COLORS.primaryLight,
  colorPrimaryActive: COLORS.primaryDark,
  colorPrimaryBg: '#FFF1F0',

  // Accent & Warnings
  colorWarning: COLORS.accent,
  colorWarningHover: COLORS.accentGoldLight,
  colorWarningBg: COLORS.accentGoldBg,

  // Neutrals & Surfaces
  colorBgContainer: COLORS.surface,
  colorBgLayout: COLORS.background,
  colorBgElevated: COLORS.surface,
  colorBorder: COLORS.border,
  colorBorderSecondary: COLORS.borderDark,

  // Text
  colorText: COLORS.textPrimary,
  colorTextSecondary: COLORS.textSecondary,
  colorTextTertiary: COLORS.textMuted,
  colorTextLightSolid: COLORS.textWhite,

  // Semantic Status
  colorSuccess: COLORS.success,
  colorSuccessBg: COLORS.successBg,
  colorError: COLORS.error,
  colorErrorBg: COLORS.errorBg,
  colorInfo: COLORS.info,
  colorInfoBg: COLORS.infoBg,

  // Shape Metrics
  borderRadiusXS: 2,
  borderRadiusSM: 4,
  borderRadius: 8,
  borderRadiusLG: 12,
  borderRadiusXL: 16,

  // Motion
  motionDurationFast: 150,
  motionDurationMid: 250,
  motionDurationSlow: 350,
};

export const LUCIAN_TOKENS = {
  // Lucian CSS variable bridge (--ux-*)
  primary: COLORS.primary,
  primaryDark: COLORS.primaryDark,
  primaryLight: COLORS.primaryLight,
  primaryTint: '#FFF1F0',

  accent: COLORS.accent,
  accentLight: COLORS.accentGoldLight,
  accentBg: COLORS.accentGoldBg,

  surface: COLORS.surface,
  surfaceElevated: COLORS.surface,
  bg: COLORS.background,
  border: COLORS.border,
  borderDark: COLORS.borderDark,

  text: COLORS.textPrimary,
  textSub: COLORS.textSecondary,
  textMuted: COLORS.textMuted,
  textInverse: COLORS.textWhite,

  // Radii
  radiusSm: 6,
  radiusMd: 10,
  radiusLg: 14,
  radiusXl: 20,
  radiusPill: 999,

  // Glows & Shadows
  glowGold: 'rgba(212, 136, 6, 0.28)',
  glowCrimson: 'rgba(140, 21, 36, 0.22)',
  shadowSubtle: {
    shadowColor: '#1F1F1F',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 4,
    elevation: 2,
  },
  shadowCard: {
    shadowColor: '#8C1524',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 10,
    elevation: 3,
  },
  shadowGold: {
    shadowColor: '#D48806',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
};

