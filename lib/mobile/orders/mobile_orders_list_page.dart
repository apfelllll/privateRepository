import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/mobile/orders/mobile_order_card.dart';
import 'package:doordesk/mobile/providers/mobile_orders_providers.dart';
import 'package:doordesk/mobile/widgets/mobile_appbar_plus_button.dart';
import 'package:doordesk/mobile/widgets/mobile_sub_page.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/number_generation_settings.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MobileOrdersFilter {
  all('Alle Aufträge', Icons.folder_open_rounded),
  inProgress('In Bearbeitung', Icons.hourglass_top_rounded),
  archive('Archiv', Icons.archive_outlined);

  const MobileOrdersFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(OrderDraft o) {
    switch (this) {
      case MobileOrdersFilter.all:
        return true;
      case MobileOrdersFilter.inProgress:
        return o.status == OrderDraftStatus.inBearbeitung;
      case MobileOrdersFilter.archive:
        return o.status == OrderDraftStatus.abgeschlossen;
    }
  }

  String get emptyMessage {
    switch (this) {
      case MobileOrdersFilter.all:
        return 'Noch keine Aufträge erfasst.\nTippe oben auf „+", um einen neuen Auftrag anzulegen.';
      case MobileOrdersFilter.inProgress:
        return 'Keine Aufträge in Bearbeitung.';
      case MobileOrdersFilter.archive:
        return 'Keine abgeschlossenen Aufträge im Archiv.';
    }
  }
}

/// Gefilterte Auftragsliste mit optionalem „Neuer Auftrag"-Button.
///
/// Permission + Dialog-Flow sind identisch zur Windows-Version.
class MobileOrdersListPage extends ConsumerWidget {
  const MobileOrdersListPage({super.key, required this.filter});

  final MobileOrdersFilter filter;

  /// Liefert die Auftragsnummer für den Dialog:
  /// - Automatisch: leerer String → Dialog holt über [OrderNumberSequence] die nächste.
  /// - Manuell: lokaler Zähler, gleiches Format wie Desktop (`A-00001`).
  Future<String> _nextOrderNumberArg(WidgetRef ref) async {
    final settings = await NumberGenerationSettings.load();
    if (settings.autoOrderNumber) return '';
    final seq = ref.read(mobileOrderNumberSeqProvider);
    final next = seq + 1;
    ref.read(mobileOrderNumberSeqProvider.notifier).state = next;
    return 'A-${next.toString().padLeft(5, '0')}';
  }

  Future<void> _openNewOrder(BuildContext context, WidgetRef ref) async {
    final customers = ref.read(mobileCustomersProvider);
    final orderNumberArg = await _nextOrderNumberArg(ref);
    if (!context.mounted) return;
    final draft = await showNewOrderDialog(
      context,
      customers: customers,
      orderNumber: orderNumberArg,
    );
    if (draft == null) return;
    final current = ref.read(mobileOrdersProvider);
    ref.read(mobileOrdersProvider.notifier).state = [...current, draft];
  }

  List<OrderDraft> _visibleOrders(List<OrderDraft> all) {
    final filtered = all.where(filter.matches).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(doorDeskSessionProvider).value;
    final canManage = user != null &&
        PermissionService.canCreateAndManageOrders(user.role);
    final orders = _visibleOrders(ref.watch(mobileOrdersProvider));

    return MobileSubPage(
      title: filter.label,
      actions: [
        if (canManage)
          MobileAppBarPlusButton(
            tooltip: 'Neuer Auftrag',
            onPressed: () => _openNewOrder(context, ref),
          ),
      ],
      child: orders.isEmpty
          ? MobileSubPagePlaceholder(
              icon: filter.icon,
              message: filter.emptyMessage,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                return MobileOrderCard(
                  order: order,
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
          content: Text('Auftrags-Detail kommt bald.'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}
