import 'dart:ui';

import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/theme/dashboard_theme.dart';
import 'package:flutter/material.dart';

class DashboardRailItem {
  const DashboardRailItem({
    required this.icon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final String label;
  final int? badge;
}

/// Eine Gruppe in der linken Rail: optionale Überschrift + Einträge.
class DashboardRailSection {
  const DashboardRailSection({
    this.heading,
    required this.items,
  });

  final String? heading;
  final List<DashboardRailItem> items;
}

/// Alle Navigations-Einträge der Sections in Reihenfolge (für Label / Index-Zugriff).
List<DashboardRailItem> flattenDashboardRailSections(
  List<DashboardRailSection> sections,
) =>
    [for (final s in sections) ...s.items];

/// Volle Höhe — sekundäre Navigation / Kontext je Haupt-Tab.
class DashboardLeftRail extends StatelessWidget {
  const DashboardLeftRail({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.footerHint,
    this.headerLeading,
  });

  final List<DashboardRailSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final String? footerHint;

  /// Optional: Aktion rechts in der Kopfzeile (gleiche Höhe wie „DoorDesk / Metisia“),
  /// am rechten Rand der Rail — ohne die Spalte zu verbreitern.
  final Widget? headerLeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DashboardTheme.railGlassFill,
            border: Border(
              right: BorderSide(color: DashboardTheme.railBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'DoorDesk',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Metisia',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (headerLeading != null) ...[
                      const Spacer(),
                      headerLeading!,
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: _buildSectionChildren(theme),
                ),
              ),
              if (footerHint != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    footerHint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const Divider(height: 1),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: onLogout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Abmelden',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSectionChildren(ThemeData theme) {
    final children = <Widget>[];
    var globalIndex = 0;
    for (var si = 0; si < sections.length; si++) {
      final section = sections[si];
      if (section.heading != null) {
        if (si > 0) {
          children.add(const SizedBox(height: 16));
        }
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                section.heading!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }
      for (final it in section.items) {
        final i = globalIndex++;
        final selected = i == selectedIndex;
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: selected
                  ? AppColors.accentSoft.withValues(alpha: 0.85)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSelect(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        it.icon,
                        size: 22,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          it.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: selected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (it.badge != null && it.badge! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${it.badge}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return children;
  }
}
