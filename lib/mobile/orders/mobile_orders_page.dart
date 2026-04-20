import 'package:doordesk/mobile/orders/mobile_customers_list_page.dart';
import 'package:doordesk/mobile/orders/mobile_orders_list_page.dart';
import 'package:doordesk/mobile/widgets/mobile_menu_list.dart';
import 'package:doordesk/mobile/widgets/mobile_page_scaffold.dart';
import 'package:flutter/material.dart';

/// Einstiegsseite des Auftraege-Tabs — sektioniertes Menue im WhatsApp/iOS-Stil.
///
/// Tap auf einen Eintrag pusht die jeweilige Unterseite nach rechts rein,
/// dieses Menue faehrt dabei nach links raus (Standard-Slide).
class MobileOrdersPage extends StatelessWidget {
  const MobileOrdersPage({super.key});

  void _openOrders(BuildContext context, MobileOrdersFilter filter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MobileOrdersListPage(filter: filter),
      ),
    );
  }

  void _openCustomers(BuildContext context, MobileCustomersFilter filter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MobileCustomersListPage(filter: filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MobilePageScaffold(
      title: 'Auftraege und Kunden',
      child: MobileMenuList(
        sections: [
          MobileMenuSection(
            heading: 'Auftraege',
            items: [
              for (final f in MobileOrdersFilter.values)
                MobileMenuItem(
                  icon: f.icon,
                  label: f.label,
                  onTap: () => _openOrders(context, f),
                ),
            ],
          ),
          MobileMenuSection(
            heading: 'Kunden',
            items: [
              for (final f in MobileCustomersFilter.values)
                MobileMenuItem(
                  icon: f.icon,
                  label: f.label,
                  onTap: () => _openCustomers(context, f),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
