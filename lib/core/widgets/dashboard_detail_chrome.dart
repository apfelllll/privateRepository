import 'dart:ui';

import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/theme/dashboard_theme.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:flutter/material.dart';

/// Such-Leiste + Begrüßung über dem Bento-Bereich.
class DashboardDetailChrome extends StatelessWidget {
  const DashboardDetailChrome({
    super.key,
    required this.greeting,
    this.subtitle,
    this.searchHint = 'Suchen…',
    this.showTopBar = true,
    this.titleTrailing,
    this.titleTrailingSpacing,
    this.titleRowOverride,
    this.reserveSpaceForGlobalSearch = true,
  });

  final String greeting;
  final String? subtitle;
  final String searchHint;

  /// Such-Pille und Benachrichtigungs-Icon — bei `false` nur Überschrift ( z. B. Aufträge ).
  final bool showTopBar;

  /// Rechts neben der Überschrift (z. B. Aktionen).
  final Widget? titleTrailing;

  /// Abstand Überschrift → [titleTrailing] in logischen Pixeln. Wenn gesetzt, folgt der
  /// Button direkt auf die Überschrift (nicht am rechten Rand); sinnvoll nur mit [titleTrailing].
  final double? titleTrailingSpacing;

  /// Ersetzt die komplette Titelzeile; [greeting], [titleTrailing] und [titleTrailingSpacing]
  /// werden dann ignoriert (z. B. Kunden-Detailkopf).
  final Widget? titleRowOverride;

  /// Bei `showTopBar: false`: Platzhalterhöhe wie die globale Suche (Ausrichtung). Bei `false`
  /// nur die natürliche Höhe der Überschrift (z. B. ohne Shell-Suche).
  final bool reserveSpaceForGlobalSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );

    Widget titleRow() {
      if (titleRowOverride != null) {
        return titleRowOverride!;
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (titleTrailing != null && titleTrailingSpacing != null) ...[
            Flexible(
              child: Text(
                greeting,
                style: headlineStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(width: titleTrailingSpacing!),
            titleTrailing!,
          ] else ...[
            Expanded(
              child: Text(
                greeting,
                style: headlineStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            ?titleTrailing,
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTopBar) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: DashboardTheme.glassFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: DashboardTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      searchHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: titleRow()),
        ] else ...[
          if (reserveSpaceForGlobalSearch)
            SizedBox(
              width: double.infinity,
              height: ShellSearchLayout.searchBarVisualHeight,
              child: titleRow(),
            )
          else
            SizedBox(width: double.infinity, child: titleRow()),
        ],
        if (subtitle != null) ...[
          SizedBox(height: showTopBar ? 6 : ShellSearchLayout.gapBelowBar),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
