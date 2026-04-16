import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/widgets/glass_card.dart';
import 'package:doordesk/models/assigned_order.dart';
import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/models/time_entry.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 0,25 h bis 24 h
List<double> quarterHourValues() =>
    List.generate(96, (i) => (i + 1) * 0.25);

Color orderStripeColor(String orderId) {
  var h = 0;
  for (final c in orderId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return Colors.primaries[h.abs() % Colors.primaries.length].shade400;
}

String _fmtDate(DateTime d) => DateFormat.yMMMd('de_DE').format(d);

DateTime _clampDateToMonth(DateTime d, DateTime monthStart) {
  final first = DateTime(monthStart.year, monthStart.month, 1);
  final last = DateTime(monthStart.year, monthStart.month + 1, 0);
  if (d.isBefore(first)) return first;
  if (d.isAfter(last)) return last;
  return DateTime(d.year, d.month, d.day);
}

class TimesheetDataTable extends ConsumerStatefulWidget {
  const TimesheetDataTable({
    super.key,
    required this.user,
    required this.month,
    required this.entries,
    required this.orders,
  });

  final DoorDeskUser user;
  final DateTime month;
  final List<TimeEntry> entries;
  final List<AssignedOrder> orders;

  @override
  ConsumerState<TimesheetDataTable> createState() =>
      _TimesheetDataTableState();
}

class _TimesheetDataTableState extends ConsumerState<TimesheetDataTable> {
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, Timer> _debounce = {};
  final Map<String, FocusNode> _notesFocus = {};

  @override
  void dispose() {
    for (final t in _debounce.values) {
      t.cancel();
    }
    for (final c in _notesControllers.values) {
      c.dispose();
    }
    for (final f in _notesFocus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncNoteControllers() {
    final ids = widget.entries.map((e) => e.id).toSet();
    for (final id in _notesControllers.keys.toList()) {
      if (!ids.contains(id)) {
        _debounce[id]?.cancel();
        _debounce.remove(id);
        _notesFocus.remove(id)?.dispose();
        _notesControllers.remove(id)?.dispose();
      }
    }
    for (final e in widget.entries) {
      _notesFocus.putIfAbsent(e.id, FocusNode.new);
      if (!_notesControllers.containsKey(e.id)) {
        _notesControllers[e.id] = TextEditingController(text: e.notes);
      } else {
        final f = _notesFocus[e.id]!;
        final c = _notesControllers[e.id]!;
        if (!f.hasFocus && c.text != e.notes) {
          c.text = e.notes;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncNoteControllers();
    final theme = Theme.of(context);
    final quarters = quarterHourValues();
    final canBook = widget.orders.isNotEmpty;

    Widget stripe(String orderId) => Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: orderStripeColor(orderId),
            borderRadius: BorderRadius.circular(4),
          ),
        );

    Future<void> patch(
      TimeEntry e, {
      String? orderId,
      DateTime? workDate,
      double? hours,
      String? notes,
    }) async {
      final svc = ref.read(hoursServiceProvider);
      if (svc == null) return;
      try {
        await svc.updateEntry(
          id: e.id,
          orderId: orderId ?? e.orderId,
          workDate: workDate ?? e.workDate,
          hours: hours ?? e.hours,
          notes: notes ?? e.notes,
        );
        ref.invalidate(timesheetEntriesProvider);
      } catch (err) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speichern fehlgeschlagen: $err'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }

    void scheduleNotesSave(TimeEntry e, String text) {
      _debounce[e.id]?.cancel();
      _debounce[e.id] = Timer(const Duration(milliseconds: 550), () {
        if (e.notes != text) patch(e, notes: text);
      });
    }

    Future<void> pickDate(TimeEntry e) async {
      final first = DateTime(widget.month.year, widget.month.month, 1);
      final last = DateTime(widget.month.year, widget.month.month + 1, 0);
      final d = await showDatePicker(
        context: context,
        initialDate: _clampDateToMonth(e.workDate, widget.month),
        firstDate: first,
        lastDate: last,
      );
      if (!context.mounted) return;
      if (d != null) {
        await patch(e, workDate: _clampDateToMonth(d, widget.month));
      }
    }

    Future<void> addRow() async {
      final svc = ref.read(hoursServiceProvider);
      if (svc == null || widget.orders.isEmpty) return;
      final first = DateTime(widget.month.year, widget.month.month, 1);
      final today = DateTime.now();
      final defaultDate =
          (today.year == widget.month.year && today.month == widget.month.month)
          ? DateTime(today.year, today.month, today.day)
          : first;
      try {
        await svc.insert(
          companyId: widget.user.companyId,
          userId: widget.user.id,
          orderId: widget.orders.first.id,
          workDate: defaultDate,
          hours: 1,
          notes: '',
        );
        ref.invalidate(timesheetEntriesProvider);
      } catch (err) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Neuer Eintrag fehlgeschlagen: $err'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }

    final monthTitle = DateFormat.yMMMM('de_DE').format(widget.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 22, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stundenliste · $monthTitle',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${widget.entries.length} ${widget.entries.length == 1 ? 'Eintrag' : 'Einträge'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Align(
            key: ValueKey(widget.entries.length),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Tooltip(
                message: canBook
                    ? 'Neue Zeile in der Tabelle anlegen'
                    : 'Benötigt einen zugewiesenen Auftrag (Administration).',
                child: FilledButton.tonalIcon(
                  onPressed: canBook ? addRow : null,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Eintrag hinzufügen'),
                ),
              ),
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                primary: false,
                child: DataTable2(
                  minWidth: 1040,
                  horizontalMargin: 16,
                  columnSpacing: 10,
                  headingRowHeight: 44,
                  dataRowHeight: 88,
                  showCheckboxColumn: false,
                  showHeadingCheckBox: false,
                  empty: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.view_list_rounded,
                                size: 44,
                                color: AppColors.accent.withValues(alpha: 0.45),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Noch keine Zeilen in diesem Monat',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                canBook
                                    ? 'Das ist Ihre digitale Stundenliste: Spalten wie in einer Tabelle. '
                                        'Klicken Sie auf „Neue Zeile / Eintrag hinzufügen“, dann tragen Sie '
                                        'Auftrag, Datum (Kalender pro Zeile), Stunden in 0,25-h-Schritten und '
                                        'eine kurze Tätigkeitsbeschreibung ein. Änderungen werden gespeichert.'
                                    : 'Die Tabelle ist vorbereitet. Sobald Ihnen ein Auftrag zugewiesen ist, '
                                        'können Sie hier Zeilen anlegen und bearbeiten.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  headingRowDecoration: BoxDecoration(
                    color: AppColors.accentSoft.withValues(alpha: 0.35),
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  columns: [
                    DataColumn2(
                      label: const SizedBox(width: 8),
                      fixedWidth: 20,
                    ),
                    const DataColumn2(
                      label: Text('Auftrag'),
                      size: ColumnSize.L,
                    ),
                    const DataColumn2(
                      label: Text('Datum'),
                      size: ColumnSize.S,
                    ),
                    const DataColumn2(
                      label: Text('Stunden'),
                      size: ColumnSize.S,
                    ),
                    const DataColumn2(
                      label: Text('Tätigkeit / Notizen'),
                      size: ColumnSize.L,
                    ),
                    const DataColumn2(
                      label: Text(''),
                      fixedWidth: 52,
                    ),
                  ],
                  rows: widget.entries.map((e) {
                    return DataRow2(
                      key: ValueKey(e.id),
                      cells: [
                        DataCell(stripe(e.orderId)),
                        DataCell(
                          canBook
                              ? SizedBox(
                                  width: 260,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: widget.orders.any(
                                            (o) => o.id == e.orderId,
                                          )
                                          ? e.orderId
                                          : widget.orders.first.id,
                                      isExpanded: true,
                                      items: widget.orders
                                          .map(
                                            (o) => DropdownMenuItem(
                                              value: o.id,
                                              child: Text(
                                                o.title,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) {
                                        if (v != null) patch(e, orderId: v);
                                      },
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: 260,
                                  child: Text(
                                    'Kein Auftrag wählbar',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                        DataCell(
                          InkWell(
                            mouseCursor: SystemMouseCursors.click,
                            onTap: () => pickDate(e),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_fmtDate(e.workDate)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: quarters.contains(e.hours)
                                    ? e.hours
                                    : _nearestQuarter(e.hours, quarters),
                                isExpanded: true,
                                items: quarters
                                    .map(
                                      (h) => DropdownMenuItem(
                                        value: h,
                                        child: Text(
                                          h == h.roundToDouble()
                                              ? '${h.toInt()} h'
                                              : '${h.toString().replaceAll('.', ',')} h',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) patch(e, hours: v);
                                },
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: _notesControllers[e.id],
                              focusNode: _notesFocus[e.id],
                              maxLines: 3,
                              minLines: 2,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Kurzbeschreibung …',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                              ),
                              style: theme.textTheme.bodyMedium,
                              onChanged: (t) => scheduleNotesSave(e, t),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            tooltip: 'Eintrag löschen',
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eintrag löschen?'),
                                  content: const Text(
                                    'Der Eintrag wird unwiderruflich entfernt.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Abbrechen'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Löschen'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                              if (!context.mounted) return;
                              try {
                                await ref
                                    .read(hoursServiceProvider)
                                    ?.deleteEntry(e.id);
                                ref.invalidate(timesheetEntriesProvider);
                              } catch (err) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Löschen fehlgeschlagen: $err',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

double _nearestQuarter(double value, List<double> quarters) {
  var best = quarters.first;
  var diff = (value - best).abs();
  for (final h in quarters) {
    final d = (value - h).abs();
    if (d < diff) {
      diff = d;
      best = h;
    }
  }
  return best;
}
