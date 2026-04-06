import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase-Start — URLs/Keys per `--dart-define=SUPABASE_URL=...` setzen.
abstract final class SupabaseConfig {
  static const _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'DoorDesk: Supabase nicht konfiguriert (SUPABASE_URL / SUPABASE_ANON_KEY). '
          'Auth-Client nutzt Platzhalter — Session kommt aus lokalem Mock.',
        );
      }
      return;
    }
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  /// Null, wenn nicht initialisiert — Services prüfen vor Nutzung.
  static SupabaseClient? get clientOrNull {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } on Exception {
      return null;
    }
  }
}
