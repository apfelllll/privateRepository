import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';

/// Kompakte Listen-Karte fuer einen Auftrag — mobil optimiert.
///
/// Layout: Icon-Kachel links (Auftragsart-Icon), Titel + Kundenname,
/// Status-Pill rechts. Grosse Tap-Flaeche, klarer Chevron.
class MobileOrderCard extends StatelessWidget {
  const MobileOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  final OrderDraft order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = order.title.trim().isEmpty
        ? 'Ohne Titel'
        : order.title.trim();
    final customerLabel = order.customer.displayTitle;

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
                  child: Icon(
                    order.orderType.icon,
                    size: 20,
                    color: AppColors.accent,
                  ),
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
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.orderNumber,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customerLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(status: order.status),
                        ],
                      ),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderDraftStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (status) {
      OrderDraftStatus.entwurf => (
          const Color(0xFFFFF4E5),
          const Color(0xFFB25C00),
        ),
      OrderDraftStatus.inBearbeitung => (
          AppColors.accentSoft,
          AppColors.accent,
        ),
      OrderDraftStatus.abgeschlossen => (
          const Color(0xFFE7F7EC),
          const Color(0xFF2E7D4F),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.displayLabel,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
