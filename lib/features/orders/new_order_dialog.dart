import 'package:doordesk/core/widgets/door_desk_form_card.dart';
import 'package:doordesk/core/widgets/labeled_text_form_field.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';

/// Öffnet den Vollbild-Dialog „Neuer Auftrag“ oder „Auftrag bearbeiten“.
/// [customers] — bestehende Kunden für Auswahl und Suche.
/// [initialOrder] — wenn gesetzt, Formular vorbefüllt (gleiche [createdAt] beim Speichern).
Future<OrderDraft?> showNewOrderDialog(
  BuildContext context, {
  required List<CustomerDraft> customers,
  required String orderNumber,
  OrderDraft? initialOrder,
  bool initialFocusNotes = false,
}) {
  return showDialog<OrderDraft>(
    context: context,
    builder: (ctx) => _NewOrderDialog(
      customers: customers,
      orderNumber: orderNumber,
      initialOrder: initialOrder,
      initialFocusNotes: initialFocusNotes,
    ),
  );
}

const double _kNewOrderFormWidth = 640;

class _NewOrderDialog extends StatefulWidget {
  const _NewOrderDialog({
    required this.customers,
    required this.orderNumber,
    this.initialOrder,
    this.initialFocusNotes = false,
  });

  final List<CustomerDraft> customers;
  final String orderNumber;
  final OrderDraft? initialOrder;
  final bool initialFocusNotes;

