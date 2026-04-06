import 'package:doordesk/core/config/supabase_config.dart';
import 'package:doordesk/models/assigned_order.dart';
import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/models/time_entry.dart';
import 'package:doordesk/services/auth_service.dart';
import 'package:doordesk/services/hours_service.dart';
import 'package:doordesk/services/user_service.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live-Client; null wenn keine Dart-Defines gesetzt sind.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return AuthService(client);
});

final userServiceProvider = Provider<UserService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return UserService(client);
});

final hoursServiceProvider = Provider<HoursService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return HoursService(client);
});

/// Erster Tag des gerade gewählten Monats ( Stundenzettel ).
final selectedTimesheetMonthProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
});

/// Einträge des angemeldeten Nutzers für den gewählten Monat.
/// Live-Updates: [timesheetRealtimeSyncProvider] invalidiert diesen Provider.
final timesheetEntriesProvider =
    FutureProvider.autoDispose<List<TimeEntry>>((ref) async {
  final svc = ref.watch(hoursServiceProvider);
  final user = ref.watch(doorDeskSessionProvider).value;
  final month = ref.watch(selectedTimesheetMonthProvider);

  if (svc == null || user == null) {
    return <TimeEntry>[];
  }

  return svc.fetchHoursForMonth(user.id, month.year, month.month);
});

/// Realtime auf `public.hours` — bei Änderungen werden Zeiten neu geladen.
/// In der Zeiten-Ansicht mit [ref.watch] einbinden.
final timesheetRealtimeSyncProvider = Provider<Object?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(doorDeskSessionProvider).value;
  if (client == null || user == null) {
    return null;
  }

  final channel = client.channel('doordesk_hours_${user.id}');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'hours',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (_) {
          ref.invalidate(timesheetEntriesProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    unawaited(client.removeChannel(channel));
  });

  return null;
});

/// Aufträge für das Stunden-Dropdown ( RLS ).
final assignedOrdersProvider =
    FutureProvider.autoDispose<List<AssignedOrder>>((ref) async {
  final svc = ref.watch(hoursServiceProvider);
  if (svc == null) return [];
  try {
    return await svc.fetchAssignedOrders();
  } catch (_) {
    return [];
  }
});

/// Wenn true, blendet [MainShell] die globale Suchleiste aus (Auftrags- oder Kunden-Detail).
final hideShellTopSearchBarProvider = StateProvider<bool>((ref) => false);

/// Auftragsliste: [MainShell] zeigt den Filtern-Button rechts neben der Suchleiste.
final showShellOrdersFilterButtonProvider = StateProvider<bool>((ref) => false);

/// Auftragsliste: Statusfilter aktiv (Badge am Filtern-Icon).
final ordersListFilterActiveProvider = StateProvider<bool>((ref) => false);

/// Öffnet das Auftrags-Filter-Bottom-Sheet (von [OrdersPage] gesetzt).
final orderFilterShellOpenProvider = StateProvider<void Function()?>(
  (ref) => null,
);

/// Null: nicht angemeldet oder Supabase nicht konfiguriert.
/// Fehler z. B. wenn `public.users` keinen passenden Eintrag hat.
final doorDeskSessionProvider = StreamProvider<DoorDeskUser?>((ref) {
  if (!SupabaseConfig.isConfigured) {
    return Stream.value(null);
  }
  final client = ref.watch(supabaseClientProvider);
  final userService = ref.watch(userServiceProvider);
  if (client == null || userService == null) {
    return Stream.value(null);
  }

  return client.auth.onAuthStateChange.asyncMap((event) async {
    final session = event.session;
    if (session == null) return null;
    return userService.fetchDoorDeskUser(session.user.id);
  });
});
