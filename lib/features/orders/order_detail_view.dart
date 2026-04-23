import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/features/orders/order_detail_customer_panel.dart';
import 'package:doordesk/features/orders/order_detail_data_panel.dart';
import 'package:doordesk/features/orders/order_detail_attachment_folder_panel.dart';
import 'package:doordesk/features/orders/order_detail_invoices_panel.dart';
import 'package:doordesk/features/orders/order_detail_quotes_panel.dart';
import 'package:doordesk/features/orders/order_detail_timesheet_panel.dart';
import 'dart:math' as math;

import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/invoice.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/models/quote.dart';
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
    this.invoices = const [],
    this.onOpenInvoice,
    this.quotes = const [],
    this.onOpenQuote,
    this.attachmentsVersion = 0,
  });

  final OrderDraft initialOrder;
  final VoidCallback onClose;
  final List<CustomerDraft> customers;
  final ValueChanged<OrderDraft> onOrderUpdated;
  final ValueChanged<CustomerDraft> onOpenCustomerDetail;
  final bool canManageOrders;

  /// Rechnungen, die zu diesem Auftrag existieren (Filterung erfolgt im Parent).
  final List<Invoice> invoices;

  /// Bestehende Rechnung oeffnen (Editor).
  final ValueChanged<Invoice>? onOpenInvoice;

  /// Angebote, die zu diesem Auftrag existieren (Filterung erfolgt im Parent).
  final List<Quote> quotes;

  /// Bestehendes Angebot öffnen (Editor).
  final ValueChanged<Quote>? onOpenQuote;

  /// Änderungsmarker für die Dateiliste — steigt, wenn der Parent neue Dateien
  /// über den zentralen Hinzufügen-Button in den Auftragsordner kopiert.
  final int attachmentsVersion;

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
        invoices: widget.invoices,
        onOpenInvoice: widget.onOpenInvoice,
        quotes: widget.quotes,
        onOpenQuote: widget.onOpenQuote,
        canManageAccounting: widget.canManageOrders,
        attachmentsVersion: widget.attachmentsVersion,
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
    this.invoices = const [],
    this.onOpenInvoice,
    this.quotes = const [],
    this.onOpenQuote,
    this.canManageAccounting = false,
    this.attachmentsVersion = 0,
  });

  final OrderDraft order;
  final VoidCallback? onAddNotes;
  final VoidCallback? onOpenCustomerDetail;
  final ValueChanged<OrderDraft>? onOrderUpdated;
  final List<Invoice> invoices;
  final ValueChanged<Invoice>? onOpenInvoice;
  final List<Quote> quotes;
  final ValueChanged<Quote>? onOpenQuote;

  /// Darf der aktuelle Nutzer Rechnungen erstellen/verwalten? Steuert nur die
  /// Leerzustand-Hinweise im Rechnungen-Panel — die eigentliche Erstellung
  /// erfolgt über den Hinzufügen-Button in der Titelzeile.
  final bool canManageAccounting;

  /// Änderungsmarker für die Dateiliste — wird durchgereicht an das
  /// [OrderDetailAttachmentFolderPanel].
  final int attachmentsVersion;

  static const double _kSideBySideBreakpoint = 720;
  static const double _kThreeColumnBreakpoint = 1080;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          final sideBySide = maxW >= OrderDetailPanel._kSideBySideBreakpoint;
          final threeColumns =
              maxW >= OrderDetailPanel._kThreeColumnBreakpoint;

          final customerAndData = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
            ],
          );
          final timesheetPanel = _buildTimesheetPanel(
            fillAvailableHeight: false,
            interactive: true,
          );
          final attachmentsPanel = OrderDetailAttachmentFolderPanel(
            order: widget.order,
            canManage: widget.onOrderUpdated != null,
            attachmentsVersion: widget.attachmentsVersion,
          );
          final invoicesPanel = OrderDetailInvoicesPanel(
            invoices: widget.invoices,
            canManage: widget.canManageAccounting,
            onOpenInvoice: widget.onOpenInvoice ?? (_) {},
          );
          final quotesPanel = OrderDetailQuotesPanel(
            quotes: widget.quotes,
            onOpenQuote: widget.onOpenQuote ?? (_) {},
            canManage: widget.onOrderUpdated != null,
          );
          final auftragsverlauf = _OrderHistoryColumn(
            quotes: quotesPanel,
            invoices: invoicesPanel,
            attachments: attachmentsPanel,
          );

          if (!sideBySide) {
            return ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kCustomerDetailCardWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  customerAndData,
                  const SizedBox(height: kCustomerDetailMapToDataGap),
                  timesheetPanel,
                  const SizedBox(height: kCustomerDetailMapToDataGap),
                  auftragsverlauf,
                ],
              ),
            );
          }

          if (threeColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: kCustomerDetailCardWidth,
                  child: customerAndData,
                ),
                const SizedBox(width: kCustomerDetailMapToDataGap),
                Expanded(child: timesheetPanel),
                const SizedBox(width: kCustomerDetailMapToDataGap),
                Expanded(child: auftragsverlauf),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: kCustomerDetailCardWidth,
                child: customerAndData,
              ),
              const SizedBox(width: kCustomerDetailMapToDataGap),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    timesheetPanel,
                    const SizedBox(height: kCustomerDetailMapToDataGap),
                    auftragsverlauf,
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

/// Rechte Spalte auf der Auftragsdetailseite: „Auftragsverlauf" mit den
/// Unterblöcken Angebot → Rechnungen → Dokumente.
///
/// Rendert lediglich die gemeinsame Überschrift und staplet die übergebenen
/// Sektionen in der vom Produkt gewünschten Reihenfolge.
class _OrderHistoryColumn extends StatelessWidget {
  const _OrderHistoryColumn({
    required this.quotes,
    required this.invoices,
    required this.attachments,
  });

  final Widget quotes;
  final Widget invoices;
  final Widget attachments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Auftragsverlauf',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: kCustomerDetailMapToDataGap),
        quotes,
        const SizedBox(height: kCustomerDetailMapToDataGap),
        invoices,
        const SizedBox(height: kCustomerDetailMapToDataGap),
        attachments,
      ],
    );
  }
}
