import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://louwovfikbuyqopfmurn.supabase.co',
  );
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_d7f6uF4p6jxLBnnObAl9bw_HSRlmFTA',
  );

  static bool _initialized = false;

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<bool> initialize() async {
    if (_initialized) return isConfigured;
    if (!isConfigured) {
      _initialized = true;
      return false;
    }

    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
    _initialized = true;
    return true;
  }
}
