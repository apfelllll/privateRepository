import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/hours/new_time_entry_dialog.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/mobile/orders/mobile_customer_detail_page.dart';
import 'package:doordesk/mobile/providers/mobile_orders_providers.dart';
import 'package:doordesk/mobile/widgets/mobile_sub_page.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/models/order_time_entry.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Auftragsdetail-Seite fuer Mobile (Android): Kunde, Auftragsdaten, Notizen, Stundenliste.
///
/// Identifikation ueber [OrderDraft.createdAt] — der Provider-Eintrag wird live gewatcht,
/// damit Aenderungen (Edit-Dialog, Zeiterfassung) sofort reflektiert werden.
class MobileOrderDetailPage extends ConsumerWidget {
  const MobileOrderDetailPage({super.key, required this.orderCreatedAt});

  final DateTime orderCreatedAt;

  OrderDraft? _currentOrder(List<OrderDraft> all) {
    for (final o in all) {
      if (o.createdAt == orderCreatedAt) return o;
    }
    return null;
  }

  Future<void> _openFullEdit(
    BuildContext context,
    WidgetRef ref,
    OrderDraft current, {
    bool focusNotes = false,
  }) async {
    final customers = ref.read(mobileCustomersProvider);
    final updated = await showNewOrderDialog(
      context,
      customers: customers,
      orderNumber: current.orderNumber,
      initialOrder: current,
      initialFocusNotes: focusNotes,
    );
    if (updated == null) return;
    _replaceOrder(ref, updated);
  }

