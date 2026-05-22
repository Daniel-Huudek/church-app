import { Platform } from 'react-native';

const fontFamily = Platform.select({
  ios: {
    regular: 'System',
    medium: 'System',
    semibold: 'System',
    bold: 'System',
  },
  android: {
    regular: 'Roboto',
    medium: 'Roboto',
    semibold: 'Roboto',
    bold: 'Roboto',
  },
  default: {
    regular: 'System',
    medium: 'System',
    semibold: 'System',
    bold: 'System',
  },
});

export const typography = {
  fontFamily,
  fontSize: {
    xs: 12,
    sm: 14,
    md: 16,
    lg: 18,
    xl: 20,
    '2xl': 24,
    '3xl': 30,
    '4xl': 36,
    '5xl': 48,
  },
  fontWeight: {
    regular: '400' as const,
    medium: '500' as const,
    semibold: '600' as const,
    bold: '700' as const,
  },
  lineHeight: {
    xs: 16,
    sm: 20,
    md: 24,
    lg: 28,
    xl: 28,
    '2xl': 32,
    '3xl': 36,
    '4xl': 44,
    '5xl': 56,
  },
  letterSpacing: {
    tighter: -0.8,
    tight: -0.4,
    normal: 0,
    wide: 0.4,
    wider: 0.8,
    widest: 1.6,
  },
  text: {
    xs: {
      fontSize: 12,
      lineHeight: 16,
      fontFamily: fontFamily.regular,
    },
    sm: {
      fontSize: 14,
      lineHeight: 20,
      fontFamily: fontFamily.regular,
    },
    md: {
      fontSize: 16,
      lineHeight: 24,
      fontFamily: fontFamily.regular,
    },
    lg: {
      fontSize: 18,
      lineHeight: 28,
      fontFamily: fontFamily.regular,
    },
    xl: {
      fontSize: 20,
      lineHeight: 28,
      fontFamily: fontFamily.regular,
    },
    '2xl': {
      fontSize: 24,
      lineHeight: 32,
      fontFamily: fontFamily.bold,
    },
    '3xl': {
      fontSize: 30,
      lineHeight: 36,
      fontFamily: fontFamily.bold,
    },
    '4xl': {
      fontSize: 36,
      lineHeight: 44,
      fontFamily: fontFamily.bold,
    },
    '5xl': {
      fontSize: 48,
      lineHeight: 56,
      fontFamily: fontFamily.bold,
    },
  },
} as const;

export type FontSizeKey = keyof typeof typography.fontSize;
export type FontWeightKey = keyof typeof typography.fontWeight;
export type LineHeightKey = keyof typeof typography.lineHeight;
export type LetterSpacingKey = keyof typeof typography.letterSpacing;
export type TextStyleKey = keyof typeof typography.text;
