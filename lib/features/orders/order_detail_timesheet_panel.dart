import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/features/hours/new_time_entry_dialog.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/models/order_time_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _formatNetDuration(Duration d) {
  if (d <= Duration.zero) return '—';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime d) =>
    DateFormat.yMMMd('de_DE').format(d);

String _formatEmployeeLine(OrderTimeEntry e) {
  final n = e.employeeName.trim();
  if (n.isEmpty) return '—';
  return '$n ${e.qualification.suffixLabel}';
}

/// Breite der Tabelle: alle Spalten mit Abstand; bei schmaler Karte horizontal scrollen.
const double _kTimesheetTableMinWidth = 1040;

/// Digitale Stundenliste zum Auftrag — gleiche Felder wie „Neue Arbeitszeiterfassung“.
class OrderDetailTimesheetPanel extends StatelessWidget {
  const OrderDetailTimesheetPanel({
    super.key,
    required this.order,
    required this.onOrderUpdated,
    this.canEdit = true,
    /// Neben Kunde + Auftragsdaten: volle Zeilenhöhe (von [Table] mit [fill]-Zelle).
    this.fillAvailableHeight = false,
  });

  final OrderDraft order;
  final ValueChanged<OrderDraft> onOrderUpdated;
  final bool canEdit;

  /// Wenn true, [Expanded] für den Tabellenbereich — nur mit begrenzter Höhe (z. B. Tabellenzeile).
  final bool fillAvailableHeight;

  Future<void> _openEditor(BuildContext context, {OrderTimeEntry? initial}) async {
    final result = await showNewTimeEntryDialog(
      context,
      forOrder: order,
      initialEntry: initial,
    );
    if (!context.mounted || result == null) return;
    final list = List<OrderTimeEntry>.from(order.timeEntries);
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
    onOrderUpdated(order.copyWith(timeEntries: list));
  }

  Future<void> _confirmDelete(BuildContext context, OrderTimeEntry e) async {
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
    if (!context.mounted || ok != true) return;
    onOrderUpdated(
      order.copyWith(
        timeEntries: order.timeEntries.where((x) => x.id != e.id).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = List<OrderTimeEntry>.from(order.timeEntries)
      ..sort((a, b) {
        final c = a.workDate.compareTo(b.workDate);
        if (c != 0) return c;
        return a.startMinutes.compareTo(b.startMinutes);
      });

    return DoorDeskFormCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          mainAxisSize:
              fillAvailableHeight ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stundenliste',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'Eintrag' : 'Einträge'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Neue Zeiterfassung'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (fillAvailableHeight)
              Expanded(
                child: _TimesheetTableBlock(
                  entries: entries,
                  canEdit: canEdit,
                  onEdit: (e) => _openEditor(context, initial: e),
                  onDelete: (e) => _confirmDelete(context, e),
                  useFlexibleTableHeight: true,
                ),
              )
            else
              _TimesheetTableBlock(
                entries: entries,
                canEdit: canEdit,
                onEdit: (e) => _openEditor(context, initial: e),
                onDelete: (e) => _confirmDelete(context, e),
                useFlexibleTableHeight: false,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimesheetTableBlock extends StatefulWidget {
  const _TimesheetTableBlock({
    required this.entries,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    required this.useFlexibleTableHeight,
  });

  final List<OrderTimeEntry> entries;
  final bool canEdit;
  final void Function(OrderTimeEntry) onEdit;
  final void Function(OrderTimeEntry) onDelete;
  final bool useFlexibleTableHeight;

  @override
  State<_TimesheetTableBlock> createState() => _TimesheetTableBlockState();
}

class _TimesheetTableBlockState extends State<_TimesheetTableBlock> {
  late final ScrollController _horizontalScroll;

  @override
  void initState() {
    super.initState();
    _horizontalScroll = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = widget.entries;
    final canEdit = widget.canEdit;
    final gesellenMinutes = entries
        .where((e) => e.qualification == OrderTimeEmployeeQualification.geselle)
        .fold<int>(0, (sum, e) => sum + e.netDuration.inMinutes);
    final meisterMinutes = entries
        .where((e) => e.qualification == OrderTimeEmployeeQualification.meister)
        .fold<int>(0, (sum, e) => sum + e.netDuration.inMinutes);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            canEdit
                ? 'Noch keine Zeiterfassung. „Neue Zeiterfassung“ hinzufügen.'
                : 'Keine Einträge.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    Widget dataTable() {
      return DataTable2(
        headingRowHeight: 44,
        dataRowHeight: 52,
        columnSpacing: 10,
        horizontalMargin: 8,
        minWidth: _kTimesheetTableMinWidth,
        isVerticalScrollBarVisible: entries.length > 8,
        headingRowColor: WidgetStatePropertyAll(
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        columns: [
          const DataColumn2(
            label: Text('Mitarbeiter'),
            size: ColumnSize.L,
          ),
          DataColumn2(
            label: const Text('Tätigkeit'),
            size: ColumnSize.M,
          ),
          const DataColumn2(
            label: Text('Beschreibung'),
            size: ColumnSize.L,
          ),
          const DataColumn2(
            label: Text('Dauer'),
            fixedWidth: 96,
          ),
          DataColumn2(
            label: const Text('Datum'),
            size: ColumnSize.S,
          ),
          if (canEdit)
            const DataColumn2(
              label: Text(''),
              fixedWidth: 100,
            ),
        ],
        rows: [
          for (final e in entries)
            DataRow2(
              cells: [
                DataCell(Text(_formatEmployeeLine(e))),
                DataCell(Text(e.activity)),
                DataCell(
                  Text(
                    e.description.isEmpty ? '—' : e.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(
                  Text('${_formatNetDuration(e.netDuration)} h'),
                ),
                DataCell(Text(_formatDate(e.workDate))),
                if (canEdit)
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Bearbeiten',
                          onPressed: () => widget.onEdit(e),
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Löschen',
                          onPressed: () => widget.onDelete(e),
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      );
    }

    Widget horizontalTable(double height) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = math.max(_kTimesheetTableMinWidth, constraints.maxWidth);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Scrollbar(
              controller: _horizontalScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalScroll,
                scrollDirection: Axis.horizontal,
                primary: false,
                child: SizedBox(
                  width: tableWidth,
                  height: height,
                  child: dataTable(),
                ),
              ),
            ),
          );
        },
      );
    }

    Widget totalsBlock() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 24,
            color: theme.colorScheme.outlineVariant,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Gesellenstunden: ${_formatNetDuration(Duration(minutes: gesellenMinutes))} h',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Meisterstunden: ${_formatNetDuration(Duration(minutes: meisterMinutes))} h',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    if (widget.useFlexibleTableHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = math.max(0.0, constraints.maxHeight);
                return horizontalTable(h);
              },
            ),
          ),
          const SizedBox(height: 8),
          totalsBlock(),
        ],
      );
    }

    final tableHeight = math.min(
      520.0,
      44.0 + 52.0 * entries.length,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        horizontalTable(tableHeight),
        const SizedBox(height: 8),
        totalsBlock(),
      ],
    );
  }
}
