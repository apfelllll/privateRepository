/// Breakpoints für Desktop-Fenster — abgestimmt auf [DashboardSplit] und Detail-Layouts.
abstract final class DashboardLayout {
  /// Volle Rail-Breite wie im Entwurf (siehe [DashboardSplit]).
  static const double splitWideMinWidth = 960;

  /// Mittlere Stufe: etwas schmalere Rail.
  static const double splitMediumMinWidth = 720;

  /// Auftrags-/Kundenliste: Karten nur halbe Breite, wenn genug Platz.
  static const double listHalfWidthMinDetailWidth = 880;

  /// Kunden-Detail: zwei Spalten nebeneinander.
  static const double customerDetailTwoColumnMinWidth = 720;

  /// Stammdaten-Zeilen: Label und Wert nebeneinander (sonst untereinander).
  static const double labelValueRowMinWidth = 420;

  /// Gleiche Logik wie [DashboardSplit] — für z. B. die globale Suchleiste in [MainShell].
  static double railWidth(double contentWidth, {double leftWidth = 272}) {
    if (contentWidth >= splitWideMinWidth) return leftWidth;
    if (contentWidth >= splitMediumMinWidth) {
      return (leftWidth - 40).clamp(200.0, leftWidth);
    }
    return 200.0;
  }
}
