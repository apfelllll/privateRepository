import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/orders/new_customer_dialog.dart';
import 'package:doordesk/mobile/orders/mobile_customer_card.dart';
import 'package:doordesk/mobile/providers/mobile_orders_providers.dart';
import 'package:doordesk/mobile/widgets/mobile_appbar_plus_button.dart';
import 'package:doordesk/mobile/widgets/mobile_sub_page.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MobileCustomersFilter {
  all('Alle Kunden', Icons.groups_outlined),
  active('Aktive Kunden', Icons.person_search_outlined);

  const MobileCustomersFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  String get emptyMessage {
    switch (this) {
      case MobileCustomersFilter.all:
        return 'Noch keine Kunden erfasst.\nTippe oben auf „+", um einen neuen Kunden anzulegen.';
      case MobileCustomersFilter.active:
        return 'Keine aktiven Kunden.\nEin Kunde ist aktiv, sobald er in einem laufenden Auftrag steht.';
    }
  }
}

/// Gefilterte Kundenliste mit optionalem „Neuer Kunde"-Button.
///
/// Permission + Dialog-Flow sind identisch zur Windows-Version.
class MobileCustomersListPage extends ConsumerWidget {
  const MobileCustomersListPage({super.key, required this.filter});

  final MobileCustomersFilter filter;

  Future<void> _openNewCustomer(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final draft = await showNewCustomerDialog(context);
    if (draft == null) return;
    final current = ref.read(mobileCustomersProvider);
    ref.read(mobileCustomersProvider.notifier).state = [...current, draft];
  }

  List<CustomerDraft> _visibleCustomers(
    List<CustomerDraft> all,
    List<OrderDraft> orders,
  ) {
    final filtered = all.where((c) {
      switch (filter) {
        case MobileCustomersFilter.all:
          return true;
        case MobileCustomersFilter.active:
          return orders.any((o) =>
              o.customer.createdAt == c.createdAt &&
              o.status == OrderDraftStatus.inBearbeitung);
      }
    }).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(doorDeskSessionProvider).value;
    final canManage = user != null &&
        PermissionService.canCreateAndManageOrders(user.role);
    final customers = _visibleCustomers(
      ref.watch(mobileCustomersProvider),
      ref.watch(mobileOrdersProvider),
    );

    return MobileSubPage(
      title: filter.label,
      actions: [
        if (canManage)
          MobileAppBarPlusButton(
            tooltip: 'Neuer Kunde',
            onPressed: () => _openNewCustomer(context, ref),
          ),
      ],
      child: customers.isEmpty
          ? MobileSubPagePlaceholder(
              icon: filter.icon,
              message: filter.emptyMessage,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return MobileCustomerCard(
                  customer: customer,
                  onTap: () => _showComingSoon(context),
                );
              },
            ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          content: Text('Kunden-Detail kommt bald.'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}
