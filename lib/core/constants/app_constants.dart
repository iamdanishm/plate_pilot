class AppConstants {
  // Application Info
  static const String appName = 'PlatePilot';
  static const String appTagline = 'Your week of meals, figured out.';
  static const String appVersion = '0.1.0';

  // Environment Keys
  static const String envSupabaseUrl = 'SUPABASE_URL';
  static const String envSupabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String envSupabasePublishableKey = 'SUPABASE_PUBLISHABLE_KEY';

  // Storage / Preferences Keys
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keySelectedHouseholdId = 'selected_household_id';
  static const String keyThemeMode = 'theme_mode';

  // Timeouts & Durations
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Defaults
  static const String defaultCurrencySymbol = '₹';
  static const int defaultHouseholdSize = 2;
  static const int defaultMaxCookingTimeMinutes = 45;
  static const double defaultWeeklyBudget = 3000.0;
}
