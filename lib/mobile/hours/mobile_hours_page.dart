import 'package:doordesk/mobile/widgets/mobile_menu_list.dart';
import 'package:doordesk/mobile/widgets/mobile_page_scaffold.dart';
import 'package:doordesk/mobile/widgets/mobile_placeholder_sub_page.dart';
import 'package:flutter/material.dart';

class MobileHoursPage extends StatelessWidget {
  const MobileHoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MobilePageScaffold(
      title: 'Arbeitszeiten',
      child: MobileMenuList(
        sections: [
          MobileMenuSection(
            heading: 'Erfassung',
            items: [
              MobileMenuItem(
                icon: Icons.add_alarm_rounded,
                label: 'Neue Arbeitszeit',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Neue Arbeitszeit',
                  icon: Icons.add_alarm_rounded,
                  message: 'Eintragsmaske fuer neue Arbeitszeiten folgt bald.',
                ),
              ),
              MobileMenuItem(
                icon: Icons.timer_outlined,
                label: 'Laufende Zeit',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Laufende Zeit',
                  icon: Icons.timer_outlined,
                  message:
                      'Start/Stopp-Stoppuhr fuer mobile Zeiterfassung folgt.',
                ),
              ),
            ],
          ),
          MobileMenuSection(
            heading: 'Auswertung',
            items: [
              MobileMenuItem(
                icon: Icons.today_rounded,
                label: 'Heute',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Heute',
                  icon: Icons.today_rounded,
                  message: 'Heutige Arbeitszeit im Ueberblick.',
                ),
              ),
              MobileMenuItem(
                icon: Icons.view_week_rounded,
                label: 'Aktuelle Woche',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Aktuelle Woche',
                  icon: Icons.view_week_rounded,
                ),
              ),
              MobileMenuItem(
                icon: Icons.calendar_view_month_rounded,
                label: 'Aktueller Monat',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Aktueller Monat',
                  icon: Icons.calendar_view_month_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
