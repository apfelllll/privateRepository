import 'package:flutter/material.dart';

/// Maße der globalen Suchzeile in [MainShell] — für Ausrichtung nur der Detail-Spalte.
abstract final class ShellSearchLayout {
  static const double detailTopAlign = 20;
  static const double searchBarVisualHeight = 50;
  static const double gapBelowBar = 8;

  /// Platz, den die Shell-Kopfleiste am rechten Rand für ihre Aktionen
  /// (Benachrichtigungs-Icon + Avatar-Button + rechtes Padding) beansprucht.
  /// Detail-Titelzeilen, die auf derselben Höhe wie die Shell-Leiste
  /// gerendert werden, müssen diesen Bereich am rechten Rand freihalten,
  /// damit ihre eigenen Action-Buttons nicht von den Shell-Icons überdeckt
  /// werden.
  ///
  /// Ableitung: 40 (Glocke) + 8 (Gap) + 40 (Avatar) + 16 (Shell-Padding)
  /// + 32 (Sicherheit/optischer Abstand) = 136.
  static const double trailingShellActionsReserve = 136;

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
