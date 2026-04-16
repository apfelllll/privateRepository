import 'package:doordesk/features/orders/customer_list_filter.dart';
import 'package:flutter/material.dart';

/// Dialog mit Checkboxen für kombinierbare Kundenfilter.
Future<CustomerListFilter?> showCustomerFilterDialog(
  BuildContext context,
  CustomerListFilter initial,
) {
  return showDialog<CustomerListFilter>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _CustomerFilterDialog(initial: initial),
  );
}

class _CustomerFilterDialog extends StatefulWidget {
  const _CustomerFilterDialog({required this.initial});

  final CustomerListFilter initial;

  @override
  State<_CustomerFilterDialog> createState() => _CustomerFilterDialogState();
}

class _CustomerFilterDialogState extends State<_CustomerFilterDialog> {
  late CustomerListFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _reset() {
    setState(() => _draft = CustomerListFilter.cleared);
  }

  Widget _mainHeading(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Filtern nach',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text, {double top = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tightAction = ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 348,
          maxWidth: 364,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mainHeading(theme),
              _sectionTitle(theme, 'Kundentyp'),
              CheckboxListTile(
                value: _draft.includePrivat,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _draft = _draft.copyWith(includePrivat: v));
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Privatkunde'),
              ),
              CheckboxListTile(
                value: _draft.includeFirma,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _draft = _draft.copyWith(includeFirma: v));
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Firmenkunde'),
              ),
              _sectionTitle(theme, 'Sortierung', top: 10),
              CheckboxListTile(
                value: _draft.sortAlphabetically,
                onChanged: (v) {
                  if (v == null) return;
                  setState(
                    () => _draft = _draft.copyWith(sortAlphabetically: v),
                  );
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Nach Alphabet'),
              ),
              _sectionTitle(theme, 'Aktivität', top: 10),
              CheckboxListTile(
                value: _draft.onlyWithActiveOrder,
                onChanged: (v) {
                  if (v == null) return;
                  setState(
                    () => _draft = _draft.copyWith(onlyWithActiveOrder: v),
                  );
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Aktiver Auftrag'),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 8,
                children: [
                  TextButton(
                    style: tightAction,
                    onPressed: _reset,
                    child: const Text('Zurücksetzen'),
                  ),
                  TextButton(
                    style: tightAction,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  FilledButton(
                    style: tightAction,
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: const Text('Übernehmen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
