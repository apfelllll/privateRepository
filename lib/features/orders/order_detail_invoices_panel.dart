import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/invoice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Panel auf der Auftrags-Detailseite: Rechnungen zu diesem Auftrag.
///
/// Wird nur eingeblendet, wenn der Nutzer Zugriff auf die Buchhaltung hat
/// (Entscheidung trifft der Parent). Zeigt eine Liste der bisher erstellten
/// Rechnungen; Tap oeffnet den Editor. Das Anlegen neuer Rechnungen erfolgt
/// zentral über den „Hinzufügen“-Button in der Titelzeile der
/// Auftragsdetailseite.
class OrderDetailInvoicesPanel extends StatelessWidget {
  const OrderDetailInvoicesPanel({
    super.key,
    required this.invoices,
    required this.canManage,
    required this.onOpenInvoice,
  });

  /// Rechnungen, die bereits zu diesem Auftrag existieren.
  final List<Invoice> invoices;

  /// `true`: Hinweistext „Ueber Hinzuf. erstellen“ im Leerzustand einblenden.
  final bool canManage;

  final ValueChanged<Invoice> onOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Rechnungen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (invoices.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                '(${invoices.length})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          _EmptyState(canManage: canManage)
        else
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < sorted.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      color: AppColors.border,
                      indent: 16,
                      endIndent: 16,
                    ),
                  _InvoiceRow(
                    invoice: sorted[i],
                    onTap: () => onOpenInvoice(sorted[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.onTap});

  final Invoice invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDraft = invoice.status == InvoiceStatus.entwurf;
    final (bg, fg) = isDraft
        ? (const Color(0xFFFFF4E5), const Color(0xFFB25C00))
        : (const Color(0xFFE7F7EC), const Color(0xFF2E7D4F));
    final money = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final dateStr = DateFormat.yMMMd('de_DE').format(invoice.createdAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          invoice.status.displayLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Erstellt am $dateStr  ·  ${invoice.lines.length} '
                    '${invoice.lines.length == 1 ? 'Position' : 'Positionen'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              money.format(invoice.netTotal),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(
        canManage
            ? 'Noch keine Rechnung. Über „Hinzufügen“ oben rechts wird ein '
                  'Entwurf aus den erfassten Arbeitszeiten erzeugt.'
            : 'Noch keine Rechnung vorhanden.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
