import 'package:shared_preferences/shared_preferences.dart';

/// Einstellungen zur automatischen Vergabe von Kunden- und Auftragsnummern
/// (Einstellungen → Aufträge und Kunden → Nummern).
abstract final class NumberGenerationSettingsKeys {
  static const customerAuto = 'settings.number_gen.customer_auto';
  static const orderAuto = 'settings.number_gen.order_auto';

  /// Nächste laufende Kundennummer (Ganzzahl), Formatierung z. B. K-00001.
  static const customerNextSeq = 'settings.number_gen.customer_next_seq';

  /// Nächste laufende Auftragsnummer (Ganzzahl), Formatierung z. B. A-00001.
  static const orderNextSeq = 'settings.number_gen.order_next_seq';

  static const invoiceNextSeq = 'settings.number_gen.invoice_next_seq';

  /// Nächste laufende Angebotsnummer (Ganzzahl), Formatierung z. B. Q-00001.
  static const quoteNextSeq = 'settings.number_gen.quote_next_seq';
}

/// Liest und speichert die Nummern-Optionen lokal ([SharedPreferences]).
class NumberGenerationSettings {
  const NumberGenerationSettings({
    required this.autoCustomerNumber,
    required this.autoOrderNumber,
  });

  /// Kundennummer automatisch vergeben (Standard: an).
  final bool autoCustomerNumber;

  /// Auftragsnummer automatisch vergeben (Standard: an).
  final bool autoOrderNumber;

  static Future<NumberGenerationSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return NumberGenerationSettings(
      autoCustomerNumber: p.getBool(NumberGenerationSettingsKeys.customerAuto) ??
          true,
      autoOrderNumber:
          p.getBool(NumberGenerationSettingsKeys.orderAuto) ?? true,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(
      NumberGenerationSettingsKeys.customerAuto,
      autoCustomerNumber,
    );
    await p.setBool(
      NumberGenerationSettingsKeys.orderAuto,
      autoOrderNumber,
    );
  }

  NumberGenerationSettings copyWith({
    bool? autoCustomerNumber,
    bool? autoOrderNumber,
  }) {
    return NumberGenerationSettings(
      autoCustomerNumber: autoCustomerNumber ?? this.autoCustomerNumber,
      autoOrderNumber: autoOrderNumber ?? this.autoOrderNumber,
    );
  }
}

/// Fortlaufende Kundennummern (`K-00001` …), synchron mit [NumberGenerationSettings].
abstract final class CustomerNumberSequence {
  static String format(int sequence) =>
      'K-${sequence.toString().padLeft(5, '0')}';

  static Future<int> _peekSeq() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(NumberGenerationSettingsKeys.customerNextSeq) ?? 1;
  }

  /// Nächste Nummer nur anzeigen (Zähler unverändert).
  static Future<String> peekNextFormatted() async {
    final n = await _peekSeq();
    return format(n);
  }

  /// Nächste Nummer vergeben und Zähler erhöhen — beim Speichern eines neuen Kunden.
  static Future<String> consumeNextFormatted() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getInt(NumberGenerationSettingsKeys.customerNextSeq) ?? 1;
    await p.setInt(NumberGenerationSettingsKeys.customerNextSeq, n + 1);
    return format(n);
  }
}

/// Fortlaufende Auftragsnummern (`A-00001` …), synchron mit [NumberGenerationSettings].
abstract final class OrderNumberSequence {
  static String format(int sequence) =>
      'A-${sequence.toString().padLeft(5, '0')}';

  static Future<int> _peekSeq() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(NumberGenerationSettingsKeys.orderNextSeq) ?? 1;
  }

  static Future<String> peekNextFormatted() async {
    final n = await _peekSeq();
    return format(n);
  }

  static Future<String> consumeNextFormatted() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getInt(NumberGenerationSettingsKeys.orderNextSeq) ?? 1;
    await p.setInt(NumberGenerationSettingsKeys.orderNextSeq, n + 1);
    return format(n);
  }
}

/// Fortlaufende Rechnungsnummern (`R-00001` ...), immer automatisch vergeben.
///
/// Gleicher Mechanismus wie [OrderNumberSequence]/[CustomerNumberSequence]:
/// `peek` liest nur, `consume` erhoeht den Zaehler. Wird beim Anlegen eines
/// neuen Rechnungs-Entwurfs aufgerufen.
abstract final class InvoiceNumberSequence {
  static String format(int sequence) =>
      'R-${sequence.toString().padLeft(5, '0')}';

  static Future<int> _peekSeq() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(NumberGenerationSettingsKeys.invoiceNextSeq) ?? 1;
  }

  /// Naechste Nummer nur anzeigen (Zaehler unveraendert).
  static Future<String> peekNextFormatted() async {
    final n = await _peekSeq();
    return format(n);
  }

  /// Naechste Nummer vergeben und Zaehler erhoehen.
  static Future<String> consumeNextFormatted() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getInt(NumberGenerationSettingsKeys.invoiceNextSeq) ?? 1;
    await p.setInt(NumberGenerationSettingsKeys.invoiceNextSeq, n + 1);
    return format(n);
  }
}

/// Fortlaufende Angebotsnummern (`Q-00001` ...), immer automatisch vergeben.
///
/// Gleicher Mechanismus wie [InvoiceNumberSequence]: `peek` liest nur,
/// `consume` erhöht den Zähler. Wird beim Anlegen eines neuen
/// Angebots-Entwurfs aufgerufen.
abstract final class QuoteNumberSequence {
  static String format(int sequence) =>
      'Q-${sequence.toString().padLeft(5, '0')}';

  static Future<int> _peekSeq() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(NumberGenerationSettingsKeys.quoteNextSeq) ?? 1;
  }

  /// Nächste Nummer nur anzeigen (Zähler unverändert).
  static Future<String> peekNextFormatted() async {
    final n = await _peekSeq();
    return format(n);
  }

  /// Nächste Nummer vergeben und Zähler erhöhen.
  static Future<String> consumeNextFormatted() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getInt(NumberGenerationSettingsKeys.quoteNextSeq) ?? 1;
    await p.setInt(NumberGenerationSettingsKeys.quoteNextSeq, n + 1);
    return format(n);
  }
}
