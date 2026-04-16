import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/features/orders/order_detail_customer_panel.dart';
import 'package:doordesk/features/orders/order_detail_data_panel.dart';
import 'package:doordesk/features/orders/order_detail_attachment_folder_panel.dart';
import 'package:doordesk/features/orders/order_detail_timesheet_panel.dart';
import 'dart:math' as math;

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
    this.canManageOrders = false,
  });

  final OrderDraft initialOrder;
  final VoidCallback onClose;
  final List<CustomerDraft> customers;
  final ValueChanged<OrderDraft> onOrderUpdated;
  final ValueChanged<CustomerDraft> onOpenCustomerDetail;
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
        onOrderUpdated: widget.canManageOrders
            ? (updated) {
                widget.onOrderUpdated(updated);
                setState(() => _order = updated);
              }
            : null,
      ),
    );
  }
}

class OrderDetailPanel extends StatefulWidget {
  const OrderDetailPanel({
    super.key,
    required this.order,
    this.onAddNotes,
    this.onOpenCustomerDetail,
    this.onOrderUpdated,
  });

  final OrderDraft order;
  final VoidCallback? onAddNotes;
  final VoidCallback? onOpenCustomerDetail;
  final ValueChanged<OrderDraft>? onOrderUpdated;

  static const double _kSideBySideBreakpoint = 720;

  @override
  State<OrderDetailPanel> createState() => _OrderDetailPanelState();
}

class _OrderDetailPanelState extends State<OrderDetailPanel> {
  Future<void> _openExpandedTimesheetDialog() async {
    final currentOrder = ValueNotifier<OrderDraft>(widget.order);
    try {
      await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        return ValueListenableBuilder<OrderDraft>(
          valueListenable: currentOrder,
          builder: (context, order, _) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(1240, size.width - 48),
                  maxHeight: size.height * 0.82,
                ),
                child: OrderDetailTimesheetPanel(
                  order: order,
                  canEdit: widget.onOrderUpdated != null,
                  onOrderUpdated: (updated) {
                    widget.onOrderUpdated?.call(updated);
                    currentOrder.value = updated;
                  },
                  fillAvailableHeight: true,
                ),
              ),
            );
          },
        );
      },
      );
    } finally {
      currentOrder.dispose();
    }
  }

  Widget _buildTimesheetPanel({
    required bool fillAvailableHeight,
    bool interactive = false,
  }) {
    final panel = IgnorePointer(
      ignoring: interactive,
      child: OrderDetailTimesheetPanel(
      order: widget.order,
      canEdit: widget.onOrderUpdated != null,
      onOrderUpdated: widget.onOrderUpdated ?? (_) {},
      fillAvailableHeight: fillAvailableHeight,
      ),
    );

    if (!interactive) return panel;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openExpandedTimesheetDialog,
        child: panel,
      ),
    );
  }

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
            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final sideBySide =
                    maxW >= OrderDetailPanel._kSideBySideBreakpoint;

                if (!sideBySide) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: kCustomerDetailCardWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OrderDetailCustomerPanel(
                          customer: widget.order.customer,
                          onTap: widget.onOpenCustomerDetail,
                        ),
                        const SizedBox(height: kCustomerDetailMapToDataGap),
                        OrderDetailDataPanel(
                          order: widget.order,
                          onAddNotes: widget.onAddNotes,
                        ),
                        const SizedBox(height: kCustomerDetailMapToDataGap),
                        _buildTimesheetPanel(
                          fillAvailableHeight: false,
                          interactive: true,
                        ),
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.min(960, maxW),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(kCustomerDetailCardWidth),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.top,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OrderDetailCustomerPanel(
                                  customer: widget.order.customer,
                                  onTap: widget.onOpenCustomerDetail,
                                ),
                                const SizedBox(
                                  height: kCustomerDetailMapToDataGap,
                                ),
                                OrderDetailDataPanel(
                                  order: widget.order,
                                  onAddNotes: widget.onAddNotes,
                                ),
                              ],
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.fill,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: kCustomerDetailMapToDataGap,
                              ),
                              child: _buildTimesheetPanel(
                                fillAvailableHeight: true,
                                interactive: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: kCustomerDetailMapToDataGap),
            OrderDetailAttachmentFolderPanel(order: widget.order),
          ],
        ),
      ),
    );
  }
}
