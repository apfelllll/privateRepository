/// Zeile aus `public.hours` — gleicher Datensatz für Persönlich & Auftrags-Stundenzettel.
class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.orderId,
    required this.workDate,
    required this.hours,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String companyId;
  final String userId;
  final String orderId;
  final DateTime workDate;
  final double hours;
  final String notes;
  final DateTime createdAt;

  factory TimeEntry.fromRow(Map<String, dynamic> row) {
    final wd = row['work_date'] as String;
    return TimeEntry(
      id: row['id'] as String,
      companyId: row['company_id'] as String,
      userId: row['user_id'] as String,
      orderId: row['order_id'] as String,
      workDate: DateTime.parse(wd),
      hours: (row['hours'] as num).toDouble(),
      notes: row['notes'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  TimeEntry copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? orderId,
    DateTime? workDate,
    double? hours,
    String? notes,
    DateTime? createdAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      workDate: workDate ?? this.workDate,
      hours: hours ?? this.hours,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
