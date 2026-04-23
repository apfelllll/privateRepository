import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/features/home/boehmenkirch_week_weather.dart';
import 'package:doordesk/features/shell/shell_navigation_items.dart';
import 'package:flutter/material.dart';

/// Start — Übersicht mit Wetterkarte fester Größe (Böhmenkirch).
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onLogout,
    required this.selectedRailIndex,
    required this.onRailSelect,
  });

  final VoidCallback onLogout;
  final int selectedRailIndex;
  final ValueChanged<int> onRailSelect;

  @override
  Widget build(BuildContext context) {
    return DashboardSplit(
      leftWidth: 272,
      detailTopPadding:
          ShellSearchLayout.detailContentTopBelowGlobalSearch(context),
      left: DashboardLeftRail(
        sections: shellRailSections,
        selectedIndex: selectedRailIndex,
        onSelect: onRailSelect,
        onLogout: onLogout,
      ),
      detail: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 32, 32),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: BoehmenkirchWeekWeatherCard(),
            ),
          ],
        ),
      ),
    );
  }
}