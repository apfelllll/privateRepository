/// Rollenmodell DoorDesk (Discord-artige Erweiterung für SuperAdmin geplant).
///
/// In Supabase (`public.users.role`) gespeichert als Kleinbuchstaben-Strings:
/// `mitarbeiter`, `admin`, `superadmin`.
enum UserRole {
  /// Geselle & Azubi
  mitarbeiter,

  /// Chef & Sekretärin — volle betriebliche Verwaltung
  admin,

  /// Geschäftsführer — inkl. Benutzer & Rechteverwaltung
  superAdmin,
}

/// Parst die Spalte `public.users.role`.
UserRole userRoleFromDatabase(String raw) {
  switch (raw.toLowerCase().trim()) {
    case 'mitarbeiter':
      return UserRole.mitarbeiter;
    case 'admin':
      return UserRole.admin;
    case 'superadmin':
      return UserRole.superAdmin;
    default:
      throw FormatException('Unbekannte Rolle: $raw');
  }
}

extension UserRoleStorage on UserRole {
  /// Wert für die Datenbank-Spalte `role`.
  String get databaseValue => switch (this) {
        UserRole.mitarbeiter => 'mitarbeiter',
        UserRole.admin => 'admin',
        UserRole.superAdmin => 'superadmin',
      };
}

extension UserRoleLabel on UserRole {
  String get displayNameDe => switch (this) {
        UserRole.mitarbeiter => 'Mitarbeiter',
        UserRole.admin => 'Admin',
        UserRole.superAdmin => 'Super-Admin',
      };
}
