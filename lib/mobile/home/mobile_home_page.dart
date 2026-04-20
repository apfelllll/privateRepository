import 'package:doordesk/mobile/widgets/mobile_menu_list.dart';
import 'package:doordesk/mobile/widgets/mobile_page_scaffold.dart';
import 'package:doordesk/mobile/widgets/mobile_placeholder_sub_page.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MobileHomePage extends ConsumerWidget {
  const MobileHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(doorDeskSessionProvider).value;
    final firstName =
        user?.displayName.split(RegExp(r'\s+')).firstOrNull ?? 'Willkommen';

    return MobilePageScaffold(
      title: 'Hallo, $firstName',
      child: MobileMenuList(
        sections: [
          MobileMenuSection(
            heading: 'Mein Tag',
            items: [
              MobileMenuItem(
                icon: Icons.today_rounded,
                label: 'Heute',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Heute',
                  icon: Icons.today_rounded,
                  message:
                      'Deine Uebersicht fuer den heutigen Tag erscheint hier bald.',
                ),
              ),
              MobileMenuItem(
                icon: Icons.view_week_rounded,
                label: 'Diese Woche',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Diese Woche',
                  icon: Icons.view_week_rounded,
                  message: 'Deine Woche im Ueberblick — kommt bald.',
                ),
              ),
            ],
          ),
          MobileMenuSection(
            heading: 'Orte',
            items: [
              MobileMenuItem(
                icon: Icons.wb_sunny_outlined,
                label: 'Wetter Boehmenkirch',
                onTap: () => pushMobilePlaceholderPage(
                  context,
                  title: 'Wetter Boehmenkirch',
                  icon: Icons.wb_sunny_outlined,
                  message: 'Die Wochenvorhersage erscheint hier bald.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
