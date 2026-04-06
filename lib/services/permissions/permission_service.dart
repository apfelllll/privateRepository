import 'package:doordesk/models/user_role.dart';

/// Zentrale RBAC-Hilfen — UI und Services orientieren sich daran.
abstract final class PermissionService {
  static bool canViewOwnTimesOnly(UserRole role) => role == UserRole.mitarbeiter;

  static bool canViewAllEmployeeHours(UserRole role) =>
      role == UserRole.admin || role == UserRole.superAdmin;

  static bool canCreateAndManageOrders(UserRole role) =>
      role == UserRole.admin || role == UserRole.superAdmin;

  static bool canManageCompanyCalendar(UserRole role) =>
      role == UserRole.admin || role == UserRole.superAdmin;

  static bool canManageMaterials(UserRole role) =>
      role == UserRole.admin || role == UserRole.superAdmin;

  /// Buchhaltung ( später eigener Bereich ) — Mitarbeiter ausgeschlossen.
  static bool canAccessAccounting(UserRole role) =>
      role == UserRole.admin || role == UserRole.superAdmin;

  static bool canCreateUsers(UserRole role) => role == UserRole.superAdmin;

  static bool canAssignRoles(UserRole role) => role == UserRole.superAdmin;

  static bool canViewOtherEmployeesData(UserRole role) =>
      role == UserRole.admin || role == UserRole.superAdmin;

  static String roleDescriptionDe(UserRole role) => switch (role) {
        UserRole.mitarbeiter =>
          'Startseite, Aufträge, Kalender, eigene Zeiten, Profil — keine Fremddaten.',
        UserRole.admin =>
          'Alle Bereiche inkl. Aufträge, Team-Zeiten, Material, Kalender.',
        UserRole.superAdmin =>
          'Voller Zugriff inkl. Benutzer anlegen und Rollen vergeben.',
      };
}
