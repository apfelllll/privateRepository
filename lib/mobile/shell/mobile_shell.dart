import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/mobile/calendar/mobile_calendar_page.dart';
import 'package:doordesk/mobile/home/mobile_home_page.dart';
import 'package:doordesk/mobile/hours/mobile_hours_page.dart';
import 'package:doordesk/mobile/orders/mobile_orders_page.dart';
import 'package:doordesk/mobile/settings/mobile_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hauptgeruest fuer Android/iOS — 5 Tabs in voller Breite (WhatsApp-Stil).
class MobileShell extends ConsumerStatefulWidget {
  const MobileShell({super.key});

  @override
  ConsumerState<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<MobileShell> {
  int _index = 0;

  static const _pages = <Widget>[
    MobileHomePage(),
    MobileOrdersPage(),
    MobileCalendarPage(),
    MobileHoursPage(),
    MobileSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          // Nur Icons sichtbar — Labels bleiben als Semantik-Hinweis (Screenreader) erhalten.
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Start',
            ),
            NavigationDestination(
              icon: Icon(Icons.corporate_fare_outlined),
              selectedIcon: Icon(Icons.corporate_fare),
              label: 'Auftraege',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Kalender',
            ),
            NavigationDestination(
              icon: Icon(Icons.schedule_outlined),
              selectedIcon: Icon(Icons.schedule),
              label: 'Zeiten',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Einstellungen',
            ),
          ],
        ),
      ),
    );
  }
}
