import 'package:doordesk/models/customer_draft.dart';

/// Kombinierbare Kundenlisten-Filter (Typ, Sortierung, Aktivität).
class CustomerListFilter {
  const CustomerListFilter({
    this.includePrivat = false,
    this.includeFirma = false,
    this.sortAlphabetically = false,
    this.onlyWithActiveOrder = false,
  });

  /// Privatkunden einschließen (Checkbox).
  final bool includePrivat;

  /// Firmenkunden einschließen (Checkbox).
  final bool includeFirma;

  /// Nach [CustomerDraft.displayTitle] sortieren statt nach Erfassung.
  final bool sortAlphabetically;

  /// Nur Kunden mit mindestens einem Auftrag im Status „In Bearbeitung“.
  final bool onlyWithActiveOrder;

  /// Kein Filter: alle Kästchen aus (wie „Zurücksetzen“).
  static const CustomerListFilter cleared = CustomerListFilter();

  /// Eingeschränkt von „alles anzeigen“ (Shell-Badge).
  bool get hasActiveFilter {
    if (sortAlphabetically || onlyWithActiveOrder) return true;
    final bothOff = !includePrivat && !includeFirma;
    final bothOn = includePrivat && includeFirma;
    if (bothOff || bothOn) return false;
    return true;
  }

  bool matchesKind(CustomerDraft c) {
    final none = !includePrivat && !includeFirma;
    if (none) return true;
    if (includePrivat && c.kind == CustomerKind.privat) return true;
    if (includeFirma && c.kind == CustomerKind.firma) return true;
    return false;
  }

  CustomerListFilter copyWith({
    bool? includePrivat,
    bool? includeFirma,
    bool? sortAlphabetically,
    bool? onlyWithActiveOrder,
  }) {
    return CustomerListFilter(
      includePrivat: includePrivat ?? this.includePrivat,
      includeFirma: includeFirma ?? this.includeFirma,
      sortAlphabetically: sortAlphabetically ?? this.sortAlphabetically,
      onlyWithActiveOrder: onlyWithActiveOrder ?? this.onlyWithActiveOrder,
    );
  }
}
