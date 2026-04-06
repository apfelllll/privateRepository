import 'package:doordesk/models/assigned_order.dart';
import 'package:doordesk/models/time_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stundenzettel + Realtime-Stream (`hours`).
class HoursService {
  HoursService(this._client);

  final SupabaseClient _client;

  /// Aufträge, die der Nutzer buchen darf (Zuordnung oder Admin über RLS ).
  Future<List<AssignedOrder>> fetchAssignedOrders() async {
    final rows = await _client
        .from('orders')
        .select('id, title')
        .eq('status', 'active')
        .order('title');
    return (rows as List<dynamic>)
        .map((e) => AssignedOrder.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Alle Buchungen des Nutzers im Kalendermonat (klassische Abfrage — stabil ).
  Future<List<TimeEntry>> fetchHoursForMonth(
    String userId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    final rows = await _client
        .from('hours')
        .select(
          'id, company_id, user_id, order_id, work_date, hours, notes, created_at',
        )
        .eq('user_id', userId)
        .gte('work_date', _dateOnly(start))
        .lte('work_date', _dateOnly(end))
        .order('work_date', ascending: true)
        .order('created_at', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => TimeEntry.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<TimeEntry> insert({
    required String companyId,
    required String userId,
    required String orderId,
    required DateTime workDate,
    required double hours,
    required String notes,
  }) async {
    final row = await _client
        .from('hours')
        .insert({
          'company_id': companyId,
          'user_id': userId,
          'order_id': orderId,
          'work_date': _dateOnly(workDate),
          'hours': hours,
          'notes': notes,
        })
        .select()
        .single();
    return TimeEntry.fromRow(Map<String, dynamic>.from(row));
  }

  Future<void> updateEntry({
    required String id,
    required String orderId,
    required DateTime workDate,
    required double hours,
    required String notes,
  }) async {
    await _client.from('hours').update({
      'order_id': orderId,
      'work_date': _dateOnly(workDate),
      'hours': hours,
      'notes': notes,
    }).eq('id', id);
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('hours').delete().eq('id', id);
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