  @override
  State<_NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<_NewOrderDialog> {
  late final TextEditingController _customerSearch;
  late final TextEditingController _orderTypeSearch;
  late final TextEditingController _orderNumber;
  late final TextEditingController _designation;
  late final TextEditingController _notes;
  late final FocusNode _customerFocus;
  late final FocusNode _orderTypeFocus;
  late final FocusNode _notesFocus;
  CustomerDraft? _customerFromList;
  OrderDraftType? _orderTypeFromList;

  @override
  void initState() {
    super.initState();
    _customerSearch = TextEditingController();
    _orderTypeSearch = TextEditingController();
    _orderNumber = TextEditingController(text: widget.orderNumber);
    _designation = TextEditingController();
    _notes = TextEditingController();
    _customerFocus = FocusNode();
    _orderTypeFocus = FocusNode();
    _notesFocus = FocusNode();
    _customerSearch.addListener(_onCustomerSearchChanged);
    _orderTypeSearch.addListener(_onOrderTypeSearchChanged);

    final existing = widget.initialOrder;
    if (existing != null) {
      for (final c in widget.customers) {
        if (c.createdAt == existing.customer.createdAt) {
          _customerFromList = c;
          break;
        }
      }
      _customerSearch.text = existing.customer.displayTitle;
      _orderTypeFromList = existing.orderType;
      _orderTypeSearch.text = existing.orderType.displayLabel;
      _orderNumber.text = existing.orderNumber;
      _designation.text = existing.title;
      _notes.text = existing.notes;
    }

    if (widget.initialFocusNotes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _notesFocus.requestFocus();
        }
      });
    }
  }

  void _onCustomerSearchChanged() {
    final p = _customerFromList;
    if (p != null && p.displayTitle.trim() != _customerSearch.text.trim()) {
      setState(() => _customerFromList = null);
    }
  }

  void _onOrderTypeSearchChanged() {
    final p = _orderTypeFromList;
    if (p != null && p.displayLabel.trim() != _orderTypeSearch.text.trim()) {
      setState(() => _orderTypeFromList = null);
    }
  }

  @override
  void dispose() {
    _customerSearch.removeListener(_onCustomerSearchChanged);
    _orderTypeSearch.removeListener(_onOrderTypeSearchChanged);
    _customerSearch.dispose();
    _orderTypeSearch.dispose();
    _orderNumber.dispose();
    _designation.dispose();
    _notes.dispose();
    _customerFocus.dispose();
    _orderTypeFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  OrderDraft _createDraft(CustomerDraft customer, OrderDraftType orderType) {
    final initial = widget.initialOrder;
    return OrderDraft(
      createdAt: initial?.createdAt ?? DateTime.now(),
      customer: customer,
      title: _designation.text.trim(),
      orderNumber: _orderNumber.text.trim(),
      orderType: orderType,
      status: initial?.status ?? OrderDraftStatus.inBearbeitung,
      notes: _notes.text,
    );
  }

  Iterable<CustomerDraft> _customerOptions(TextEditingValue value) {
    if (widget.customers.isEmpty) {
      return const Iterable<CustomerDraft>.empty();
    }
    final q = value.text.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.customers;
    }
    return widget.customers.where((c) {
      final title = c.displayTitle.toLowerCase();
      final mail = c.email.trim().toLowerCase();
      final num = c.customerNumber.trim().toLowerCase();
      return title.contains(q) ||
          mail.contains(q) ||
          (num.isNotEmpty && num.contains(q));
    });
  }

  CustomerDraft? _resolveCustomer(String fieldText) {
    final t = fieldText.trim();
    if (t.isEmpty) return null;

    if (_customerFromList != null &&
        _customerFromList!.displayTitle.trim() == t) {
      return _customerFromList;
    }

    final lower = t.toLowerCase();
    final exactTitle = widget.customers
        .where((c) => c.displayTitle.trim().toLowerCase() == lower)
        .toList();
    if (exactTitle.length == 1) return exactTitle.first;

    final exactEmail = widget.customers
        .where((c) => c.email.trim().toLowerCase() == lower)
        .toList();
    if (exactEmail.length == 1) return exactEmail.first;

    final contains = widget.customers
        .where((c) => c.displayTitle.toLowerCase().contains(lower))
        .toList();
    if (contains.length == 1) return contains.first;

    return null;
  }

  Iterable<OrderDraftType> _orderTypeOptions(TextEditingValue value) {
    final q = value.text.trim().toLowerCase();
    if (q.isEmpty) {
      return OrderDraftType.values;
    }
    return OrderDraftType.values.where(
      (t) => t.displayLabel.toLowerCase().contains(q),
    );
  }

  OrderDraftType? _resolveOrderType(String fieldText) {
    final t = fieldText.trim();
    if (t.isEmpty) return null;

    if (_orderTypeFromList != null &&
        _orderTypeFromList!.displayLabel.trim() == t) {
      return _orderTypeFromList;
    }

    final lower = t.toLowerCase();
    final exact = OrderDraftType.values
        .where((e) => e.displayLabel.trim().toLowerCase() == lower)
        .toList();
    if (exact.length == 1) return exact.first;

    final contains = OrderDraftType.values
        .where((e) => e.displayLabel.toLowerCase().contains(lower))
        .toList();
    if (contains.length == 1) return contains.first;

    return null;
  }

  void _trySave() {
    if (widget.customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Es gibt noch keine Kunden. Legen Sie zuerst unter „Kunden“ einen Kunden an.',
          ),
        ),
      );
      return;
    }
    if (_orderNumber.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte eine Auftragsnummer eingeben.')),
      );
      return;
    }
    if (_designation.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte einen Auftragsnamen eingeben.'),
        ),
      );
      return;
    }
    final orderType = _resolveOrderType(_orderTypeSearch.text);
    if (orderType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte einen Auftragstyp aus der Liste wählen oder so eingeben, '
            'dass genau ein Treffer zugeordnet werden kann.',
          ),
        ),
      );
      return;
    }

    final customer = _resolveCustomer(_customerSearch.text);
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bitte einen Kunden aus der Liste wählen oder so eingeben, '
            'dass genau ein Treffer zugeordnet werden kann.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(_createDraft(customer, orderType));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final screenW = MediaQuery.sizeOf(context).width;
    final formCardWidth = _kNewOrderFormWidth > screenW - 32
        ? screenW - 32
        : _kNewOrderFormWidth;

    final formCard = DoorDeskFormCard(
      child: SizedBox(
        width: formCardWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                widget.initialOrder != null ? 'Auftrag bearbeiten' : 'Neuer Auftrag',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledTextFormField(
                    label: 'Auftragsname',
                    controller: _designation,
                    hint: 'z. B. Küche Einbau',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  RawAutocomplete<CustomerDraft>(
                    focusNode: _customerFocus,
                    textEditingController: _customerSearch,
                    displayStringForOption: (c) => c.displayTitle,
                    optionsBuilder: _customerOptions,
                    onSelected: (c) {
                      setState(() {
                        _customerFromList = c;
                        _customerSearch.text = c.displayTitle;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return LabeledFormBlock(
                            label: 'Kunde',
                            child: doorDeskInputFieldTheme(
                              context,
                              TextField(
                                controller: controller,
                                focusNode: focusNode,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => onFieldSubmitted(),
                                decoration: doorDeskFormInputDecoration(
                                  context,
                                  hintText: widget.customers.isEmpty
                                      ? 'Keine Kunden vorhanden'
                                      : 'Kunde suchen oder aus Liste wählen…',
                                ),
                              ),
                            ),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      if (options.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surface,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final c = options.elementAt(index);
                                final kindIcon = switch (c.kind) {
                                  CustomerKind.privat => Icons.person_rounded,
                                  CustomerKind.firma => Icons.factory_outlined,
                                };
                                final sub = c.formattedDeliveryLine;
                                return ListTile(
                                  leading: Icon(
                                    kindIcon,
                                    color: theme.colorScheme.primary,
                                  ),
                                  title: Text(c.displayTitle),
                                  subtitle: sub == null
                                      ? null
                                      : Text(
                                          sub,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  onTap: () => onSelected(c),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  RawAutocomplete<OrderDraftType>(
                    focusNode: _orderTypeFocus,
                    textEditingController: _orderTypeSearch,
                    displayStringForOption: (t) => t.displayLabel,
                    optionsBuilder: _orderTypeOptions,
                    onSelected: (t) {
                      setState(() {
                        _orderTypeFromList = t;
                        _orderTypeSearch.text = t.displayLabel;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return LabeledFormBlock(
                            label: 'Auftragstyp',
                            child: doorDeskInputFieldTheme(
                              context,
                              TextField(
                                controller: controller,
                                focusNode: focusNode,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => onFieldSubmitted(),
                                decoration: doorDeskFormInputDecoration(
                                  context,
                                  hintText: 'Typ suchen oder aus Liste wählen…',
                                ),
                              ),
                            ),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      if (options.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surface,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final t = options.elementAt(index);
                                return ListTile(
                                  leading: Icon(
                                    t.icon,
                                    color: theme.colorScheme.primary,
                                  ),
                                  title: Text(t.displayLabel),
                                  onTap: () => onSelected(t),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  LabeledTextFormField(
                    label: 'Auftragsnummer',
                    controller: _orderNumber,
                    hint: 'z. B. A-00042',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),
                  LabeledTextFormField(
                    label: 'Notizen',
                    subtitle: 'Optional',
                    controller: _notes,
                    hint: 'Optional',
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    focusNode: _notesFocus,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _trySave,
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: screenW,
        height: screenH,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: formCard,
          ),
        ),
      ),
    );
  }
}
