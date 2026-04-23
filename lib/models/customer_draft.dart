/// Lokal erfasster Kunde (z. B. bis Supabase-Anbindung).
enum CustomerKind { privat, firma }

/// Anrede für die automatische Erzeugung der Anrede-Zeile auf Rechnungen
/// und Angeboten („Sehr geehrter Herr …" / „Sehr geehrte Frau …"). `null`
/// an einer Kunden-Instanz bedeutet „keine Anrede hinterlegt" — es wird
/// dann auf „Sehr geehrte Damen und Herren," zurückgefallen.
enum Salutation { herr, frau }

extension SalutationDisplay on Salutation {
  String get displayLabel => switch (this) {
    Salutation.herr => 'Herr',
    Salutation.frau => 'Frau',
  };
}

class CustomerDraft {
  const CustomerDraft({
    required this.createdAt,
    required this.kind,
    required this.customerNumber,
    required this.firstName,
    required this.lastName,
    required this.companyName,
    required this.contactName,
    required this.email,
    required this.phone,
    required this.street,
    required this.houseNumber,
    required this.zip,
    required this.city,
    required this.billingStreet,
    required this.billingHouseNumber,
    required this.billingZip,
    required this.billingCity,
    required this.billingEmail,
    required this.vatId,
    required this.taxNumber,
    required this.paymentTerms,
    required this.notes,
    this.salutation,
  });

  final DateTime createdAt;
  final CustomerKind kind;

  /// Optionale Anrede (primär für Privatkunden relevant). `null` = keine
  /// Anrede hinterlegt — Rechnungen/Angebote fallen dann auf die neutrale
  /// Formel „Sehr geehrte Damen und Herren," zurück.
  final Salutation? salutation;

  final String customerNumber;
  final String firstName;
  final String lastName;
  final String companyName;
  final String contactName;
  final String email;
  final String phone;
  final String street;
  final String houseNumber;
  final String zip;
  final String city;
  final String billingStreet;
  final String billingHouseNumber;
  final String billingZip;
  final String billingCity;
  final String billingEmail;
  final String vatId;
  final String taxNumber;
  final String paymentTerms;
  final String notes;

  /// Kurztitel für Listen und Karten.
  String get displayTitle {
    switch (kind) {
      case CustomerKind.privat:
        final n = '${firstName.trim()} ${lastName.trim()}'.trim();
        if (n.isNotEmpty) return n;
        break;
      case CustomerKind.firma:
        if (companyName.trim().isNotEmpty) return companyName.trim();
        if (contactName.trim().isNotEmpty) return contactName.trim();
        break;
    }
    if (email.trim().isNotEmpty) return email.trim();
    return 'Neuer Kunde';
  }

  String get deliveryCityLine {
    final z = zip.trim();
    final c = city.trim();
    if (z.isEmpty && c.isEmpty) return '';
    if (z.isEmpty) return c;
    if (c.isEmpty) return z;
    return '$z $c';
  }

  /// Eine Zeile Lieferadresse (Straße, PLZ Ort), z. B. für Listen.
  String? get formattedDeliveryLine {
    final streetLine = '${street.trim()} ${houseNumber.trim()}'.trim();
    final zipCity = deliveryCityLine;
    if (streetLine.isEmpty && zipCity.isEmpty) return null;
    if (streetLine.isEmpty) return zipCity;
    if (zipCity.isEmpty) return streetLine;
    return '$streetLine , $zipCity';
  }

  /// Freitext für Karten-Suche (Lieferadresse), z. B. Google Maps; `null` wenn leer.
  /// „, Deutschland“ angehängt für zuverlässigere Geokodierung in Embed/WebView.
  String? get mapsDeliveryAddressQuery {
    final streetLine = '${street.trim()} ${houseNumber.trim()}'.trim();
    final zipCity = deliveryCityLine;
    if (streetLine.isEmpty && zipCity.isEmpty) return null;
    final core = switch ((streetLine.isEmpty, zipCity.isEmpty)) {
      (true, _) => zipCity,
      (_, true) => streetLine,
      _ => '$streetLine, $zipCity',
    };
    final lower = core.toLowerCase();
    if (lower.contains('deutschland') ||
        lower.contains('germany') ||
        lower.endsWith(', de')) {
      return core;
    }
    return '$core, Deutschland';
  }
}
