import 'package:doordesk/features/orders/order_list_filter.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';

Future<OrderListFilter?> showOrderFilterDialog(
  BuildContext context,
  OrderListFilter initial,
) {
  return showDialog<OrderListFilter>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _OrderFilterDialog(initial: initial),
  );
}

class _OrderFilterDialog extends StatefulWidget {
  const _OrderFilterDialog({required this.initial});

  final OrderListFilter initial;

  @override
  State<_OrderFilterDialog> createState() => _OrderFilterDialogState();
}

class _OrderFilterDialogState extends State<_OrderFilterDialog> {
  late OrderListFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _reset() {
    setState(() => _draft = OrderListFilter.cleared);
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

  CheckboxListTile _typeTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String label,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) {
        if (v == null) return;
        onChanged(v);
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
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

    final maxH = MediaQuery.sizeOf(context).height * 0.58;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 348,
          maxWidth: 364,
          maxHeight: maxH.clamp(360, 560),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _mainHeading(theme),
                      _sectionTitle(theme, 'Auftragstyp'),
                      _typeTile(
                        value: _draft.includeTueren,
                        label: OrderDraftType.tueren.displayLabel,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(includeTueren: v),
                        ),
                      ),
                      _typeTile(
                        value: _draft.includeMoebel,
                        label: OrderDraftType.moebel.displayLabel,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(includeMoebel: v),
                        ),
                      ),
                      _typeTile(
                        value: _draft.includeRestauration,
                        label: OrderDraftType.restauration.displayLabel,
                        onChanged: (v) => setState(
                          () =>
                              _draft = _draft.copyWith(includeRestauration: v),
                        ),
                      ),
                      _typeTile(
                        value: _draft.includeInnenausbau,
                        label: OrderDraftType.innenausbau.displayLabel,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(includeInnenausbau: v),
                        ),
                      ),
                      _typeTile(
                        value: _draft.includeAnderes,
                        label: OrderDraftType.anderes.displayLabel,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(includeAnderes: v),
                        ),
                      ),
                      _sectionTitle(theme, 'Aktivität', top: 10),
                      _typeTile(
                        value: _draft.includeEntwurf,
                        label: OrderDraftStatus.entwurf.displayLabel,
                        onChanged: (v) => setState(
                          () => _draft = _draft.copyWith(includeEntwurf: v),
                        ),
                      ),
                      _typeTile(
                        value: _draft.includeInBearbeitung,
                        label: OrderDraftStatus.inBearbeitung.displayLabel,
                        onChanged: (v) => setState(
                          () =>
                              _draft = _draft.copyWith(includeInBearbeitung: v),
                        ),
                      ),
                      _typeTile(
                        value: _draft.includeAbgeschlossen,
                        label: OrderDraftStatus.abgeschlossen.displayLabel,
                        onChanged: (v) => setState(
                          () =>
                              _draft = _draft.copyWith(includeAbgeschlossen: v),
                        ),
                      ),
                    ],
                  ),
                ),
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