  void _replaceOrder(WidgetRef ref, OrderDraft updated) {
    final list = ref.read(mobileOrdersProvider);
    ref.read(mobileOrdersProvider.notifier).state = [
      for (final o in list)
        if (o.createdAt == updated.createdAt) updated else o,
    ];
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    OrderDraft current,
  ) async {
    final selected = await showModalBottomSheet<OrderDraftStatus>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Status ändern',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              for (final status in OrderDraftStatus.values)
                ListTile(
                  onTap: () => Navigator.of(ctx).pop(status),
                  leading: Icon(
                    status == current.status
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: status == current.status
                        ? Theme.of(ctx).colorScheme.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(status.displayLabel),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == current.status) return;
    _replaceOrder(ref, current.copyWith(status: selected));
  }

  Future<void> _openTimeEntryEditor(
    BuildContext context,
    WidgetRef ref,
    OrderDraft current, {
    OrderTimeEntry? initial,
  }) async {
    final result = await showNewTimeEntryDialog(
      context,
      forOrder: current,
      initialEntry: initial,
    );
    if (result == null) return;
    final list = List<OrderTimeEntry>.from(current.timeEntries);
    final i = list.indexWhere((e) => e.id == result.id);
    if (i >= 0) {
      list[i] = result;
    } else {
      list.add(result);
    }
    list.sort((a, b) {
      final c = a.workDate.compareTo(b.workDate);
      if (c != 0) return c;
      return a.startMinutes.compareTo(b.startMinutes);
    });
    _replaceOrder(ref, current.copyWith(timeEntries: list));
  }

  Future<void> _confirmDeleteTimeEntry(
    BuildContext context,
    WidgetRef ref,
    OrderDraft current,
    OrderTimeEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text(
          'Dieser Zeiterfassungseintrag wird aus der Stundenliste entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    _replaceOrder(
      ref,
      current.copyWith(
        timeEntries: current.timeEntries
            .where((x) => x.id != entry.id)
            .toList(),
      ),
    );
  }

  void _openCustomerDetail(BuildContext context, CustomerDraft customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MobileCustomerDetailPage(customerCreatedAt: customer.createdAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(doorDeskSessionProvider).value;
    final canManage =
        user != null && PermissionService.canCreateAndManageOrders(user.role);

    final orders = ref.watch(mobileOrdersProvider);
    final order = _currentOrder(orders);

    if (order == null) {
      return const MobileSubPage(
        title: 'Auftrag',
        child: MobileSubPagePlaceholder(
          icon: Icons.folder_off_outlined,
          message: 'Dieser Auftrag ist nicht mehr verfügbar.',
        ),
      );
    }

    final title = order.title.trim().isEmpty
        ? 'Ohne Titel'
        : order.title.trim();

    return MobileSubPage(
      title: title,
      actions: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Auftrag bearbeiten',
              onPressed: () => _openFullEdit(context, ref, order),
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.textPrimary,
            ),
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CustomerRow(
            customer: order.customer,
            onTap: () => _openCustomerDetail(context, order.customer),
          ),
          const SizedBox(height: 16),
          _OrderDataCard(
            order: order,
            onTapStatus: canManage
                ? () => _changeStatus(context, ref, order)
                : null,
            onTapTitle: canManage
                ? () => _openFullEdit(context, ref, order)
                : null,
          ),
          const SizedBox(height: 20),
          _NotesSection(
            order: order,
            onAddNotes: canManage
                ? () => _openFullEdit(context, ref, order, focusNotes: true)
                : null,
          ),
          const SizedBox(height: 20),
          _TimesheetSection(
            entries: order.timeEntries,
            canEdit: canManage,
            onAdd: canManage
                ? () => _openTimeEntryEditor(context, ref, order)
                : null,
            onEdit: canManage
                ? (e) => _openTimeEntryEditor(context, ref, order, initial: e)
                : null,
            onDelete: canManage
                ? (e) => _confirmDeleteTimeEntry(context, ref, order, e)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Tappbare Kundenzeile — fuehrt zur Kundendetailseite.
class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer, required this.onTap});

  final CustomerDraft customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (customer.kind) {
      CustomerKind.privat => Icons.person_rounded,
      CustomerKind.firma => Icons.apartment_rounded,
    };
    final streetLine =
        '${customer.street.trim()} ${customer.houseNumber.trim()}'.trim();
    final zipCityLine = customer.deliveryCityLine;
    final hasAddress = streetLine.isNotEmpty || zipCityLine.isNotEmpty;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        customer.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (hasAddress) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            streetLine,
                            zipCityLine,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Auftragsdaten-Kachel: Nummer, Titel, Typ, Status, Erfasst am.
class _OrderDataCard extends StatelessWidget {
  const _OrderDataCard({
    required this.order,
    required this.onTapStatus,
    required this.onTapTitle,
  });

  final OrderDraft order;

  /// Wenn gesetzt: Status-Pill oeffnet ein Bottom Sheet zum schnellen Aendern.
  final VoidCallback? onTapStatus;

  /// Wenn gesetzt: Tap auf den Titel oeffnet den vollen Edit-Dialog
  /// (praktisch, wenn der Titel leer ist → „Ohne Titel").
  final VoidCallback? onTapTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMMd('de_DE').add_Hm().format(order.createdAt);
    final hasTitle = order.title.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Auftrag',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _InfoLine(
            theme: theme,
            label: 'Auftragsnummer',
            valueChild: Text(
              order.orderNumber,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _InfoLine(
            theme: theme,
            label: 'Titel',
            valueChild: _TitleValue(
              hasTitle: hasTitle,
              title: order.title.trim(),
              onTap: onTapTitle,
              theme: theme,
            ),
          ),
          _InfoLine(
            theme: theme,
            label: 'Typ',
            valueChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  order.orderType.icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    order.orderType.displayLabel,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          _InfoLine(
            theme: theme,
            label: 'Status',
            valueChild: _StatusPill(status: order.status, onTap: onTapStatus),
          ),
          _InfoLine(
            theme: theme,
            label: 'Erfasst am',
            valueChild: Text(dateStr, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _TitleValue extends StatelessWidget {
  const _TitleValue({
    required this.hasTitle,
    required this.title,
    required this.onTap,
    required this.theme,
  });

  final bool hasTitle;
  final String title;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (hasTitle) {
      return Text(title, style: theme.textTheme.bodyLarge);
    }
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: onTap == null
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.primary,
    );
    if (onTap == null) {
      return Text('—', style: style);
    }
    return GestureDetector(
      onTap: onTap,
      child: Text('hinzufügen', style: style),
    );
  }
}

/// Status-Pill — tappbar wenn [onTap] gesetzt ist (oeffnet Status-Auswahl).
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.onTap});

  final OrderDraftStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (status) {
      OrderDraftStatus.entwurf => (
        const Color(0xFFFFF4E5),
        const Color(0xFFB25C00),
      ),
      OrderDraftStatus.inBearbeitung => (
        AppColors.accentSoft,
        AppColors.accent,
      ),
      OrderDraftStatus.abgeschlossen => (
        const Color(0xFFE7F7EC),
        const Color(0xFF2E7D4F),
      ),
    };

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.displayLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 16, color: fg),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: pill,
      ),
    );
  }
}

