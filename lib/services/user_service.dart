import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/models/user_role.dart' show userRoleFromDatabase;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Liest das Profil aus `public.users` (nicht auth.users).
class UserService {
  UserService(this._client);

  final SupabaseClient _client;

  Future<DoorDeskUser> fetchDoorDeskUser(String authUserId) async {
    final row = await _client
        .from('users')
        .select('id, company_id, role, name, email')
        .eq('id', authUserId)
        .maybeSingle();

    if (row == null) {
      throw UserProfileMissingException(authUserId);
    }

    return DoorDeskUser(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      email: row['email'] as String,
      displayName: row['name'] as String,
      role: userRoleFromDatabase(row['role'] as String),
      phone: null,
    );
  }
}

/// Kein Datensatz in `public.users` trotz gültiger Auth-Session.
class UserProfileMissingException implements Exception {
  UserProfileMissingException(this.authUserId);

  final String authUserId;

  @override
  String toString() =>
      'Kein Eintrag in der Tabelle „users“ für diese Auth-User-ID. '
      'Bitte Profil im Dashboard anlegen (siehe Anleitung).';
}
