import 'dart:async';
import 'package:fin_logs/config/supabase_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  SupabaseConfig.forceDemoMode = true;
  await testMain();
}
