/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{ts,tsx}', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#F5F3FF',
          100: '#EDE9FE',
          200: '#DDD6FE',
          300: '#C4B5FD',
          400: '#A78BFA',
          500: '#8B5CF6',
          600: '#7C3AED',
          700: '#6D28D9',
          800: '#5B21B6',
          900: '#4C1D95',
        },
        dark: {
          bg: '#0A0A0F',
          surface: '#12121A',
          card: '#1A1A2E',
          border: '#1F2937',
          text: '#F9FAFB',
          muted: '#6B7280',
        },
        light: {
          bg: '#FFFFFF',
          surface: '#F9FAFB',
          card: '#FFFFFF',
          border: '#E5E7EB',
          text: '#111827',
          muted: '#9CA3AF',
        },
      },
      fontFamily: {
        sans: ['System'],
      },
      borderRadius: {
        sm: '8px',
        md: '12px',
        lg: '16px',
        xl: '24px',
      },
    },
  },
  plugins: [],
};
