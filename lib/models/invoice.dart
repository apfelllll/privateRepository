import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/models/order_time_entry.dart';
import 'package:doordesk/services/calculation_settings.dart';

/// Status einer Rechnung.
///
/// `entwurf` = voll editierbar, `finalisiert` = schreibgeschuetzt.
/// Aenderungen nach der Finalisierung nur ueber eine neue Version oder eine
/// Gutschrift — diese Pfade sind bewusst noch nicht implementiert (Platzhalter).
enum InvoiceStatus { entwurf, finalisiert }

extension InvoiceStatusDisplay on InvoiceStatus {
  String get displayLabel => switch (this) {
    InvoiceStatus.entwurf => 'Entwurf',
    InvoiceStatus.finalisiert => 'Finalisiert',
  };
}

/// Positionsart — bestimmt Anzeige + Felder im Rechnungs-Editor.
///
/// - `arbeit`   = aus Zeiterfassung uebernommene Arbeitsposition (Stunden * Stundensatz)
/// - `material` = manuell gepflegte Material-/Artikelposition (Menge * Einzelpreis, mit Einheit)
/// - `frei`     = frei formulierte Position ohne Einheit
enum InvoiceLineKind { arbeit, material, frei }

extension InvoiceLineKindDisplay on InvoiceLineKind {
  String get displayLabel => switch (this) {
    InvoiceLineKind.arbeit => 'Arbeit',
    InvoiceLineKind.material => 'Material',
    InvoiceLineKind.frei => 'Freie Position',
  };
}

/// Eine einzelne Rechnungsposition.
///
/// Bewusst als flache Klasse mit `kind`-Diskriminator umgesetzt (statt sealed
/// Hierarchie), damit Listen-Editing, copyWith und spaetere Serialisierung
/// (PDF, XRechnung/ZUGFeRD) ohne Typ-Downcasts moeglich sind.
class InvoiceLineItem {
  const InvoiceLineItem({
    required this.id,
    required this.kind,
    required this.active,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.unit = '',
    this.employeeName = '',
    this.qualification,
    this.workDate,
    this.sourceTimeEntryId,
    // TODO XRechnung/ZUGFeRD: MwSt.-Satz pro Zeile (0.19 / 0.07 / 0).
    // Feld absichtlich noch nicht belegt — Gesamtsumme rechnet derzeit netto.
  });

  /// Lokale ID, stabil beim Editieren einer Zeile.
  final String id;

  final InvoiceLineKind kind;

  /// `false` = Zeile zaehlt nicht in die Gesamtsumme und wird im UI als
  /// deaktiviert dargestellt (z. B. „Mitarbeiter ausschliessen").
  final bool active;

  final String description;

  /// Arbeit: Stunden (0.25er-Raster moeglich). Material/Frei: Menge.
  final double quantity;

  /// EUR netto pro Einheit/Stunde.
  final double unitPrice;

  /// Nur fuer Material relevant („Stk", „m", „kg", ...). Frei/Arbeit leer.
  final String unit;

  /// Nur fuer Arbeit gefuellt — reine Anzeige (Snapshot-Wert).
  final String employeeName;

  /// Nur fuer Arbeit gefuellt — reine Anzeige (Snapshot-Wert).
  final OrderTimeEmployeeQualification? qualification;

  /// Nur fuer Arbeit: Arbeitstag der ursprueglichen Zeiterfassung.
  final DateTime? workDate;

  /// Nur fuer Arbeit: ID der Ursprungs-[OrderTimeEntry].
  ///
  /// Rein dokumentarisch — der Editor liest die Werte NICHT zurueck vom
  /// Auftrag, damit Aenderungen am `OrderTimeEntry` die Rechnung nicht
  /// rueckwirkend veraendern (Snapshot-Prinzip).
  final String? sourceTimeEntryId;

  /// Zeilensumme netto — deaktivierte Zeilen zaehlen mit 0.
  double get lineTotal => active ? quantity * unitPrice : 0;

  InvoiceLineItem copyWith({
    String? id,
    InvoiceLineKind? kind,
    bool? active,
    String? description,
    double? quantity,
    double? unitPrice,
    String? unit,
    String? employeeName,
    OrderTimeEmployeeQualification? qualification,
    DateTime? workDate,
    String? sourceTimeEntryId,
  }) {
    return InvoiceLineItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      active: active ?? this.active,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      employeeName: employeeName ?? this.employeeName,
      qualification: qualification ?? this.qualification,
      workDate: workDate ?? this.workDate,
      sourceTimeEntryId: sourceTimeEntryId ?? this.sourceTimeEntryId,
    );
  }
}

