/// Gemeinsame Breite für Karten-Spalte links (Karte + Stammdaten), linksbündig.
/// Schmaler als volle Spaltenbreite; passt sich auf schmalen Viewports an (`maxWidth`).
const double kCustomerDetailCardWidth = 400;

/// Maximalbreite der Auftragskarten in der rechten Spalte.
/// Basis + ca. 7 cm (96 dpi: 7 × 96 / 2,54 ≈ 265 logische Pixel).
const double kCustomerDetailOrdersCardMaxWidth = 520 + 265;

/// Synchron mit [CustomerDeliveryMapCard] — Abstand Oberkante Daten/Aufträge zur Zeile.
const double kCustomerDeliveryMapCardHeight = 248;

const double kCustomerDetailMapToDataGap = 20;

/// Oberkante Stammdaten-Kachel = Oberkante Auftrags-Kachel (rechte Spalte Abstand oben).
const double kCustomerDetailAlignedContentTopInset =
    kCustomerDeliveryMapCardHeight + kCustomerDetailMapToDataGap;
