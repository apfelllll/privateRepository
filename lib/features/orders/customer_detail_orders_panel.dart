import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/features/orders/order_draft_card.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';

/// Aufträge im Kunden-Detail: je Auftrag eine [OrderDraftCard] (kompakt, ohne Kundenspalte).
///
/// Überschrift und Karten teilen sich eine gemeinsame Breite und sind rechts in der Spalte
/// ausgerichtet — die linke Kante von „Aufträge“ entspricht der linken Kante der Karten.
class CustomerDetailOrdersPanel extends StatelessWidget {
  const CustomerDetailOrdersPanel({
    super.key,
    required this.orders,
    this.onOpenOrderDetail,
    this.onNewOrder,
  });

  final List<OrderDraft> orders;
  final void Function(OrderDraft order)? onOpenOrderDetail;

  /// Direkt rechts neben der Überschrift „Aufträge“: nur +-Symbol (Dialog mit vorbefülltem Kundenfeld).
  final VoidCallback? onNewOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emptyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Aufträge',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (onNewOrder != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Neuer Auftrag',
                child: FilledButton(
                  onPressed: onNewOrder,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(40, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.add_rounded, size: 22),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Keine Aufträge für diesen Kunden.',
              style: emptyStyle,
            ),
          )
        else
          for (var i = 0; i < orders.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            OrderDraftCard(
              order: orders[i],
              compact: true,
              onOpenDetail: onOpenOrderDetail != null
                  ? () => onOpenOrderDetail!(orders[i])
                  : null,
            ),
          ],
      ],
    );

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: kCustomerDetailOrdersCardMaxWidth,
        ),
        child: content,
      ),
    );
  }
}
