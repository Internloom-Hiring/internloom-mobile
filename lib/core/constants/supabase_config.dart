import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Handles loading and accessing Supabase credentials safely.
class SupabaseConfig {
  SupabaseConfig._();

  static String get url {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return dotenv.env['SUPABASE_URL'] ?? 'https://your-project-id.supabase.co';
  }

  static String get anonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) return envKey;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-actual-anon-key-here';
  }

  static bool get isConfigured {
    return url.isNotEmpty &&
        !url.contains('your-project-id') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('your-actual-anon-key');
  }
}
