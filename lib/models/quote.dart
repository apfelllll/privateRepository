import 'package:doordesk/models/invoice.dart';
import 'package:doordesk/models/order_draft.dart';

/// Status eines Angebots.
///
/// Aktuell halten wir nur `entwurf` aktiv befüllt — alle anderen Stufen sind
/// bereits vorgesehen, damit spätere Flows (Versand, Kundenentscheidung,
/// Umwandlung in einen Auftrag/eine Rechnung) ohne Schema-Migration
/// nachgezogen werden können.
enum QuoteStatus { entwurf, versendet, angenommen, abgelehnt }

extension QuoteStatusDisplay on QuoteStatus {
  String get displayLabel => switch (this) {
    QuoteStatus.entwurf => 'Entwurf',
    QuoteStatus.versendet => 'Versendet',
    QuoteStatus.angenommen => 'Angenommen',
    QuoteStatus.abgelehnt => 'Abgelehnt',
  };
}

/// Positionsart — identisch zu [InvoiceLineKind], damit ein angenommenes
/// Angebot später ohne Konvertierung als Grundlage für eine Rechnung dienen
/// kann.
typedef QuoteLineKind = InvoiceLineKind;

/// Eine einzelne Angebotsposition.
///
/// Struktur bewusst deckungsgleich mit [InvoiceLineItem], damit der
/// Rechnungs-Editor eine Kopie einer Angebots-Zeile 1:1 übernehmen kann
/// (Snapshot-Prinzip).
class QuoteLineItem {
  const QuoteLineItem({
    required this.id,
    required this.kind,
    required this.active,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.unit = '',
  });

  /// Lokale ID, stabil beim Editieren einer Zeile.
  final String id;

  final QuoteLineKind kind;

  /// `false` = Zeile zählt nicht in die Gesamtsumme und wird im UI als
  /// deaktiviert dargestellt.
  final bool active;

  final String description;

  /// Arbeit: Stunden (0.25er-Raster möglich). Material/Frei: Menge.
  final double quantity;

  /// EUR netto pro Einheit/Stunde.
  final double unitPrice;

  /// Nur für Material relevant („Stk", „m", „kg", ...).
  final String unit;

  /// Zeilensumme netto — deaktivierte Zeilen zählen mit 0.
  double get lineTotal => active ? quantity * unitPrice : 0;

  QuoteLineItem copyWith({
    String? id,
    QuoteLineKind? kind,
    bool? active,
    String? description,
    double? quantity,
    double? unitPrice,
    String? unit,
  }) {
    return QuoteLineItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      active: active ?? this.active,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
    );
  }
}

/// Ein Angebot — Snapshot aus einem Auftrag, unabhängig vom Original
/// editierbar.
///
/// Angebote werden in der aktuellen Ausbaustufe typischerweise VOR dem
/// eigentlichen Auftragsbeginn erstellt. Der Auftrag selbst dient derzeit
/// bereits als Verknüpfungs-Anker (Kunde + Nummer + Titel), damit die
/// spätere Umwandlung in eine Rechnung einfach bleibt.
class Quote {
  const Quote({
    required this.id,
    required this.quoteNumber,
    required this.createdAt,
    required this.status,
    required this.orderCreatedAt,
    required this.orderNumber,
    required this.orderTitle,
    required this.customer,
    required this.lines,
    this.title = '',
    this.notes = '',
    this.validUntil,
    this.sentAt,
    this.decidedAt,
  });

  /// Lokale ID (bis Supabase-Anbindung).
  final String id;

  /// Sichtbare Angebotsnummer (z. B. `Q-00001`).
  final String quoteNumber;

  final DateTime createdAt;

  final QuoteStatus status;

  /// Optionaler Titel des Angebots (z. B. „Türerneuerung Erdgeschoss").
  /// Default: leer — wird beim Anlegen aus dem Auftragstitel übernommen.
  final String title;

  /// Freitext-Anmerkung an den Kunden (Angebotstext, Rahmenbedingungen ...).
  final String notes;

  /// Gültigkeitsdatum (bis wann das Angebot verbindlich ist). Optional.
  final DateTime? validUntil;

  /// Wird beim Versand an den Kunden gesetzt. Im Entwurf `null`.
  final DateTime? sentAt;

  /// Wird beim Angenommen/Abgelehnt-Status gesetzt. Sonst `null`.
  final DateTime? decidedAt;

