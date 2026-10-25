// Configuration for Supabase backend
class SupabaseConfig {
  // Injected at build/run time via --dart-define=SUPABASE_URL=...
  // Reads from GitHub environment secrets or CI/CD variables in production
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  // Injected at build/run time via --dart-define=SUPABASE_ANON_KEY=...
  // Reads from GitHub environment secrets or CI/CD variables in production
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Storage bucket name for receipt images
  static const String receiptsBucket = 'Receipts';

  // Edge function name for OCR receipt analysis
  static const String parseReceiptFunction = 'parse-receipt';

  // Allow tests or debug environments to force offline demo mode
  static bool forceDemoMode = false;

  // Demo mode enabled if credentials are not provided, placeholders, or forced
  static bool get isDemoMode =>
      forceDemoMode ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey.isEmpty ||
      supabaseUrl.contains('xyzcompany') ||
      supabaseAnonKey.contains('placeholder');
}
