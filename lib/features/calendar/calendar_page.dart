import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/features/shell/shell_navigation_items.dart';
import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({
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
      detailTopPadding: ShellSearchLayout.detailColumnTopPadding(context),
      left: DashboardLeftRail(
        sections: shellRailSections,
        selectedIndex: selectedRailIndex,
        onSelect: onRailSelect,
        onLogout: onLogout,
      ),
      detail: const SizedBox.expand(),
    );
  }
}
