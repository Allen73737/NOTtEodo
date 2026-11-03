/// Enterprise Environment Flavor
enum AppEnvironment { development, staging, production }

/// Centralized Enterprise Configuration & Feature Flags
class AppConfig {
  static const String appName = 'NOTTeodo Sanctuary';
  static const String appVersion = '1.0.0+1';
  static const String schemaVersion = '2026.09';

  static AppEnvironment get environment {
    const envStr = String.fromEnvironment('APP_ENV', defaultValue: 'production');
    switch (envStr.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
      default:
        return AppEnvironment.production;
    }
  }

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isDevelopment => environment == AppEnvironment.development;

  // Supabase Configuration with Secure Environment Ingestion & Runtime Resolution
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zjmxwttdkvhiuampirwa.supabase.co',
  );

  // AI provider keys never ship in the app: the `ai-assist` edge function holds them.

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_5HFXNaUjrzusoPYEtdtAQw_taum_OxL',
  );

  static String? _overrideSupabaseUrl;
  static String? _overrideSupabasePublishableKey;

  static void configure({String? url, String? anonKey}) {
    if (url != null && url.isNotEmpty) _overrideSupabaseUrl = url;
    if (anonKey != null && anonKey.isNotEmpty) _overrideSupabasePublishableKey = anonKey;
  }

  static String get resolvedSupabaseUrl =>
      (_overrideSupabaseUrl != null && _overrideSupabaseUrl!.isNotEmpty)
          ? _overrideSupabaseUrl!
          : supabaseUrl;

  static String get resolvedSupabasePublishableKey =>
      (_overrideSupabasePublishableKey != null && _overrideSupabasePublishableKey!.isNotEmpty)
          ? _overrideSupabasePublishableKey!
          : supabasePublishableKey;

  // Enterprise Security Limits & Policies
  static const int maxFailedAuthAttempts = 5;
  static const Duration authLockoutDuration = Duration(minutes: 15);
  static const Duration ephemeralClipboardTimeout = Duration(seconds: 30);
  static const Duration sessionInactivityTimeout = Duration(minutes: 30);
  static const int auditLogRetentionLimit = 1000;
  static const int maxOfflineQueueItems = 500;

  // Feature Flags
  static const bool enableLocalVectorSearch = true;
  static const bool enableZkpAuditProofs = true;
  static const bool enableAuditHashChaining = true;
  static const bool enableOfflineSyncQueue = true;
  static const bool enableClientSideEncryption = true;
}
