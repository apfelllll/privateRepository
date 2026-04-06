import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/features/home/boehmenkirch_week_weather.dart';
import 'package:flutter/material.dart';

const _kHomeRailItems = [
  DashboardRailItem(icon: Icons.home_rounded, label: 'Übersicht'),
];

/// Start — Übersicht mit Wetterkarte fester Größe (Böhmenkirch).
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return DashboardSplit(
      leftWidth: 272,
      detailTopPadding:
          ShellSearchLayout.detailContentTopBelowGlobalSearch(context),
      left: DashboardLeftRail(
        sections: const [DashboardRailSection(items: _kHomeRailItems)],
        selectedIndex: 0,
        onSelect: (_) {},
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
A