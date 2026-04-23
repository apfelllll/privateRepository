import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/quote.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Panel auf der Auftrags-Detailseite: Angebote zu diesem Auftrag.
///
/// Angebote werden typischerweise VOR dem Auftrag erstellt — sie geben dem
/// Kunden einen unverbindlichen Überblick über die geplanten Leistungen.
/// Dieses Panel listet alle Angebote des Auftrags auf; ein Tap öffnet den
/// Angebots-Editor. Neue Angebote werden zentral über den „Hinzufügen"-Button
/// in der Titelzeile angelegt.
class OrderDetailQuotesPanel extends StatelessWidget {
  const OrderDetailQuotesPanel({
    super.key,
    required this.quotes,
    required this.onOpenQuote,
    this.canManage = false,
  });

  /// Angebote, die bereits zu diesem Auftrag existieren.
  final List<Quote> quotes;

  final ValueChanged<Quote> onOpenQuote;

  /// `true`: Hinweistext „Über Hinzufügen erstellen" im Leerzustand einblenden.
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<Quote>.from(quotes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Angebot',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (quotes.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                '(${quotes.length})',
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
                  _QuoteRow(
                    quote: sorted[i],
                    onTap: () => onOpenQuote(sorted[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.quote, required this.onTap});

  final Quote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final dateStr = DateFormat.yMMMd('de_DE').format(quote.createdAt);
    final (bg, fg) = _statusColors(quote.status);
    final subtitle = quote.lines.isEmpty
        ? 'Erstellt am $dateStr  ·  noch keine Positionen'
        : 'Erstellt am $dateStr  ·  ${quote.lines.length} '
              '${quote.lines.length == 1 ? 'Position' : 'Positionen'}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.request_quote_outlined,
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
                        quote.quoteNumber,
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
                          quote.status.displayLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (quote.title.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      quote.title,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (quote.netTotal != 0)
              Text(
                money.format(quote.netTotal),
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

  static (Color, Color) _statusColors(QuoteStatus status) => switch (status) {
    QuoteStatus.entwurf => (
      const Color(0xFFFFF4E5),
      const Color(0xFFB25C00),
    ),
    QuoteStatus.versendet => (
      const Color(0xFFE3EEFF),
      const Color(0xFF1F4FAF),
    ),
    QuoteStatus.angenommen => (
      const Color(0xFFE7F7EC),
      const Color(0xFF2E7D4F),
    ),
    QuoteStatus.abgelehnt => (
      const Color(0xFFFDE2E2),
      const Color(0xFFB02828),
    ),
  };
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
            ? 'Es wurde noch kein Angebot erstellt. Über „Hinzufügen" '
                  'oben rechts kann vor Auftragsbeginn ein Angebot für '
                  'den Kunden angelegt werden.'
            : 'Es wurde noch kein Angebot erstellt.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
