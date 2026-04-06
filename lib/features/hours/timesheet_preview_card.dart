import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/widgets/dashboard_white_card.dart';
import 'package:doordesk/features/hours/timesheet_data_table.dart';
import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Weiße Vorschau-Karte: Antippen klappt den Stundenzettel **im Kontext** auf
/// (keine neue Route).
class TimesheetPreviewCard extends ConsumerStatefulWidget {
  const TimesheetPreviewCard({
    super.key,
    required this.user,
  });

  final DoorDeskUser user;

  @override
  ConsumerState<TimesheetPreviewCard> createState() =>
      _TimesheetPreviewCardState();
}

class _TimesheetPreviewCardState extends ConsumerState<TimesheetPreviewCard> {
  bool _expanded = false;

  Future<void> _pickMonth(BuildContext context) async {
    final current = ref.read(selectedTimesheetMonthProvider);
    final d = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 2),
      lastDate: DateTime(current.year + 2, 12, 31),
    );
    if (d != null && context.mounted) {
      ref.read(selectedTimesheetMonthProvider.notifier).state =
          DateTime(d.year, d.month, 1);
    }
  }

  void _shiftMonth(int delta) {
    final m = ref.read(selectedTimesheetMonthProvider);
    ref.read(selectedTimesheetMonthProvider.notifier).state =
        DateTime(m.year, m.month + delta, 1);
  }

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    setState(() => _expanded = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expanded = _expanded;
    final month = ref.watch(selectedTimesheetMonthProvider);
    final monthTitle = DateFormat.yMMMM('de_DE').format(month);
    final monthLabel = DateFormat.yMMMM('de_DE').format(month);
    final entriesAsync = ref.watch(timesheetEntriesProvider);

    return DashboardWhiteCard(
      onTap: expanded ? null : () => _setExpanded(true),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            entriesAsync.when(
              data: (entries) {
                final sumH =
                    entries.fold<double>(0, (s, e) => s + e.hours);
                final sumText = sumH == sumH.roundToDouble()
                    ? '${sumH.toInt()}'
                    : sumH.toStringAsFixed(2).replaceAll('.', ',');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (expanded) ...[
                          IconButton(
                            tooltip: 'Einklappen',
                            onPressed: () => _setExpanded(false),
                            icon: Icon(
                              Icons.expand_less_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.schedule_rounded,
                            color: AppColors.accent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Stundenzettel',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                monthTitle,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!expanded)
                          Icon(
                            Icons.expand_more_rounded,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.7),
                            size: 28,
                          ),
                      ],
                    ),
                    if (!expanded) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _statChip(context, '${entries.length}', 'Einträge'),
                          const SizedBox(width: 12),
                          _statChip(context, sumText, 'Std. gesamt'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Antippen, um die Stundenliste einzublenden und zu '
                        'bearbeiten.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => Row(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Stundenzettel wird geladen…',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              error: (e, _) => Text(
                'Vorschau nicht verfügbar: $e',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (expanded) ...[
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Monat',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Vorheriger Monat',
                      ),
                      TextButton.icon(
                        onPressed: () => _pickMonth(context),
                        icon: const Icon(Icons.calendar_month_outlined, size: 20),
                        label: Text(
                          monthLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Nächster Monat',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: AppColors.background.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: ref.watch(timesheetEntriesProvider).when(
                        data: (entries) {
                          return ref.watch(assignedOrdersProvider).when(
                                data: (orders) => TimesheetDataTable(
                                  user: widget.user,
                                  month: month,
                                  entries: entries,
                                  orders: orders,
                                ),
                                loading: () => const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 48),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (e, _) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Text(
                                    'Aufträge: $e',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            '$e',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _statChip(BuildContext context, String value, String label) {
    final t = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: t.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
