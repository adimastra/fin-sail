// Configuration for Supabase backend
class SupabaseConfig {
  // Injected at build/run time via --dart-define=SUPABASE_URL=...
  // Reads from GitHub environment secrets or CI/CD variables in production
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xywhladlyekplqvpiozg.supabase.co',
  );

  // Injected at build/run time via --dart-define=SUPABASE_ANON_KEY=...
  // Reads from GitHub environment secrets or CI/CD variables in production
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5d2hsYWRseWVrcGxxdnBpb3pnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI4NTAwNjIsImV4cCI6MjEwODQyNjA2Mn0.zjxxCUMquJuo7GGfhq2N67VrdH2qdSwrCnAN6yftb-w',
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
