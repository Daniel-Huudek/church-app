class AppConstants {
  AppConstants._();

  // Storage keys
  static const String accessTokenKey = '@church_app_access_token';
  static const String refreshTokenKey = '@church_app_refresh_token';
  static const String userKey = '@church_app_user';
  static const String themeKey = '@church_app_theme';
  static const String onboardingKey = '@church_app_onboarding';

  // App info
  static const String appName = 'IPI Avaré';
  static const String appTagline = 'Igreja Presbiteriana de Avaré';

  // Roles
  static const String roleAdmin = 'ADMINISTRADOR';
  static const String rolePastor = 'PASTOR';
  static const String roleFinanceiro = 'FINANCEIRO';
  static const String roleLider = 'LIDER';
  static const String roleMembro = 'MEMBRO';

  // Pagination
  static const int defaultPageSize = 20;

  // Date format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
}
