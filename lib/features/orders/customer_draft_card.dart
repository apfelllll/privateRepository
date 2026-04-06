import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/features/orders/draft_list_card_constants.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:flutter/material.dart';

/// Anzeige eines lokal gespeicherten Kunden — **Name · Privatkunde/Firmenkunde**, darunter die Adresse.
class CustomerDraftCard extends StatelessWidget {
  const CustomerDraftCard({
    super.key,
    required this.customer,
    required this.onOpenDetail,
  });

  final CustomerDraft customer;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kindIcon = switch (customer.kind) {
      CustomerKind.privat => Icons.person_rounded,
      CustomerKind.firma => Icons.factory_outlined,
    };
    final addressLine = customer.formattedDeliveryLine;
    final kindLabel = switch (customer.kind) {
      CustomerKind.privat => 'Privatkunde',
      CustomerKind.firma => 'Firmenkunde',
    };
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.25,
    );
    final dotStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w900,
      color: theme.colorScheme.onSurface,
      height: 1.0,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: DoorDeskFormCard(
        child: InkWell(
          onTap: onOpenDetail,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: kDraftListCardPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kDraftListCardMinContentHeight,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    kindIcon,
                    size: kDraftListCardIconSize,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                                customer.displayTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
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
                                kindLabel,
                                style: muted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (addressLine != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            addressLine,
                            style: muted,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
