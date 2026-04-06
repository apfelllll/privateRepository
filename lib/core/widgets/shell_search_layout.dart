import 'package:flutter/material.dart';

/// Maße der globalen Suchzeile in [MainShell] — für Ausrichtung nur der Detail-Spalte.
abstract final class ShellSearchLayout {
  static const double detailTopAlign = 20;
  static const double searchBarVisualHeight = 50;
  static const double gapBelowBar = 8;

  static double searchRowTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + detailTopAlign;

  /// Nur bis zur gleichen oberen Kante wie die globale Suche — Überschrift sitzt in der
  /// gleichen Zeile wie das Suchfeld ([searchBarVisualHeight]).
  static double detailColumnTopPadding(BuildContext context) =>
      searchRowTop(context);

  /// Detail-Inhalt beginnt **unter** der Suchzeile (+ kleiner Abstand).
  /// Sinnvoll z. B. für die Startseite, wenn oben nur die Suche sichtbar sein soll.
  static double detailContentTopBelowGlobalSearch(BuildContext context) =>
      searchRowTop(context) + searchBarVisualHeight + gapBelowBar;
}
