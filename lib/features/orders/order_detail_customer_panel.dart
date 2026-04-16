import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:flutter/material.dart';

/// Wie [CustomerDetailDataPanel] / [OrderDetailDataPanel] — gleiche Kartenform in der Spalte.
const double _kCardRadius = 32;
const double _kCardElevation = 8;
const double _kHeaderIconSize = 26;

/// Kundenübersicht auf der Auftrags-Detailseite: **Icon + Name**, darunter **Straße · Nr.** und **PLZ Ort**.
class OrderDetailCustomerPanel extends StatelessWidget {
  const OrderDetailCustomerPanel({
    super.key,
    required this.customer,
    this.onTap,
  });

  final CustomerDraft customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kindIcon = switch (customer.kind) {
      CustomerKind.privat => Icons.person_rounded,
      CustomerKind.firma => Icons.factory_outlined,
    };
    final streetLine =
        '${customer.street.trim()} ${customer.houseNumber.trim()}'.trim();
    final zipCityLine = customer.deliveryCityLine;
    final hasAddress = streetLine.isNotEmpty || zipCityLine.isNotEmpty;

    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.25,
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              kindIcon,
              color: theme.colorScheme.primary,
              size: _kHeaderIconSize,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    customer.displayTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasAddress) ...[
                    const SizedBox(height: 8),
                    if (streetLine.isNotEmpty)
                      Text(
                        streetLine,
                        style: muted,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (streetLine.isNotEmpty && zipCityLine.isNotEmpty)
                      const SizedBox(height: 4),
                    if (zipCityLine.isNotEmpty)
                      Text(
                        zipCityLine,
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
      ],
    );

    return Material(
      color: AppColors.surface,
      elevation: _kCardElevation,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(_kCardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: body,
        ),
      ),
    );
  }
}
