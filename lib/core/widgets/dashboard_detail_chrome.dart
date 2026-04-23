import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:flutter/material.dart';

/// Begrüßung/Titelzeile über dem Bento-Bereich.
class DashboardDetailChrome extends StatelessWidget {
  const DashboardDetailChrome({
    super.key,
    required this.greeting,
    this.subtitle,
    this.titleTrailing,
    this.titleTrailingSpacing,
    this.titleRowOverride,
    this.reserveSpaceForGlobalSearch = true,
  });

  final String greeting;
  final String? subtitle;

  /// Rechts neben der Überschrift (z. B. Aktionen).
  final Widget? titleTrailing;

  /// Abstand Überschrift → [titleTrailing] in logischen Pixeln. Wenn gesetzt, folgt der
  /// Button direkt auf die Überschrift (nicht am rechten Rand); sinnvoll nur mit [titleTrailing].
  final double? titleTrailingSpacing;

  /// Ersetzt die komplette Titelzeile; [greeting], [titleTrailing] und [titleTrailingSpacing]
  /// werden dann ignoriert (z. B. Kunden-Detailkopf).
  final Widget? titleRowOverride;

  /// Reserviert vertikalen Platz für die Shell-Kopfzeile (Ausrichtung zur
  /// globalen Titelzeile). Bei `false` nur die natürliche Höhe der Überschrift.
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
        if (reserveSpaceForGlobalSearch)
          SizedBox(
            width: double.infinity,
            height: ShellSearchLayout.searchBarVisualHeight,
            child: titleRow(),
          )
        else
          SizedBox(width: double.infinity, child: titleRow()),
        if (subtitle != null) ...[
          SizedBox(height: ShellSearchLayout.gapBelowBar),
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
