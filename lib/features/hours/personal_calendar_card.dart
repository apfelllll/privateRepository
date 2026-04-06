import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/widgets/dashboard_white_card.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Persönlicher Monatskalender in weißer Karte ( Mo–So, heute hervorgehoben ).
class PersonalCalendarCard extends ConsumerWidget {
  const PersonalCalendarCard({super.key});

  static const _weekdayShortDe = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedTimesheetMonthProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthTitle = DateFormat.yMMMM('de_DE').format(month);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekdayMon = first.weekday;
    final leadingBlanks = (firstWeekdayMon - 1) % 7;

    void shift(int d) {
      final m = ref.read(selectedTimesheetMonthProvider);
      ref.read(selectedTimesheetMonthProvider.notifier).state =
          DateTime(m.year, m.month + d, 1);
    }

    Future<void> pickMonth() async {
      final current = ref.read(selectedTimesheetMonthProvider);
      final picked = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(current.year - 2),
        lastDate: DateTime(current.year + 2, 12, 31),
      );
      if (picked != null && context.mounted) {
        ref.read(selectedTimesheetMonthProvider.notifier).state =
            DateTime(picked.year, picked.month, 1);
      }
    }

    final cells = <Widget>[];

    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final dayDate = DateTime(month.year, month.month, day);
      final isToday = dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day;
      cells.add(
        Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? AppColors.accentSoft : null,
              border: isToday
                  ? Border.all(color: AppColors.accent, width: 1.2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isToday ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return DashboardWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persönlicher Kalender',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Übersicht & Monatswahl (gilt auch für den Stundenzettel)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                onPressed: () => shift(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: TextButton(
                  onPressed: pickMonth,
                  child: Text(
                    monthTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                visualDensity: VisualDensity.compact,
                onPressed: () => shift(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final w in _weekdayShortDe)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
            children: cells,
          ),
        ],
      ),
    );
  }
}
