import 'package:doordesk/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth: Anmeldung, Abmeldung, Session.
class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentAuthUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase ist nicht konfiguriert. Start mit SUPABASE_URL und SUPABASE_ANON_KEY.',
      );
    }
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}
