import 'package:doordesk/models/order_time_entry.dart';
import 'package:doordesk/models/user_role.dart';

/// Profildaten ( später mit Supabase `profiles` synchron ).
class DoorDeskUser {
  const DoorDeskUser({
    required this.id,
    required this.companyId,
    required this.email,
    required this.displayName,
    required this.role,
    this.phone,
    /// Später z. B. aus `public.users` — Meister/Geselle für Stundenlisten.
    this.craftQualification,
  });

  final String id;
  final String companyId;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phone;

  /// Meister/Geselle für AZE; `null` = bis zur DB-Anbindung (Fallback: Geselle).
  final OrderTimeEmployeeQualification? craftQualification;

  DoorDeskUser copyWith({
    String? id,
    String? companyId,
    String? email,
    String? displayName,
    UserRole? role,
    String? phone,
    OrderTimeEmployeeQualification? craftQualification,
  }) {
    return DoorDeskUser(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      craftQualification: craftQualification ?? this.craftQualification,
    );
  }
}
