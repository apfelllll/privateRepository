import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Gleiche Kartenform wie [CustomerDetailDataPanel] (Radius, Elevation, Innenabstände).
const double _kOrderDataCardRadius = 32;
const double _kOrderDataCardElevation = 8;

class OrderDetailDataPanel extends StatelessWidget {
  const OrderDetailDataPanel({
    super.key,
    required this.order,
    this.onAddNotes,
  });

  final OrderDraft order;

  /// Wenn gesetzt und keine Notizen: Link „hinzufügen“ (wie Kunden-Stammdaten).
  final VoidCallback? onAddNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat.yMMMMd('de_DE').add_Hm().format(order.createdAt);

    final fieldsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrderDetailSectionTitle(theme, 'Auftrag'),
        _OrderDetailLine(
          theme: theme,
          label: 'Auftragsnummer',
          value: order.orderNumber,
        ),
        _OrderDetailLine(
          theme: theme,
          label: 'Typ',
          value: order.orderType.displayLabel,
          valueIcon: order.orderType.icon,
        ),
        _OrderDetailLine(
          theme: theme,
          label: 'Status',
          value: order.status.displayLabel,
        ),
        _OrderDetailLine(
          theme: theme,
          label: 'Erfasst am',
          value: dateStr,
        ),
        const SizedBox(height: 20),
        _OrderDetailSectionTitle(theme, 'Notizen'),
        if (order.notes.trim().isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(order.notes.trim()),
          )
        else if (onAddNotes != null)
          Align(
            alignment: Alignment.centerLeft,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onAddNotes,
                child: Text(
                  'hinzufügen',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '—',
              style: theme.textTheme.bodyLarge,
            ),
          ),
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kCustomerDetailCardWidth),
        child: Material(
          color: AppColors.surface,
          elevation: _kOrderDataCardElevation,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(_kOrderDataCardRadius),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: DefaultTextStyle.merge(
              style: theme.textTheme.bodyLarge,
              child: fieldsColumn,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderDetailSectionTitle extends StatelessWidget {
  const _OrderDetailSectionTitle(this.theme, this.label);

  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _OrderDetailLine extends StatelessWidget {
  const _OrderDetailLine({
    required this.theme,
    required this.label,
    required this.value,
    this.valueIcon,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final IconData? valueIcon;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '—' : value.trim();
    final valueChild = valueIcon == null
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(text),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                valueIcon,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(text),
                ),
              ),
            ],
          );
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 0,
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                style: labelStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: valueChild),
        ],
      ),
    );
  }
}