/// Default-Text für die zweite (editierbare) Zeile des Einleitungstexts.
/// Wird bei neu erzeugten Rechnungen als Startwert in [Invoice.introText]
/// übernommen und kann in der Detailansicht angepasst werden.
const String kDefaultInvoiceIntroBody =
    'nachfolgend berechnen wir Ihnen wie vorab besprochen:';

/// Rechnungsrelevante Kundendaten — eingefroren zum Erstellungszeitpunkt.
///
/// Spaetere Aenderungen am [CustomerDraft] wirken NICHT auf bereits erstellte
/// Rechnungen (wichtig fuer Pruefbarkeit + XRechnung/ZUGFeRD-Export).
class InvoiceCustomerSnapshot {
  const InvoiceCustomerSnapshot({
    required this.displayTitle,
    required this.customerNumber,
    required this.billingStreet,
    required this.billingHouseNumber,
    required this.billingZip,
    required this.billingCity,
    required this.billingEmail,
    required this.vatId,
    required this.taxNumber,
    required this.paymentTerms,
    this.salutation,
    this.lastName = '',
  });

  final String displayTitle;
  final String customerNumber;
  final String billingStreet;
  final String billingHouseNumber;
  final String billingZip;
  final String billingCity;
  final String billingEmail;
  final String vatId;
  final String taxNumber;
  final String paymentTerms;

  /// Anrede für die automatische Einleitungszeile der Rechnung.
  /// `null` = keine Anrede hinterlegt → „Sehr geehrte Damen und Herren,".
  final Salutation? salutation;

  /// Nachname für die Anrede-Zeile. Bei Firmenkunden i. d. R. leer.
  final String lastName;

  /// Automatisch erzeugte erste Zeile des Rechnungs-Einleitungstexts.
  /// Beispiele: „Sehr geehrter Herr Brühl,", „Sehr geehrte Frau Meier,",
  /// oder als neutraler Fallback „Sehr geehrte Damen und Herren,".
  String get salutationLine {
    final name = lastName.trim();
    switch (salutation) {
      case Salutation.herr:
        return name.isEmpty
            ? 'Sehr geehrter Herr,'
            : 'Sehr geehrter Herr $name,';
      case Salutation.frau:
        return name.isEmpty
            ? 'Sehr geehrte Frau,'
            : 'Sehr geehrte Frau $name,';
      case null:
        return 'Sehr geehrte Damen und Herren,';
    }
  }

  factory InvoiceCustomerSnapshot.fromCustomer(CustomerDraft c) {
    // Rechnungsadresse mit Fallback auf Lieferadresse, falls leer.
    final bs = c.billingStreet.trim().isEmpty ? c.street : c.billingStreet;
    final bhn = c.billingHouseNumber.trim().isEmpty
        ? c.houseNumber
        : c.billingHouseNumber;
    final bz = c.billingZip.trim().isEmpty ? c.zip : c.billingZip;
    final bc = c.billingCity.trim().isEmpty ? c.city : c.billingCity;
    final be = c.billingEmail.trim().isEmpty ? c.email : c.billingEmail;
    // Nachname nur bei Privatkunden übernehmen — bei Firmen wäre er für
    // die Anrede-Zeile irreführend (wir fallen dort auf „Damen und Herren").
    final lastName = c.kind == CustomerKind.privat ? c.lastName.trim() : '';
    return InvoiceCustomerSnapshot(
      displayTitle: c.displayTitle,
      customerNumber: c.customerNumber,
      billingStreet: bs,
      billingHouseNumber: bhn,
      billingZip: bz,
      billingCity: bc,
      billingEmail: be,
      vatId: c.vatId,
      taxNumber: c.taxNumber,
      paymentTerms: c.paymentTerms,
      salutation: c.kind == CustomerKind.privat ? c.salutation : null,
      lastName: lastName,
    );
  }
}

