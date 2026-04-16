import 'package:doordesk/models/order_draft.dart';

/// Kombinierbare Auftragslisten-Filter (Auftragsarten, Status / Aktivität).
class OrderListFilter {
  const OrderListFilter({
    this.includeTueren = false,
    this.includeMoebel = false,
    this.includeRestauration = false,
    this.includeInnenausbau = false,
    this.includeAnderes = false,
    this.includeEntwurf = false,
    this.includeInBearbeitung = false,
    this.includeAbgeschlossen = false,
  });

  final bool includeTueren;
  final bool includeMoebel;
  final bool includeRestauration;
  final bool includeInnenausbau;
  final bool includeAnderes;

  /// Status „Entwurf“, „In Bearbeitung“ (Aktivität), „Abgeschlossen“.
  final bool includeEntwurf;
  final bool includeInBearbeitung;
  final bool includeAbgeschlossen;

  /// Kein Filter: alle Kästchen aus (wie „Zurücksetzen“).
  static const OrderListFilter cleared = OrderListFilter();

  bool get hasActiveFilter {
    final tAllOff = !includeTueren &&
        !includeMoebel &&
        !includeRestauration &&
        !includeInnenausbau &&
        !includeAnderes;
    final tAllOn = includeTueren &&
        includeMoebel &&
        includeRestauration &&
        includeInnenausbau &&
        includeAnderes;
    final typeActive = !tAllOff && !tAllOn;

    final sAllOff =
        !includeEntwurf && !includeInBearbeitung && !includeAbgeschlossen;
    final sAllOn =
        includeEntwurf && includeInBearbeitung && includeAbgeschlossen;
    final statusActive = !sAllOff && !sAllOn;

    return typeActive || statusActive;
  }

  bool matches(OrderDraft o) => matchesType(o) && matchesStatus(o);

  bool matchesType(OrderDraft o) {
    final none = !includeTueren &&
        !includeMoebel &&
        !includeRestauration &&
        !includeInnenausbau &&
        !includeAnderes;
    if (none) return true;
    return switch (o.orderType) {
      OrderDraftType.tueren => includeTueren,
      OrderDraftType.moebel => includeMoebel,
      OrderDraftType.restauration => includeRestauration,
      OrderDraftType.innenausbau => includeInnenausbau,
      OrderDraftType.anderes => includeAnderes,
    };
  }

  bool matchesStatus(OrderDraft o) {
    final none =
        !includeEntwurf && !includeInBearbeitung && !includeAbgeschlossen;
    if (none) return true;
    return switch (o.status) {
      OrderDraftStatus.entwurf => includeEntwurf,
      OrderDraftStatus.inBearbeitung => includeInBearbeitung,
      OrderDraftStatus.abgeschlossen => includeAbgeschlossen,
    };
  }

  OrderListFilter copyWith({
    bool? includeTueren,
    bool? includeMoebel,
    bool? includeRestauration,
    bool? includeInnenausbau,
    bool? includeAnderes,
    bool? includeEntwurf,
    bool? includeInBearbeitung,
    bool? includeAbgeschlossen,
  }) {
    return OrderListFilter(
      includeTueren: includeTueren ?? this.includeTueren,
      includeMoebel: includeMoebel ?? this.includeMoebel,
      includeRestauration: includeRestauration ?? this.includeRestauration,
      includeInnenausbau: includeInnenausbau ?? this.includeInnenausbau,
      includeAnderes: includeAnderes ?? this.includeAnderes,
      includeEntwurf: includeEntwurf ?? this.includeEntwurf,
      includeInBearbeitung: includeInBearbeitung ?? this.includeInBearbeitung,
      includeAbgeschlossen: includeAbgeschlossen ?? this.includeAbgeschlossen,
    );
  }
}