/// Label/Wert-Zeile mit oberem Label und Wert darunter (mobile-lesbar).
class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.theme,
    required this.label,
    required this.valueChild,
  });

  final ThemeData theme;
  final String label;
  final Widget valueChild;

  @override
  Widget build(BuildContext context) {
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      fontSize: 12.5,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          Align(alignment: Alignment.centerLeft, child: valueChild),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.order, required this.onAddNotes});

  final OrderDraft order;
  final VoidCallback? onAddNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNotes = order.notes.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notizen',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (hasNotes && onAddNotes != null)
                IconButton(
                  tooltip: 'Notizen bearbeiten',
                  onPressed: onAddNotes,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasNotes)
            Text(order.notes.trim(), style: theme.textTheme.bodyLarge)
          else if (onAddNotes != null)
            GestureDetector(
              onTap: onAddNotes,
              child: Text(
                'hinzufügen',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else
            Text('—', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Stundenliste mobil: Header + Summen + kompakte Zeilen.
class _TimesheetSection extends StatelessWidget {
  const _TimesheetSection({
    required this.entries,
    required this.canEdit,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OrderTimeEntry> entries;
  final bool canEdit;
  final VoidCallback? onAdd;
  final void Function(OrderTimeEntry)? onEdit;
  final void Function(OrderTimeEntry)? onDelete;

  List<OrderTimeEntry> get _sorted {
    final list = List<OrderTimeEntry>.from(entries);
    list.sort((a, b) {
      final c = b.workDate.compareTo(a.workDate);
      if (c != 0) return c;
      return b.startMinutes.compareTo(a.startMinutes);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = _sorted;
    final gesellenMinutes = entries
        .where((e) => e.qualification == OrderTimeEmployeeQualification.geselle)
        .fold<int>(0, (sum, e) => sum + e.netDuration.inMinutes);
    final meisterMinutes = entries
        .where((e) => e.qualification == OrderTimeEmployeeQualification.meister)
        .fold<int>(0, (sum, e) => sum + e.netDuration.inMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 22,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Stundenliste',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${entries.length} ${entries.length == 1 ? 'Eintrag' : 'Einträge'}',
              style: theme.textTheme.bodyMedium,
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 8),
              Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onAdd,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              canEdit
                  ? 'Noch keine Zeiterfassung. Über „+" einen Eintrag hinzufügen.'
                  : 'Keine Einträge.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          // Material (lokal) statt Ink: so bleibt der Hintergrund beim
          // Scrollen/Overscroll mit den Zeilen verbunden, und die inneren
          // InkWells ripplen auf dieser lokalen Material — nicht auf der
          // Scaffold-Material, die ausserhalb des Scroll-Viewports liegt.
          Material(
            type: MaterialType.canvas,
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: 14,
                      endIndent: 14,
                    ),
                  _TimeEntryRow(
                    entry: sorted[i],
                    onEdit: onEdit == null ? null : () => onEdit!(sorted[i]),
                    onDelete: onDelete == null
                        ? null
                        : () => onDelete!(sorted[i]),
                  ),
                ],
              ],
            ),
          ),
        if (sorted.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TotalsBlock(
            gesellenMinutes: gesellenMinutes,
            meisterMinutes: meisterMinutes,
          ),
        ],
      ],
    );
  }
}

class _TimeEntryRow extends StatelessWidget {
  const _TimeEntryRow({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final OrderTimeEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMd('de_DE').format(entry.workDate);
    final duration = _formatDuration(entry.netDuration);
    final employee = entry.employeeName.trim().isEmpty
        ? '—'
        : '${entry.employeeName.trim()} ${entry.qualification.suffixLabel}';
    final description = entry.description.trim();

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.activity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$duration h',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr  ·  $employee',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              _RowMenu(onEdit: onEdit, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onEdit, required this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Mehr',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Bearbeiten'),
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFB42318),
              ),
              title: Text(
                'Löschen',
                style: TextStyle(color: Color(0xFFB42318)),
              ),
            ),
          ),
      ],
    );
  }
}

class _TotalsBlock extends StatelessWidget {
  const _TotalsBlock({
    required this.gesellenMinutes,
    required this.meisterMinutes,
  });

  final int gesellenMinutes;
  final int meisterMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gesellenstunden',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${_formatDuration(Duration(minutes: gesellenMinutes))} h',
                style: text,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Meisterstunden',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                '${_formatDuration(Duration(minutes: meisterMinutes))} h',
                style: text,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  if (d <= Duration.zero) return '00:00';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
