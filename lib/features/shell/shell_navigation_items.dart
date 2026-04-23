import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:flutter/material.dart';

const shellHomeSubItems = [
  DashboardRailItem(icon: Icons.home_rounded, label: 'Übersicht'),
];

const shellOrdersSubItems = [
  DashboardRailItem(icon: Icons.folder_open_rounded, label: 'Alle Aufträge'),
  DashboardRailItem(icon: Icons.hourglass_top_rounded, label: 'In Bearbeitung'),
  DashboardRailItem(icon: Icons.archive_outlined, label: 'Archiv'),
];

const shellCustomersSubItems = [
  DashboardRailItem(icon: Icons.groups_outlined, label: 'Alle Kunden'),
  DashboardRailItem(icon: Icons.person_search_outlined, label: 'Aktive Kunden'),
];

const shellCalendarSubItems = [
  DashboardRailItem(icon: Icons.calendar_month_rounded, label: 'Kalenderansicht'),
];

const shellHoursSubItems = [
  DashboardRailItem(icon: Icons.schedule_rounded, label: 'Zeiterfassung'),
];

const shellRailSections = [
  DashboardRailSection(heading: 'Startseite', items: shellHomeSubItems, isSubSection: true),
  DashboardRailSection(
    heading: 'Arbeitszeiten',
    items: shellHoursSubItems,
    isSubSection: true,
  ),
  DashboardRailSection(heading: 'Aufträge', items: shellOrdersSubItems, isSubSection: true),
  DashboardRailSection(heading: 'Kunden', items: shellCustomersSubItems, isSubSection: true),
  DashboardRailSection(heading: 'Kalender', items: shellCalendarSubItems, isSubSection: true),
];

class ShellRailTarget {
  const ShellRailTarget(this.tabIndex, this.subIndex);

  final int tabIndex;
  final int subIndex;
}

ShellRailTarget shellRailTargetFromIndex(int index) {
  if (index <= 0) return const ShellRailTarget(0, 0);
  if (index == 1) return const ShellRailTarget(4, 0);
  if (index <= 4) return ShellRailTarget(1, index - 2);
  if (index <= 6) return ShellRailTarget(2, index - 5);
  return const ShellRailTarget(3, 0);
}

int shellRailSelectedIndex({
  required int activeTabIndex,
  required int ordersSubIndex,
  required int customersSubIndex,
}) {
  switch (activeTabIndex) {
    case 0:
      return 0;
    case 4:
      return 1;
    case 1:
      return 2 + ordersSubIndex.clamp(0, shellOrdersSubItems.length - 1);
    case 2:
      return 5 + customersSubIndex.clamp(0, shellCustomersSubItems.length - 1);
    case 3:
      return 7;
    default:
      return 0;
  }
}
