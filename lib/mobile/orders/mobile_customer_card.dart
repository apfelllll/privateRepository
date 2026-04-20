import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:flutter/material.dart';

/// Kompakte Listen-Karte fuer einen Kunden — mobil optimiert.
class MobileCustomerCard extends StatelessWidget {
  const MobileCustomerCard({
    super.key,
    required this.customer,
    this.onTap,
  });

  final CustomerDraft customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompany = customer.kind == CustomerKind.firma;
    final icon =
        isCompany ? Icons.apartment_rounded : Icons.person_rounded;

    final subtitleLines = <String>[];
    final delivery = customer.formattedDeliveryLine;
    if (delivery != null && delivery.trim().isNotEmpty) {
      subtitleLines.add(delivery);
    }
    final email = customer.email.trim();
    final phone = customer.phone.trim();
    if (email.isNotEmpty) {
      subtitleLines.add(email);
    } else if (phone.isNotEmpty) {
      subtitleLines.add(phone);
    }

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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              customer.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (customer.customerNumber.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              customer.customerNumber.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitleLines.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleLines.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (subtitleLines.length > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleLines[1],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                          ),
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