  /// Verknüpfung zum zugehörigen [OrderDraft] (über `createdAt` als ID).
  final DateTime orderCreatedAt;

  /// Kopie zum Erstellungszeitpunkt — für Anzeige auch dann, wenn der Auftrag
  /// später umbenannt wurde.
  final String orderNumber;
  final String orderTitle;

  /// Snapshot der Rechnungsdaten des Kunden (wiederverwendet aus dem
  /// Rechnungsmodell — identische Felder).
  final InvoiceCustomerSnapshot customer;

  final List<QuoteLineItem> lines;

  /// Gesamtsumme netto — nur aktive Zeilen.
  double get netTotal => lines.fold<double>(0, (s, l) => s + l.lineTotal);

  /// Teilsumme für eine bestimmte Positionsart (z. B. nur Arbeit).
  double subtotalFor(QuoteLineKind kind) => lines
      .where((l) => l.kind == kind)
      .fold<double>(0, (s, l) => s + l.lineTotal);

  List<QuoteLineItem> linesOf(QuoteLineKind kind) =>
      lines.where((l) => l.kind == kind).toList();

  Quote copyWith({
    String? id,
    String? quoteNumber,
    DateTime? createdAt,
    QuoteStatus? status,
    String? title,
    String? notes,
    DateTime? validUntil,
    DateTime? sentAt,
    DateTime? decidedAt,
    DateTime? orderCreatedAt,
    String? orderNumber,
    String? orderTitle,
    InvoiceCustomerSnapshot? customer,
    List<QuoteLineItem>? lines,
  }) {
    return Quote(
      id: id ?? this.id,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      validUntil: validUntil ?? this.validUntil,
      sentAt: sentAt ?? this.sentAt,
      decidedAt: decidedAt ?? this.decidedAt,
      orderCreatedAt: orderCreatedAt ?? this.orderCreatedAt,
      orderNumber: orderNumber ?? this.orderNumber,
      orderTitle: orderTitle ?? this.orderTitle,
      customer: customer ?? this.customer,
      lines: lines ?? this.lines,
    );
  }

  /// Legt einen leeren Angebots-Entwurf zu einem Auftrag an.
  ///
  /// Es werden absichtlich keine Positionen vorbefüllt — Angebote werden in
  /// der Regel vor Arbeitsbeginn manuell geschrieben (im Gegensatz zu
  /// Rechnungen, die aus erfassten Arbeitszeiten gespeist werden).
  factory Quote.emptyFromOrder({
    required OrderDraft order,
    required String quoteNumber,
    required DateTime createdAt,
  }) {
    return Quote(
      id: 'qte_${createdAt.microsecondsSinceEpoch}',
      quoteNumber: quoteNumber,
      createdAt: createdAt,
      status: QuoteStatus.entwurf,
      title: order.title,
      orderCreatedAt: order.createdAt,
      orderNumber: order.orderNumber,
      orderTitle: order.title,
      customer: InvoiceCustomerSnapshot.fromCustomer(order.customer),
      lines: const <QuoteLineItem>[],
    );
  }
}

/// Wandelt ein Angebot in einen Rechnungs-Entwurf um.
///
/// - Positionen werden 1:1 übernommen (Snapshot-Prinzip — spätere Änderungen
///   am Angebot wirken NICHT auf die Rechnung).
/// - Arbeitszeiten-Meta (`employeeName`, `workDate`, `sourceTimeEntryId`) bleibt
///   leer: Angebote enthalten keine realen Zeiterfassungs-Referenzen.
extension QuoteToInvoice on Quote {
  Invoice toInvoiceDraft({
    required String invoiceNumber,
    required DateTime createdAt,
  }) {
    final invoiceLines = <InvoiceLineItem>[
      for (final l in lines)
        InvoiceLineItem(
          id: 'fromquote_${l.id}',
          kind: l.kind,
          active: l.active,
          description: l.description,
          quantity: l.quantity,
          unitPrice: l.unitPrice,
          unit: l.unit,
        ),
    ];
    return Invoice(
      id: 'inv_${createdAt.microsecondsSinceEpoch}',
      invoiceNumber: invoiceNumber,
      createdAt: createdAt,
      status: InvoiceStatus.entwurf,
      orderCreatedAt: orderCreatedAt,
      orderNumber: orderNumber,
      orderTitle: orderTitle,
      customer: customer,
      introText: kDefaultInvoiceIntroBody,
      lines: invoiceLines,
    );
  }
}
