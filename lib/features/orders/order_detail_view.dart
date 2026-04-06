import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/features/orders/order_detail_customer_panel.dart';
import 'package:doordesk/features/orders/order_detail_data_panel.dart';
import 'package:doordesk/features/orders/order_detail_pdf_panel.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Auftrags-Detail in der Hauptfläche (analog [CustomerDetailShell]).
class OrderDetailShell extends StatefulWidget {
  const OrderDetailShell({
    super.key,
    required this.initialOrder,
    required this.onClose,
    required this.customers,
    required this.onOrderUpdated,
    required this.onOpenCustomerDetail,
    required this.attachments,
    required this.onAddAttachments,
    required this.onRemoveAttachment,
    this.canManageOrders = false,
  });

  final OrderDraft initialOrder;
  final VoidCallback onClose;
  final List<CustomerDraft> customers;
  final ValueChanged<OrderDraft> onOrderUpdated;
  final ValueChanged<CustomerDraft> onOpenCustomerDetail;
  final List<String> attachments;
  final ValueChanged<List<String>> onAddAttachments;
  final ValueChanged<String> onRemoveAttachment;
  final bool canManageOrders;

  @override
  State<OrderDetailShell> createState() => _OrderDetailShellState();
}

class _OrderDetailShellState extends State<OrderDetailShell> {
  late OrderDraft _order;

  bool _onEscapeKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    widget.onClose();
    return true;
  }

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    HardwareKeyboard.instance.addHandler(_onEscapeKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onEscapeKey);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OrderDetailShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOrder.createdAt == _order.createdAt &&
        !identical(widget.initialOrder, _order)) {
      setState(() => _order = widget.initialOrder);
    }
  }

  Future<void> _openNotesEditor() async {
    final updated = await showNewOrderDialog(
      context,
      customers: widget.customers,
      orderNumber: _order.orderNumber,
      initialOrder: _order,
      initialFocusNotes: true,
    );
    if (!mounted || updated == null) return;
    widget.onOrderUpdated(updated);
    setState(() => _order = updated);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OrderDetailPanel(
        order: _order,
        onAddNotes: widget.canManageOrders ? _openNotesEditor : null,
        onOpenCustomerDetail: () => widget.onOpenCustomerDetail(_order.customer),
        attachments: widget.attachments,
        onAddAttachments: widget.onAddAttachments,
        onRemoveAttachment: widget.onRemoveAttachment,
      ),
    );
  }
}

class OrderDetailPanel extends StatelessWidget {
  const OrderDetailPanel({
    super.key,
    required this.order,
    required this.attachments,
    required this.onAddAttachments,
    required this.onRemoveAttachment,
    this.onAddNotes,
    this.onOpenCustomerDetail,
  });

  final OrderDraft order;
  final List<String> attachments;
  final ValueChanged<List<String>> onAddAttachments;
  final ValueChanged<String> onRemoveAttachment;
  final VoidCallback? onAddNotes;
  final VoidCallback? onOpenCustomerDetail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 32),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kCustomerDetailCardWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OrderDetailCustomerPanel(
                    customer: order.customer,
                    onTap: onOpenCustomerDetail,
                  ),
                  const SizedBox(height: kCustomerDetailMapToDataGap),
                  OrderDetailDataPanel(
                    order: order,
                    onAddNotes: onAddNotes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: kCustomerDetailMapToDataGap),
            OrderDetailPdfPanel(
              attachments: attachments,
              onAddAttachments: onAddAttachments,
              onRemoveAttachment: onRemoveAttachment,
            ),
          ],
        ),
      ),
    );
  }
}
