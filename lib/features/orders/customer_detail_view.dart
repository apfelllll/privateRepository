import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/features/orders/customer_detail_data_panel.dart';
import 'package:doordesk/features/orders/customer_detail_map_panel.dart';
import 'package:doordesk/features/orders/customer_detail_orders_panel.dart';
import 'package:doordesk/features/orders/new_customer_dialog.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kunden-Detail in der Hauptfläche (ersetzt die Kundenliste; kein Overlay-Dialog).
class CustomerDetailShell extends StatefulWidget {
  const CustomerDetailShell({
    super.key,
    required this.initialCustomer,
    required this.customerOrders,
    required this.onCustomerSaved,
    required this.onClose,
    this.onOpenOrderDetail,
  });

  final CustomerDraft initialCustomer;
  final List<OrderDraft> customerOrders;
  final void Function(CustomerDraft updated) onCustomerSaved;
  final VoidCallback onClose;
  final void Function(OrderDraft order)? onOpenOrderDetail;

  @override
  State<CustomerDetailShell> createState() => _CustomerDetailShellState();
}

class _CustomerDetailShellState extends State<CustomerDetailShell> {
  late CustomerDraft _customer;

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
    _customer = widget.initialCustomer;
    HardwareKeyboard.instance.addHandler(_onEscapeKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onEscapeKey);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomerDetailShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCustomer.createdAt == _customer.createdAt &&
        !identical(widget.initialCustomer, _customer)) {
      setState(() => _customer = widget.initialCustomer);
    }
  }

  Future<void> _openEdit([CustomerFormFocusField? focusField]) async {
    final updated = await showNewCustomerDialog(
      context,
      initial: _customer,
      focusField: focusField,
    );
    if (!mounted || updated == null) return;
    setState(() => _customer = updated);
    widget.onCustomerSaved(updated);
  }

  @override
  Widget build(BuildContext context) {
    // Kein SizedBox.expand: sonst Mindesthöhe = voller Viewport → rechte Spalte / Auftrags-Kachel wird vertikal gedehnt.
    return SizedBox(
      width: double.infinity,
      child: CustomerDetailPanel(
        customer: _customer,
        onEdit: _openEdit,
        customerOrders: widget.customerOrders,
        onOpenOrderDetail: widget.onOpenOrderDetail,
      ),
    );
  }
}

/// Zwei Spalten in einem Scroll: Map oben links; Stammdaten & Aufträge auf gleicher Y-Höhe.
class CustomerDetailPanel extends StatelessWidget {
  const CustomerDetailPanel({
    super.key,
    required this.customer,
    required this.onEdit,
    required this.customerOrders,
    this.onOpenOrderDetail,
  });

  final CustomerDraft customer;
  final Future<void> Function([CustomerFormFocusField? focusField]) onEdit;
  final List<OrderDraft> customerOrders;
  final void Function(OrderDraft order)? onOpenOrderDetail;

  @override
  Widget build(BuildContext context) {
    void jump(CustomerFormFocusField f) => onEdit(f);

    const betweenCols = 20.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 12, 32),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth.isFinite
              ? c.maxWidth
              : MediaQuery.sizeOf(context).width - 12;
          final inner = (w - betweenCols).clamp(0.0, double.infinity);
          final leftW = inner * 2 / 5;
          final rightW = inner * 3 / 5;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: leftW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomerDetailMapPanel(customer: customer),
                    const SizedBox(height: kCustomerDetailMapToDataGap),
                    CustomerDetailDataPanel(
                      customer: customer,
                      onJumpToField: jump,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: betweenCols),
              SizedBox(
                width: rightW,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: kCustomerDetailAlignedContentTopInset),
                    CustomerDetailOrdersPanel(
                      orders: customerOrders,
                      onOpenOrderDetail: onOpenOrderDetail,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