/// Eine Rechnung — Snapshot aus einem Auftrag, unabhaengig vom Original editierbar.
class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.createdAt,
    required this.status,
    required this.orderCreatedAt,
    required this.orderNumber,
    required this.orderTitle,
    required this.customer,
    required this.lines,
    this.introText = '',
    this.finalizedAt,
    // TODO Versionen/Gutschriften: parentInvoiceId + InvoiceKind (rechnung/storno)
    // werden hier spaeter ergaenzt.
  });

  /// Lokale ID (bis Supabase-Anbindung).
  final String id;

  /// Sichtbare Rechnungsnummer (z. B. `R-00001`).
  final String invoiceNumber;

  final DateTime createdAt;

  /// Wird beim Finalisieren gesetzt. Im Entwurf `null`.
  final DateTime? finalizedAt;

  final InvoiceStatus status;

  /// Verknuepfung zum zugehoerigen [OrderDraft] (ueber `createdAt` als ID).
  final DateTime orderCreatedAt;

  /// Kopie zum Erstellungszeitpunkt — fuer Anzeige auch dann, wenn der Auftrag
  /// spaeter umbenannt wurde.
  final String orderNumber;
  final String orderTitle;

  final InvoiceCustomerSnapshot customer;

  /// Freitext oberhalb der Positionen („Sehr geehrte Damen und Herren,
  /// für die durchgeführten Arbeiten stellen wir Ihnen in Rechnung …“).
  /// Wird im Rechnungs-Editor frei befüllt und auf der Detailseite direkt
  /// unter der Anschrift angezeigt. Leer = keine Einleitung.
  final String introText;

  final List<InvoiceLineItem> lines;

  /// Gesamtsumme netto — nur aktive Zeilen.
  double get netTotal => lines.fold<double>(0, (s, l) => s + l.lineTotal);

  /// Teilsumme fuer eine bestimmte Positionsart (z. B. nur Arbeit).
  double subtotalFor(InvoiceLineKind kind) => lines
      .where((l) => l.kind == kind)
      .fold<double>(0, (s, l) => s + l.lineTotal);

  List<InvoiceLineItem> linesOf(InvoiceLineKind kind) =>
      lines.where((l) => l.kind == kind).toList();

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? createdAt,
    DateTime? finalizedAt,
    InvoiceStatus? status,
    DateTime? orderCreatedAt,
    String? orderNumber,
    String? orderTitle,
    InvoiceCustomerSnapshot? customer,
    String? introText,
    List<InvoiceLineItem>? lines,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      status: status ?? this.status,
      orderCreatedAt: orderCreatedAt ?? this.orderCreatedAt,
      orderNumber: orderNumber ?? this.orderNumber,
      orderTitle: orderTitle ?? this.orderTitle,
      customer: customer ?? this.customer,
      introText: introText ?? this.introText,
      lines: lines ?? this.lines,
    );
  }

  /// Erzeugt einen Rechnungs-Entwurf aus einem Auftrag.
  ///
  /// - Pro [OrderTimeEntry] wird eine aktive Arbeitsposition erzeugt.
  /// - Stunden = Netto-Arbeitsdauer (Ende - Start - Pause) als Dezimal.
  /// - Stundensatz nach Qualifikation aus [CalculationSettings].
  /// - Material-/Freie Positionen bleiben leer — werden im Editor ergaenzt.
  factory Invoice.fromOrder({
    required OrderDraft order,
    required CalculationSettings calc,
    required String invoiceNumber,
    required DateTime createdAt,
  }) {
    final workLines = <InvoiceLineItem>[];
    for (final e in order.timeEntries) {
      final hours = e.netDuration.inMinutes / 60.0;
      final rate = switch (e.qualification) {
        OrderTimeEmployeeQualification.meister => calc.meisterHourlyRate,
        OrderTimeEmployeeQualification.geselle => calc.geselleHourlyRate,
      };
      final empName = e.employeeName.trim();
      final activity = e.activity.trim();
      final desc = _composeWorkLineDescription(
        activity: activity,
        rawDescription: e.description.trim(),
      );
      workLines.add(
        InvoiceLineItem(
          id: 'work_${e.id}',
          kind: InvoiceLineKind.arbeit,
          active: true,
          description: desc,
          quantity: hours,
          unitPrice: rate,
          employeeName: empName,
          qualification: e.qualification,
          workDate: e.workDate,
          sourceTimeEntryId: e.id,
        ),
      );
    }

    // Stabil nach Datum/Name sortieren, damit der Entwurf immer gleich aussieht.
    workLines.sort((a, b) {
      final da = a.workDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.workDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final c = da.compareTo(db);
      if (c != 0) return c;
      return a.employeeName.toLowerCase().compareTo(
        b.employeeName.toLowerCase(),
      );
    });

    return Invoice(
      id: 'inv_${createdAt.microsecondsSinceEpoch}',
      invoiceNumber: invoiceNumber,
      createdAt: createdAt,
      status: InvoiceStatus.entwurf,
      orderCreatedAt: order.createdAt,
      orderNumber: order.orderNumber,
      orderTitle: order.title,
      customer: InvoiceCustomerSnapshot.fromCustomer(order.customer),
      introText: kDefaultInvoiceIntroBody,
      lines: workLines,
    );
  }
}

String _composeWorkLineDescription({
  required String activity,
  required String rawDescription,
}) {
  if (activity.isEmpty && rawDescription.isEmpty) return 'Arbeitsleistung';
  if (activity.isEmpty) return rawDescription;
  if (rawDescription.isEmpty) return activity;
  return '$activity — $rawDescription';
}
