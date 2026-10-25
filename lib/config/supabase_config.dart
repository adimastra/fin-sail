// Configuration for Supabase backend
class SupabaseConfig {
  // Replace these with your project credentials from Supabase Dashboard -> Settings -> API
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'public-anon-key-placeholder',
  );

  // Storage bucket name for receipt images
  static const String receiptsBucket = 'Receipts';

  // Edge function name for OCR receipt analysis
  static const String parseReceiptFunction = 'parse-receipt';

  // Demo mode enabled if credentials are left as placeholders
  static bool get isDemoMode =>
      supabaseUrl.contains('xyzcompany') ||
      supabaseAnonKey.contains('placeholder') ||
      supabaseUrl.isEmpty;
}
