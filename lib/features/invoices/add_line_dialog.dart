import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/models/invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kleines Auswahl-/Eingabe-Dialog: Typ der neuen Position waehlen und Felder
/// ausfuellen. Liefert die fertige [InvoiceLineItem] zurueck oder `null`, wenn
/// abgebrochen wurde.
Future<InvoiceLineItem?> showAddInvoiceLineDialog(BuildContext context) {
  return showDialog<InvoiceLineItem>(
    context: context,
    builder: (_) => const _AddInvoiceLineDialog(),
  );
}

class _AddInvoiceLineDialog extends StatefulWidget {
  const _AddInvoiceLineDialog();

  @override
  State<_AddInvoiceLineDialog> createState() => _AddInvoiceLineDialogState();
}

class _AddInvoiceLineDialogState extends State<_AddInvoiceLineDialog> {
  InvoiceLineKind _kind = InvoiceLineKind.material;
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _unitPrice = TextEditingController();
  final _unit = TextEditingController(text: 'Stk');

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _unitPrice.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _submit() {
    final desc = _description.text.trim();
    final qty = _parseNum(_quantity.text) ?? 0;
    final price = _parseNum(_unitPrice.text) ?? 0;
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Beschreibung eingeben.')),
      );
      return;
    }
    final id =
        'line_${DateTime.now().microsecondsSinceEpoch}_${_kind.name}';
    Navigator.of(context).pop(
      InvoiceLineItem(
        id: id,
        kind: _kind,
        active: true,
        description: desc,
        quantity: qty,
        unitPrice: price,
        unit: _kind == InvoiceLineKind.material ? _unit.text.trim() : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Neue Position'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Typ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SegmentedButton<InvoiceLineKind>(
              segments: const [
                ButtonSegment(
                  value: InvoiceLineKind.arbeit,
                  icon: Icon(Icons.schedule_rounded),
                  label: Text('Arbeit'),
                ),
                ButtonSegment(
                  value: InvoiceLineKind.material,
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Material'),
                ),
                ButtonSegment(
                  value: InvoiceLineKind.frei,
                  icon: Icon(Icons.edit_note_rounded),
                  label: Text('Frei'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _description,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'z. B. Kantholz Fichte 60x60 mm',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: _kind == InvoiceLineKind.arbeit
                          ? 'Stunden'
                          : 'Menge',
                    ),
                  ),
                ),
                if (_kind == InvoiceLineKind.material) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Einheit',
                        hintText: 'Stk',
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _unitPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: _kind == InvoiceLineKind.arbeit
                          ? 'Stundensatz'
                          : 'Einzelpreis',
                      hintText: '0,00',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Hinzufuegen'),
        ),
      ],
    );
  }
}

double? _parseNum(String raw) {
  final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return 0;
  return double.tryParse(cleaned);
}
