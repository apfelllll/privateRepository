import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:flutter/material.dart';

const _calendarRailItems = [
  DashboardRailItem(icon: Icons.calendar_month_rounded, label: 'Kalender'),
];

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return DashboardSplit(
      leftWidth: 272,
      detailTopPadding: ShellSearchLayout.detailColumnTopPadding(context),
      left: DashboardLeftRail(
        sections: const [DashboardRailSection(items: _calendarRailItems)],
        selectedIndex: 0,
        onSelect: (_) {},
        onLogout: onLogout,
      ),
      detail: const SizedBox.expand(),
    );
  }
}
