import 'package:doordesk/mobile/widgets/mobile_menu_list.dart';
import 'package:doordesk/mobile/widgets/mobile_page_scaffold.dart';
import 'package:doordesk/mobile/widgets/mobile_placeholder_sub_page.dart';
import 'package:flutter/material.dart';

class MobileCalendarPage extends StatelessWidget {
  const MobileCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MobilePageScaffold(
      title: 'Kalender',
      child: MobileMenuList(
        sections: [
          MobileMenuSection(
            heading: 'Ansicht',
            items: [
              MobileMenuItem(
                icon: Icons.today_rounded,
                label: 'Heute',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Heute',
                  icon: Icons.today_rounded,
                  message: 'Die Tagesansicht erscheint hier bald.',
                ),
              ),
              MobileMenuItem(
                icon: Icons.view_week_rounded,
                label: 'Woche',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Woche',
                  icon: Icons.view_week_rounded,
                  message: 'Die Wochenansicht erscheint hier bald.',
                ),
              ),
              MobileMenuItem(
                icon: Icons.calendar_view_month_rounded,
                label: 'Monat',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Monat',
                  icon: Icons.calendar_view_month_rounded,
                  message: 'Die Monatsansicht erscheint hier bald.',
                ),
              ),
            ],
          ),
          MobileMenuSection(
            heading: 'Meine Termine',
            items: [
              MobileMenuItem(
                icon: Icons.event_available_rounded,
                label: 'Offene Termine',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Offene Termine',
                  icon: Icons.event_available_rounded,
                ),
              ),
              MobileMenuItem(
                icon: Icons.event_busy_outlined,
                label: 'Vergangene Termine',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Vergangene Termine',
                  icon: Icons.event_busy_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
