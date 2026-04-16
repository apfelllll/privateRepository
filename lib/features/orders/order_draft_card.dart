import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/features/orders/draft_list_card_constants.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';

/// Karte für einen lokal gespeicherten Auftrag.
///
/// Standardliste: **Bezeichnung · Typ**, darunter **Kunde**, rechts **Status**.
/// [compact]: Kunden-Detail — **Bezeichnung · Typ**, **Auftragsnummer** mittig, **Status** rechts (ohne Kundenzeile).
class OrderDraftCard extends StatelessWidget {
  const OrderDraftCard({
    super.key,
    required this.order,
    this.onOpenDetail,
    this.compact = false,
  });

  final OrderDraft order;
  final VoidCallback? onOpenDetail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.25,
    );
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final dotStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w900,
      color: theme.colorScheme.onSurface,
      height: 1.0,
    );

    final inner = Padding(
      padding: kDraftListCardPadding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kDraftListCardMinContentHeight,
        ),
        child: compact
            ? _compactRow(theme, muted, titleStyle, dotStyle)
            : _fullRow(theme, muted, titleStyle, dotStyle),
      ),
    );

    return MouseRegion(
      cursor: onOpenDetail != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: DoorDeskFormCard(
        child: onOpenDetail != null
            ? InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: onOpenDetail,
                borderRadius: BorderRadius.circular(28),
                child: inner,
              )
            : inner,
      ),
    );
  }

  /// Kunden-Detail: links Bezeichnung · Typ, Mitte Nummer, rechts Status.
  Widget _compactRow(
    ThemeData theme,
    TextStyle? muted,
    TextStyle? titleStyle,
    TextStyle? dotStyle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          order.orderType.icon,
          size: kDraftListCardIconSize,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  order.title,
                  style: titleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                child: Text('·', style: dotStyle),
              ),
              Flexible(
                flex: 2,
                child: Text(
                  order.orderType.displayLabel,
                  style: muted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Text(
              order.orderNumber,
              style: muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              order.status.displayLabel,
              style: muted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }

  /// Globale Auftragsliste: Kunde unter Auftragsnamen, Status rechts.
  Widget _fullRow(
    ThemeData theme,
    TextStyle? muted,
    TextStyle? titleStyle,
    TextStyle? dotStyle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          order.orderType.icon,
          size: kDraftListCardIconSize,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 3,
                    child: Text(
                      order.title,
                      style: titleStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: Text('·', style: dotStyle),
                  ),
                  Flexible(
                    flex: 2,
                    child: Text(
                      order.orderType.displayLabel,
                      style: muted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.customer.displayTitle,
                style: muted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              order.status.displayLabel,
              style: muted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }
}
