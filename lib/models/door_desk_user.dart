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
  });

  final String id;
  final String companyId;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phone;

  DoorDeskUser copyWith({
    String? id,
    String? companyId,
    String? email,
    String? displayName,
    UserRole? role,
    String? phone,
  }) {
    return DoorDeskUser(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
    );
  }
}
