/// Qualifikation für Stundenlohn / Abrechnung: Meister oder Geselle.
enum OrderTimeEmployeeQualification {
  meister,
  geselle;

  /// Anzeige in Klammern neben dem Namen.
  String get suffixLabel => switch (this) {
        meister => '(M)',
        geselle => '(G)',
      };
}

/// Lokale Arbeitszeiterfassung zu einem [OrderDraft] (ohne Supabase).
class OrderTimeEntry {
  const OrderTimeEntry({
    required this.id,
    required this.workDate,
    required this.activity,
    required this.startMinutes,
    required this.endMinutes,
    required this.pauseMinutes,
    required this.description,
    this.employeeName = '',
    this.qualification = OrderTimeEmployeeQualification.geselle,
  });

  final String id;

  /// Kalendertag (nur Datum relevant).
  final DateTime workDate;

  /// Tätigkeit (z. B. gleiche Liste wie „Neue Arbeitszeiterfassung“).
  final String activity;

  /// Minuten seit Mitternacht (0–24h).
  final int startMinutes;
  final int endMinutes;

  /// Gesamte Pause in Minuten.
  final int pauseMinutes;

  final String description;

  /// Erfasser der Zeile (Anzeige in der Stundenliste).
  final String employeeName;

  /// Steht mit [employeeName] in Klammern: (M) / (G).
  final OrderTimeEmployeeQualification qualification;

  /// Netto-Arbeitsdauer: Ende − Beginn − Pause (kann nicht negativ sein).
  Duration get netDuration {
    var span = endMinutes - startMinutes - pauseMinutes;
    if (span < 0) return Duration.zero;
    return Duration(minutes: span);
  }

  OrderTimeEntry copyWith({
    String? id,
    DateTime? workDate,
    String? activity,
    int? startMinutes,
    int? endMinutes,
    int? pauseMinutes,
    String? description,
    String? employeeName,
    OrderTimeEmployeeQualification? qualification,
  }) {
    return OrderTimeEntry(
      id: id ?? this.id,
      workDate: workDate ?? this.workDate,
      activity: activity ?? this.activity,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      pauseMinutes: pauseMinutes ?? this.pauseMinutes,
      description: description ?? this.description,
      employeeName: employeeName ?? this.employeeName,
      qualification: qualification ?? this.qualification,
    );
  }
}
