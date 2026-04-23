import 'package:doordesk/core/layout/dashboard_layout.dart';
import 'package:doordesk/core/widgets/dashboard_detail_chrome.dart';
import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/features/invoices/invoice_detail_view.dart';
import 'package:doordesk/features/quotes/quote_detail_view.dart';
import 'package:doordesk/features/orders/customer_detail_view.dart';
import 'package:doordesk/features/orders/customer_draft_card.dart';
import 'package:doordesk/features/orders/customer_filter_dialog.dart';
import 'package:doordesk/features/orders/customer_list_filter.dart';
import 'package:doordesk/features/orders/order_filter_dialog.dart';
import 'package:doordesk/features/orders/order_list_filter.dart';
import 'package:doordesk/features/orders/new_customer_dialog.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/features/orders/order_detail_view.dart';
import 'package:doordesk/features/orders/order_draft_card.dart';
import 'package:doordesk/features/shell/shell_navigation_items.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/invoice.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/models/quote.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/calculation_settings.dart';
import 'package:doordesk/services/number_generation_settings.dart';
import 'package:doordesk/services/order_attachment_service.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _ordersRailItems = [
  DashboardRailItem(icon: Icons.folder_open_rounded, label: 'Alle Aufträge'),
  DashboardRailItem(icon: Icons.hourglass_top_rounded, label: 'In Bearbeitung'),
  DashboardRailItem(icon: Icons.archive_outlined, label: 'Archiv'),
];

const _kundenRailItems = [
  DashboardRailItem(icon: Icons.groups_outlined, label: 'Alle Kunden'),
  DashboardRailItem(icon: Icons.person_search_outlined, label: 'Aktive Kunden'),
];

/// Zusätzlicher Abstand vor der ersten Kundenkarte (ca. 2 cm bei üblicher logischer Auflösung).
const double _kExtraGapBeforeFirstCustomerCard = 76;

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({
    super.key,
    required this.onLogout,
    required this.selectedRailIndex,
    required this.openCustomersSection,
    required this.onShellSelect,
    required this.onRailSelect,
    required this.initialSubIndex,
  });

  final VoidCallback onLogout;
  final int selectedRailIndex;
  final bool openCustomersSection;
  final ValueChanged<int> onShellSelect;
  final ValueChanged<int> onRailSelect;
  final int initialSubIndex;

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  @override
  void initState() {
    super.initState();
    _railIndex = widget.initialSubIndex;
  }

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openCustomersSection != widget.openCustomersSection) {
      setState(() {
        _railIndex = widget.initialSubIndex;
        if (widget.openCustomersSection) {
          _selectedOrderCreatedAt = null;
        } else {
          _selectedCustomerCreatedAt = null;
        }
      });
    }
    if (oldWidget.initialSubIndex != widget.initialSubIndex) {
      setState(() => _railIndex = widget.initialSubIndex);
    }
  }

  @override
  void dispose() {
    ref.read(showShellOrdersFilterButtonProvider.notifier).state = false;
    ref.read(ordersListFilterActiveProvider.notifier).state = false;
    ref.read(orderFilterShellOpenProvider.notifier).state = null;
    ref.read(showShellCustomersFilterButtonProvider.notifier).state = false;
    ref.read(customersListFilterActiveProvider.notifier).state = false;
    ref.read(customerFilterShellOpenProvider.notifier).state = null;
    super.dispose();
  }

  int _railIndex = 0;
  final List<OrderDraft> _orders = [];
  final List<CustomerDraft> _customers = [];
  final List<Invoice> _invoices = [];
  final List<Quote> _quotes = [];
  DateTime? _selectedCustomerCreatedAt;
  DateTime? _selectedOrderCreatedAt;
  String? _selectedQuoteId;
  String? _selectedInvoiceId;
  int _orderNumberSeq = 0;
  int _attachmentsVersion = 0;

  OrderListFilter _orderFilter = OrderListFilter.cleared;

  CustomerListFilter _customerFilter = CustomerListFilter.cleared;

  String _nextOrderNumber() {
    _orderNumberSeq += 1;
    return 'A-${_orderNumberSeq.toString().padLeft(5, '0')}';
  }

  /// Bei manueller Auftragsnummer: Vorschlag aus lokalem Zähler. Bei automatischer
  /// Vergabe leer — [showNewOrderDialog] nutzt [OrderNumberSequence].
  Future<String> _orderNumberArgForNewOrderDialog() async {
    final s = await NumberGenerationSettings.load();
    if (s.autoOrderNumber) return '';
    return _nextOrderNumber();
  }

  List<OrderDraft> _visibleOrdersOrdered() {
    final list = _orders.where((o) => _orderFilter.matches(o)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<OrderDraft> _ordersForCustomer(CustomerDraft c) {
    final list = _orders
        .where((o) => o.customer.createdAt == c.createdAt)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Gefilterte und ggf. alphabetisch sortierte Kundenliste.
  List<CustomerDraft> _visibleCustomersOrdered() {
    final list = _customers.where((c) {
      if (!_customerFilter.matchesKind(c)) return false;
      if (_customerFilter.onlyWithActiveOrder) {
        final hasActive = _ordersForCustomer(
          c,
        ).any((o) => o.status == OrderDraftStatus.inBearbeitung);
        if (!hasActive) return false;
      }
      return true;
    }).toList();

    if (_customerFilter.sortAlphabetically) {
      list.sort(
        (a, b) => a.displayTitle.toLowerCase().compareTo(
          b.displayTitle.toLowerCase(),
        ),
      );
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  void _openCustomerDetail(CustomerDraft c) {
    setState(() => _selectedCustomerCreatedAt = c.createdAt);
  }

  void _closeCustomerDetail() {
    setState(() => _selectedCustomerCreatedAt = null);
  }

  void _openOrderDetail(OrderDraft o) {
    setState(() => _selectedOrderCreatedAt = o.createdAt);
  }

  void _closeOrderDetail() {
    setState(() => _selectedOrderCreatedAt = null);
  }

  /// Legt aus einem Auftrag einen Rechnungs-Entwurf an (Snapshot) und oeffnet
  /// den Editor. Rechnungsnummer kommt aus lokaler Sequenz (SharedPreferences).
  Future<void> _createInvoiceForOrder(OrderDraft order) async {
    final calc = await CalculationSettings.load();
    final number = await InvoiceNumberSequence.consumeNextFormatted();
    if (!mounted) return;
    final invoice = Invoice.fromOrder(
      order: order,
      calc: calc,
      invoiceNumber: number,
      createdAt: DateTime.now(),
    );
    setState(() => _invoices.add(invoice));
    _openInvoiceEditor(invoice);
  }

  /// Öffnet die Rechnungs-Detailseite innerhalb der App-Shell (Left-Rail und
  /// Tab-Leiste bleiben sichtbar) — genauso wie bei Angebots-, Auftrags- und
  /// Kundendetailansicht wird nur der Detail-Bereich ausgetauscht.
  void _openInvoiceEditor(Invoice invoice) {
    setState(() {
      _selectedInvoiceId = invoice.id;
      _selectedQuoteId = null;
    });
  }

  void _closeInvoiceDetail() {
    setState(() => _selectedInvoiceId = null);
  }

  Invoice? _resolveDetailInvoice() {
    if (_selectedInvoiceId == null) return null;
    for (final i in _invoices) {
      if (i.id == _selectedInvoiceId) return i;
    }
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _selectedInvoiceId = null);
    });
    return null;
  }

  void _upsertInvoice(Invoice updated) {
    if (!mounted) return;
    setState(() {
      final i = _invoices.indexWhere((x) => x.id == updated.id);
      if (i >= 0) {
        _invoices[i] = updated;
      } else {
        _invoices.add(updated);
      }
    });
  }

  List<Invoice> _invoicesForOrder(OrderDraft order) {
    return _invoices
        .where((inv) => inv.orderCreatedAt == order.createdAt)
        .toList();
  }

  /// Legt zu einem Auftrag einen leeren Angebots-Entwurf an (Snapshot von
  /// Kunde + Auftrag) und öffnet direkt die Angebots-Detailseite. Die
  /// Angebotsnummer wird aus der lokalen [QuoteNumberSequence] bezogen.
  Future<void> _createQuoteForOrder(OrderDraft order) async {
    final number = await QuoteNumberSequence.consumeNextFormatted();
    if (!mounted) return;
    final quote = Quote.emptyFromOrder(
      order: order,
      quoteNumber: number,
      createdAt: DateTime.now(),
    );
    setState(() => _quotes.add(quote));
    _openQuoteEditor(quote);
  }

  /// Öffnet die Angebots-Detailseite innerhalb der App-Shell (Left-Rail und
  /// Tab-Leiste bleiben sichtbar) — genauso wie bei Auftrags- und
  /// Kundendetailansicht wird nur der Detail-Bereich ausgetauscht.
  void _openQuoteEditor(Quote quote) {
    setState(() => _selectedQuoteId = quote.id);
  }

  /// Erzeugt aus einem Angebot einen Rechnungs-Entwurf (Positionen werden 1:1
  /// übernommen, Snapshot-Prinzip) und öffnet direkt den Rechnungs-Editor.
  Future<void> _createInvoiceFromQuote(Quote quote) async {
    final number = await InvoiceNumberSequence.consumeNextFormatted();
    if (!mounted) return;
    final invoice = quote.toInvoiceDraft(
      invoiceNumber: number,
      createdAt: DateTime.now(),
    );
    setState(() {
      _invoices.add(invoice);
      // Damit beim Schließen der Rechnung nicht die leere Liste erscheint,
      // sondern der zugehörige Auftrag: wir setzen ihn als Hintergrund-Detail.
      _selectedOrderCreatedAt = quote.orderCreatedAt;
    });
    _openInvoiceEditor(invoice);
  }

  /// Platzhalter — PDF-Druck folgt, sobald das Angebots-PDF-Template steht.
  void _printQuote(Quote quote) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Angebot ${quote.quoteNumber} drucken: Funktion folgt in Kürze.',
        ),
      ),
    );
  }

  /// Platzhalter — Mail-Versand folgt, sobald PDF-Export + SMTP angebunden
  /// sind.
  void _emailQuote(Quote quote) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Angebot ${quote.quoteNumber} per Mail versenden: Funktion folgt in Kürze.',
        ),
      ),
    );
  }

  void _closeQuoteDetail() {
    setState(() => _selectedQuoteId = null);
  }

  Quote? _resolveDetailQuote() {
    if (_selectedQuoteId == null) return null;
    for (final q in _quotes) {
      if (q.id == _selectedQuoteId) return q;
    }
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _selectedQuoteId = null);
    });
    return null;
  }

  void _upsertQuote(Quote updated) {
    if (!mounted) return;
    setState(() {
      final i = _quotes.indexWhere((x) => x.id == updated.id);
      if (i >= 0) {
        _quotes[i] = updated;
      } else {
        _quotes.add(updated);
      }
    });
  }

  List<Quote> _quotesForOrder(OrderDraft order) {
    return _quotes
        .where((q) => q.orderCreatedAt == order.createdAt)
        .toList();
  }

  OrderDraft? _resolveDetailOrder() {
    if (_selectedOrderCreatedAt == null) return null;
    for (final o in _orders) {
      if (o.createdAt == _selectedOrderCreatedAt) return o;
    }
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _selectedOrderCreatedAt = null);
    });
    return null;
  }

  Future<void> _editCustomer(CustomerDraft c) async {
    final updated = await showNewCustomerDialog(context, initial: c);
    if (!mounted || updated == null) return;
    setState(() {
      final i = _customers.indexWhere((x) => x.createdAt == updated.createdAt);
      if (i >= 0) {
        _customers[i] = updated;
      }
    });
  }

  Future<void> _confirmDeleteCustomer(CustomerDraft c) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kunde löschen?'),
        content: Text(
          '„${c.displayTitle}“ wird gelöscht. '
          'Alle zugehörigen Aufträge werden ebenfalls entfernt.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    setState(() {
      _customers.removeWhere((x) => x.createdAt == c.createdAt);
      _orders.removeWhere((o) => o.customer.createdAt == c.createdAt);
      if (_selectedCustomerCreatedAt == c.createdAt) {
        _selectedCustomerCreatedAt = null;
      }
      if (_selectedOrderCreatedAt != null &&
          !_orders.any((o) => o.createdAt == _selectedOrderCreatedAt)) {
        _selectedOrderCreatedAt = null;
      }
    });
  }

  Future<void> _openCustomerFilterDialog() async {
    final next = await showCustomerFilterDialog(context, _customerFilter);
    if (!mounted || next == null) return;
    setState(() => _customerFilter = next);
  }

  Future<void> _openOrderFilterDialog() async {
    final next = await showOrderFilterDialog(context, _orderFilter);
    if (!mounted || next == null) return;
    setState(() => _orderFilter = next);
  }

  /// Öffnet den „Neuer Auftrag"-Dialog und legt bei Bestätigung den Entwurf
  /// an. Wird sowohl vom lokalen Kundendetail-Plus-Menü als auch vom
  /// globalen „+"-Button in der Shell-Kopfleiste genutzt.
  Future<void> _createNewOrderFromShell() async {
    final orderArg = await _orderNumberArgForNewOrderDialog();
    if (!mounted) return;
    final draft = await showNewOrderDialog(
      context,
      customers: _customers,
      orderNumber: orderArg,
    );
    if (!mounted || draft == null) return;
    setState(() => _orders.add(draft));
  }

  Future<void> _createNewCustomerFromShell() async {
    final draft = await showNewCustomerDialog(context);
    if (!mounted || draft == null) return;
    setState(() => _customers.add(draft));
  }

  /// Relative Position direkt unter einem Widget-[context] — wird für
  /// showMenu-Aufrufe aus der Shell-Kopfleiste genutzt.
  RelativeRect? _menuPositionUnder(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return null;
    final topLeft =
        box.localToGlobal(Offset(0, box.size.height + 6), ancestor: overlay);
    final bottomRight =
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);
    return RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      overlay.size.width - bottomRight.dx,
      overlay.size.height - bottomRight.dy,
    );
  }

  /// Öffnet das „Hinzufügen"-Menü für den aktuell offenen Auftrag direkt
  /// unter dem Shell-„+"-Button. Enthält Datei / Angebot / Rechnung,
  /// jeweils nur wenn die entsprechende Aktion erlaubt ist.
  Future<void> _openOrderDetailAddMenu(
    BuildContext buttonContext,
    OrderDraft order,
  ) async {
    final position = _menuPositionUnder(buttonContext);
    if (position == null) return;
    final selected = await showMenu<_OrderAddAction>(
      context: buttonContext,
      position: position,
      items: const <PopupMenuEntry<_OrderAddAction>>[
        PopupMenuItem<_OrderAddAction>(
          value: _OrderAddAction.file,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.upload_file_outlined),
            title: Text('Datei'),
          ),
        ),
        PopupMenuItem<_OrderAddAction>(
          value: _OrderAddAction.quote,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.request_quote_outlined),
            title: Text('Angebot'),
          ),
        ),
        PopupMenuItem<_OrderAddAction>(
          value: _OrderAddAction.invoice,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('Rechnung'),
          ),
        ),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case _OrderAddAction.file:
        await _addFilesToOrder(order);
        break;
      case _OrderAddAction.quote:
        await _createQuoteForOrder(order);
        break;
      case _OrderAddAction.invoice:
        await _createInvoiceForOrder(order);
        break;
    }
  }

  /// Öffnet das „Hinzufügen"-Menü für den aktuell offenen Kunden direkt
  /// unter dem Shell-„+"-Button. Enthält Auftrag / Angebot / Rechnung.
  Future<void> _openCustomerDetailAddMenu(
    BuildContext buttonContext,
    CustomerDraft customer,
  ) async {
    final position = _menuPositionUnder(buttonContext);
    if (position == null) return;
    final selected = await showMenu<_CustomerAddAction>(
      context: buttonContext,
      position: position,
      items: const <PopupMenuEntry<_CustomerAddAction>>[
        PopupMenuItem<_CustomerAddAction>(
          value: _CustomerAddAction.order,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.assignment_outlined),
            title: Text('Auftrag'),
          ),
        ),
        PopupMenuItem<_CustomerAddAction>(
          value: _CustomerAddAction.quote,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.request_quote_outlined),
            title: Text('Angebot'),
          ),
        ),
        PopupMenuItem<_CustomerAddAction>(
          value: _CustomerAddAction.invoice,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.receipt_long_outlined),
            title: Text('Rechnung'),
          ),
        ),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case _CustomerAddAction.order:
        final orderArg = await _orderNumberArgForNewOrderDialog();
        if (!mounted) return;
        final draft = await showNewOrderDialog(
          context,
          customers: _customers,
          orderNumber: orderArg,
          initialCustomer: customer,
        );
        if (!mounted || draft == null) return;
        setState(() => _orders.add(draft));
        break;
      case _CustomerAddAction.quote:
        _showAddStubSnack('Angebot');
        break;
      case _CustomerAddAction.invoice:
        _showAddStubSnack('Rechnung');
        break;
    }
  }

  /// Platzhalter-Rückmeldung für noch nicht implementierte Hinzufügen-Einträge
  /// (Angebot, eigenständige Rechnung). Die echten Flows werden separat gebaut.
  void _showAddStubSnack(String kind) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$kind: Funktion folgt in Kürze.')),
    );
  }

  /// Öffnet den System-Dateidialog und kopiert die gewählten Dateien in den
  /// Auftragsordner. Erhöht anschließend [_attachmentsVersion], damit das
  /// Dateien-Panel seine Liste neu lädt.
  Future<void> _addFilesToOrder(OrderDraft order) async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Dateien zum Auftrag hinzufügen',
      allowMultiple: true,
      withData: false,
      lockParentWindow: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final paths = result.files
        .map((f) => f.path)
        .whereType<String>()
        .toList(growable: false);
    if (paths.isEmpty) return;
    await OrderAttachmentService.addAttachments(order.createdAt, paths);
    if (!mounted) return;
    setState(() => _attachmentsVersion++);
  }

  Future<void> _editOrder(OrderDraft o) async {
    final updated = await showNewOrderDialog(
      context,
      customers: _customers,
      orderNumber: o.orderNumber,
      initialOrder: o,
    );
    if (!mounted || updated == null) return;
    setState(() {
      final i = _orders.indexWhere((x) => x.createdAt == updated.createdAt);
      if (i >= 0) {
        _orders[i] = updated;
      }
    });
  }

  CustomerDraft? _resolveDetailCustomer() {
    if (_selectedCustomerCreatedAt == null) return null;
    for (final c in _customers) {
      if (c.createdAt == _selectedCustomerCreatedAt) return c;
    }
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _selectedCustomerCreatedAt = null);
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(doorDeskSessionProvider).value;
    if (user == null) return const SizedBox.shrink();
    final canManage = PermissionService.canCreateAndManageOrders(user.role);
    final isAuftraegeSection = !widget.openCustomersSection;
    final idx = _railIndex.clamp(
      0,
      (isAuftraegeSection ? _ordersRailItems.length : _kundenRailItems.length) - 1,
    );
    final showNeuerAuftrag = isAuftraegeSection && canManage;
    final showNeuerKunde = !isAuftraegeSection && canManage;
    final detailCustomer = !isAuftraegeSection
        ? _resolveDetailCustomer()
        : null;
    final detailOrder = isAuftraegeSection ? _resolveDetailOrder() : null;
    final detailQuote = isAuftraegeSection ? _resolveDetailQuote() : null;
    final detailInvoice = isAuftraegeSection ? _resolveDetailInvoice() : null;
    final hasAnyAuftraegeDetail =
        detailOrder != null || detailQuote != null || detailInvoice != null;
    final showAuftraegeListenChrome =
        isAuftraegeSection && !hasAnyAuftraegeDetail;
    final showKundenListenChrome =
        !isAuftraegeSection && detailCustomer == null;
    final visibleCustomers = _visibleCustomersOrdered();
    final visibleOrders = _visibleOrdersOrdered();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(showShellOrdersFilterButtonProvider.notifier).state =
          showAuftraegeListenChrome;
      ref.read(ordersListFilterActiveProvider.notifier).state =
          _orderFilter.hasActiveFilter;
      ref.read(orderFilterShellOpenProvider.notifier).state =
          showAuftraegeListenChrome ? _openOrderFilterDialog : null;

      ref.read(showShellCustomersFilterButtonProvider.notifier).state =
          showKundenListenChrome;
      ref.read(customersListFilterActiveProvider.notifier).state =
          _customerFilter.hasActiveFilter;
      ref.read(customerFilterShellOpenProvider.notifier).state =
          showKundenListenChrome ? _openCustomerFilterDialog : null;
    });

    return DashboardSplit(
      leftWidth: 272,
      detailTopPadding: MediaQuery.paddingOf(context).top +
          ShellSearchLayout.detailTopAlign,
      left: DashboardLeftRail(
        sections: shellRailSections,
        selectedIndex: widget.selectedRailIndex,
        onSelect: widget.onRailSelect,
        onLogout: widget.onLogout,
      ),
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: isAuftraegeSection
                  ? (hasAnyAuftraegeDetail
                        ? const EdgeInsets.only(bottom: 32)
                        : const EdgeInsets.fromLTRB(28, 0, 32, 32))
                  : detailCustomer != null
                  ? const EdgeInsets.only(bottom: 32)
                  : const EdgeInsets.fromLTRB(28, 0, 32, 32),
              child: isAuftraegeSection
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Überschrift „Aufträge" + „Neuer Auftrag"-Button
                        // sitzen direkt am Seitenanfang neben der
                        // Überschrift. In Detail-Ansichten wird die
                        // Titelzeile durch [titleRowOverride] ersetzt.
                        if (!hasAnyAuftraegeDetail)
                          DashboardDetailChrome(
                            greeting: 'Aufträge',
                            titleTrailingSpacing: 12,
                            titleTrailing: showNeuerAuftrag
                                ? _NewEntityButton(
                                    label: 'Neuer Auftrag',
                                    onPressed: _createNewOrderFromShell,
                                  )
                                : null,
                          )
                        else
                          DashboardDetailChrome(
                            greeting: 'Aufträge',
                            reserveSpaceForGlobalSearch: false,
                            titleRowOverride: detailInvoice != null
                                ? _RechnungDetailChromeTitleRow(
                                    invoice: detailInvoice,
                                    onBack: _closeInvoiceDetail,
                                  )
                                : detailQuote != null
                                ? _AngebotDetailChromeTitleRow(
                                    quote: detailQuote,
                                    onBack: _closeQuoteDetail,
                                    onPrint: () => _printQuote(detailQuote),
                                    onEmail: () => _emailQuote(detailQuote),
                                    onCreateInvoice: canManage
                                        ? () => _createInvoiceFromQuote(
                                              detailQuote,
                                            )
                                        : null,
                                  )
                                : detailOrder != null
                                ? _AuftraegeDetailChromeTitleRow(
                                    order: detailOrder,
                                    onBack: _closeOrderDetail,
                                    onEdit: canManage
                                        ? () => _editOrder(detailOrder)
                                        : null,
                                    onAddPressed: canManage
                                        ? (btnCtx) =>
                                              _openOrderDetailAddMenu(
                                                btnCtx,
                                                detailOrder,
                                              )
                                        : null,
                                  )
                                : null,
                          ),
                        Expanded(
                          child: Padding(
                            padding: hasAnyAuftraegeDetail
                                ? const EdgeInsets.fromLTRB(28, 0, 32, 0)
                                : EdgeInsets.zero,
                            child: detailInvoice != null
                                ? InvoiceDetailShell(
                                    key: ValueKey(detailInvoice.id),
                                    initialInvoice: detailInvoice,
                                    onClose: _closeInvoiceDetail,
                                    canManage: canManage,
                                    onInvoiceUpdated: _upsertInvoice,
                                  )
                                : detailQuote != null
                                ? QuoteDetailShell(
                                    key: ValueKey(detailQuote.id),
                                    initialQuote: detailQuote,
                                    onClose: _closeQuoteDetail,
                                    canManage: canManage,
                                    onQuoteUpdated: _upsertQuote,
                                  )
                                : detailOrder != null
                                ? OrderDetailShell(
                                    key: ValueKey(detailOrder.createdAt),
                                    initialOrder: detailOrder,
                                    onClose: _closeOrderDetail,
                                    customers: _customers,
                                    canManageOrders: canManage,
                                    invoices: _invoicesForOrder(detailOrder),
                                    quotes: _quotesForOrder(detailOrder),
                                    attachmentsVersion: _attachmentsVersion,
                                    onOpenInvoice: _openInvoiceEditor,
                                    onOpenQuote: _openQuoteEditor,
                                    onOpenCustomerDetail: (_) {
                                      setState(() {
                                        _selectedOrderCreatedAt = null;
                                      });
                                      widget.onShellSelect(2);
                                    },
                                    onOrderUpdated: (updated) {
                                      setState(() {
                                        final i = _orders.indexWhere(
                                          (x) =>
                                              x.createdAt == updated.createdAt,
                                        );
                                        if (i >= 0) {
                                          _orders[i] = updated;
                                        }
                                      });
                                    },
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (_orders.isNotEmpty &&
                                            visibleOrders.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 48,
                                              bottom: 24,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Keine Aufträge für diese '
                                                'Filterkombination.',
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        if (visibleOrders.isNotEmpty) ...[
                                          const SizedBox(
                                            height:
                                                20 +
                                                _kExtraGapBeforeFirstCustomerCard,
                                          ),
                                          ...visibleOrders.map(
                                            (o) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: LayoutBuilder(
                                                builder: (context, lc) {
                                                  final half =
                                                      lc.maxWidth >=
                                                      DashboardLayout
                                                          .listHalfWidthMinDetailWidth;
                                                  return Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: FractionallySizedBox(
                                                      widthFactor: half
                                                          ? 0.5
                                                          : 1.0,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: OrderDraftCard(
                                                        order: o,
                                                        onOpenDetail: () =>
                                                            _openOrderDetail(o),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Überschrift „Kunden" + „Neuer Kunde"-Button sitzen
                        // direkt am Seitenanfang. In der Detailansicht wird
                        // die Titelzeile durch [titleRowOverride] ersetzt.
                        if (detailCustomer == null)
                          DashboardDetailChrome(
                            greeting: 'Kunden',
                            titleTrailingSpacing: 12,
                            titleTrailing: showNeuerKunde
                                ? _NewEntityButton(
                                    label: 'Neuer Kunde',
                                    onPressed: _createNewCustomerFromShell,
                                  )
                                : null,
                          )
                        else
                          DashboardDetailChrome(
                            greeting: 'Kunden',
                            reserveSpaceForGlobalSearch: false,
                            titleRowOverride: _KundenDetailChromeTitleRow(
                              customer: detailCustomer,
                              onEdit: () => _editCustomer(detailCustomer),
                              onBack: _closeCustomerDetail,
                              onAddPressed: canManage
                                  ? (btnCtx) => _openCustomerDetailAddMenu(
                                        btnCtx,
                                        detailCustomer,
                                      )
                                  : null,
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: detailCustomer != null
                                ? const EdgeInsets.fromLTRB(28, 0, 32, 0)
                                : EdgeInsets.zero,
                            child: detailCustomer != null
                                ? CustomerDetailShell(
                                    key: ValueKey(detailCustomer.createdAt),
                                    initialCustomer: detailCustomer,
                                    customerOrders: _ordersForCustomer(
                                      detailCustomer,
                                    ),
                                    onCustomerSaved: (updated) {
                                      setState(() {
                                        final i = _customers.indexWhere(
                                          (x) =>
                                              x.createdAt == updated.createdAt,
                                        );
                                        if (i >= 0) {
                                          _customers[i] = updated;
                                        }
                                      });
                                    },
                                    onClose: _closeCustomerDetail,
                                    onOpenOrderDetail: (_) {
                                      setState(() {
                                        _selectedCustomerCreatedAt = null;
                                      });
                                      widget.onShellSelect(1);
                                    },
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (_customers.isNotEmpty &&
                                            visibleCustomers.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 48,
                                              bottom: 24,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Keine Kunden für diese '
                                                'Filterkombination.',
                                                textAlign: TextAlign.center,
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        if (visibleCustomers.isNotEmpty) ...[
                                          const SizedBox(
                                            height:
                                                20 +
                                                _kExtraGapBeforeFirstCustomerCard,
                                          ),
                                          ...visibleCustomers.map(
                                            (c) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: LayoutBuilder(
                                                builder: (context, lc) {
                                                  final half =
                                                      lc.maxWidth >=
                                                      DashboardLayout
                                                          .listHalfWidthMinDetailWidth;
                                                  return Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: FractionallySizedBox(
                                                      widthFactor: half
                                                          ? 0.5
                                                          : 1.0,
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: CustomerDraftCard(
                                                        customer: c,
                                                        onOpenDetail: () =>
                                                            _openCustomerDetail(
                                                              c,
                                                            ),
                                                        onEdit: canManage
                                                            ? () =>
                                                                _editCustomer(c)
                                                            : null,
                                                        onDelete: canManage
                                                            ? () =>
                                                                _confirmDeleteCustomer(
                                                                  c,
                                                                )
                                                            : null,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Titelzeile bei geöffnetem Angebots-Detail. Zurück-Button ganz links,
/// dann Angebots-Icon + Nummer/Titel. Rechts oben: Drucken, Mail und der
/// zentrale „Erstellen“-Button (aktuell mit „Rechnung“ als einziger Option).
class _AngebotDetailChromeTitleRow extends StatelessWidget {
  const _AngebotDetailChromeTitleRow({
    required this.quote,
    required this.onBack,
    this.onPrint,
    this.onEmail,
    this.onCreateInvoice,
  });

  final Quote quote;
  final VoidCallback onBack;
  final VoidCallback? onPrint;
  final VoidCallback? onEmail;
  final VoidCallback? onCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final safeLeft = MediaQuery.paddingOf(context).left;
    final safeRight = MediaQuery.paddingOf(context).right;
    final titleText = quote.title.trim().isEmpty
        ? 'Angebot ${quote.quoteNumber}'
        : 'Angebot ${quote.quoteNumber} — ${quote.title}';
    final hasCreateAction = onCreateInvoice != null;
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16 + safeLeft, right: 4),
            child: IconButton(
              tooltip: 'Zurück zum Auftrag',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.request_quote_outlined,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      titleText,
                      style: headlineStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onPrint != null) ...[
            _DetailTitleCircleAction(
              icon: Icons.print_outlined,
              tooltip: 'Angebot drucken',
              onTap: onPrint!,
            ),
            const SizedBox(width: 8),
          ],
          if (onEmail != null) ...[
            _DetailTitleCircleAction(
              icon: Icons.mail_outline_rounded,
              tooltip: 'Angebot per Mail versenden',
              onTap: onEmail!,
            ),
            const SizedBox(width: 8),
          ],
          if (hasCreateAction)
            _QuoteCreateMenu(onCreateInvoice: onCreateInvoice),
          SizedBox(
            width: ShellSearchLayout.trailingShellActionsReserve + safeRight,
          ),
        ],
      ),
    );
  }
}

/// Kreisförmiger Aktions-Button für Detail-Titelzeilen (Drucken / Mail /
/// Finalisieren usw.). Stilistisch identisch zum „Bearbeiten“-Symbol in der
/// Kunden-/Auftragszeile, wiederverwendet für Angebots- und
/// Rechnungs-Titelzeilen.
class _DetailTitleCircleAction extends StatelessWidget {
  const _DetailTitleCircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22, color: theme.colorScheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Zentraler „Erstellen“-Button rechts oben auf der Angebotsdetail-Seite.
///
/// Klappt ein Menü auf, über das aus dem Angebot Folge-Dokumente erzeugt
/// werden können. Aktuell nur „Rechnung“ — weitere Einträge (z. B. Auftrag
/// bestätigen, Angebot duplizieren) folgen, sobald die zugehörigen Flows
/// existieren. Einträge ohne Callback werden ausgeblendet.
class _QuoteCreateMenu extends StatefulWidget {
  const _QuoteCreateMenu({this.onCreateInvoice});

  final VoidCallback? onCreateInvoice;

  @override
  State<_QuoteCreateMenu> createState() => _QuoteCreateMenuState();
}

class _QuoteCreateMenuState extends State<_QuoteCreateMenu> {
  final GlobalKey _buttonKey = GlobalKey();

  Future<void> _open() async {
    final buttonContext = _buttonKey.currentContext;
    if (buttonContext == null) return;
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlay == null) return;

    final topLeft = buttonBox.localToGlobal(
      Offset(0, buttonBox.size.height + 6),
      ancestor: overlay,
    );
    final bottomRight = buttonBox.localToGlobal(
      buttonBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );
    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy,
      overlay.size.width - bottomRight.dx,
      overlay.size.height - bottomRight.dy,
    );

    final selected = await showMenu<_QuoteCreateAction>(
      context: buttonContext,
      position: position,
      items: <PopupMenuEntry<_QuoteCreateAction>>[
        if (widget.onCreateInvoice != null)
          const PopupMenuItem<_QuoteCreateAction>(
            value: _QuoteCreateAction.invoice,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('Rechnung'),
            ),
          ),
      ],
    );

    if (!mounted || selected == null) return;
    switch (selected) {
      case _QuoteCreateAction.invoice:
        widget.onCreateInvoice?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Folge-Dokument aus diesem Angebot erstellen',
      waitDuration: const Duration(milliseconds: 400),
      child: FilledButton.icon(
        key: _buttonKey,
        onPressed: _open,
        icon: const Icon(Icons.auto_awesome_outlined, size: 20),
        label: const Text('Erstellen'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

enum _QuoteCreateAction { invoice }

/// Titelzeile bei geöffnetem Rechnungs-Detail. Zurück-Button ganz links,
/// dann Rechnungs-Icon + Nummer/Titel. Rechts oben: Drucken, Mail und —
/// nur bei Entwurfs-Rechnungen und passender Berechtigung — ein
/// „Finalisieren“-Button. Nach dem Finalisieren verschwindet der Button;
/// der Read-only-Hinweis wandert in die Detailseite (Banner).
class _RechnungDetailChromeTitleRow extends StatelessWidget {
  const _RechnungDetailChromeTitleRow({
    required this.invoice,
    required this.onBack,
  });

  final Invoice invoice;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final safeLeft = MediaQuery.paddingOf(context).left;
    final safeRight = MediaQuery.paddingOf(context).right;
    final titleText = invoice.orderTitle.trim().isEmpty
        ? 'Rechnung ${invoice.invoiceNumber}'
        : 'Rechnung ${invoice.invoiceNumber} — ${invoice.orderTitle}';
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16 + safeLeft, right: 4),
            child: IconButton(
              tooltip: 'Zurück',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      titleText,
                      style: headlineStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: ShellSearchLayout.trailingShellActionsReserve + safeRight,
          ),
        ],
      ),
    );
  }
}

/// Titelzeile bei geöffnetem Auftrags-Detail: Zurück-Button, Icon, Titel,
/// Bearbeiten-Knopf und — falls [onAddPressed] gesetzt ist — ein zentraler
/// „Hinzufügen“-Button mit Popup-Menü (Datei / Angebot / Rechnung). Der
/// Menü-Aufruf erhält den Button-[BuildContext], damit [showMenu] das Menü
/// direkt unter dem Button platzieren kann.
class _AuftraegeDetailChromeTitleRow extends StatelessWidget {
  const _AuftraegeDetailChromeTitleRow({
    required this.order,
    required this.onBack,
    this.onEdit,
    this.onAddPressed,
  });

  final OrderDraft order;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final void Function(BuildContext)? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final safeLeft = MediaQuery.paddingOf(context).left;
    final safeRight = MediaQuery.paddingOf(context).right;
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16 + safeLeft, right: 4),
            child: IconButton(
              tooltip: 'Zurück zur Auftragsliste',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Row(
                children: [
                  Icon(
                    order.orderType.icon,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      order.title,
                      style: headlineStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 12),
                    Semantics(
                      button: true,
                      label: 'Auftrag bearbeiten',
                      child: Tooltip(
                        message: 'Auftrag bearbeiten',
                        waitDuration: const Duration(milliseconds: 400),
                        child: Material(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            mouseCursor: SystemMouseCursors.click,
                            onTap: onEdit,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 22,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (onAddPressed != null) ...[
                    const SizedBox(width: 12),
                    _DetailAddMenuButton(
                      tooltip:
                          'Neuen Eintrag zu diesem Auftrag hinzufügen',
                      onPressed: onAddPressed!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: ShellSearchLayout.trailingShellActionsReserve + safeRight),
        ],
      ),
    );
  }
}

/// Aktionen des „+"-Popup-Menüs auf der Auftragsdetail-Seite. Das Menü
/// wird in [_OrdersPageState._openOrderDetailAddMenu] konfiguriert und
/// direkt unter dem „Hinzufügen"-Button der Titelzeile geöffnet.
enum _OrderAddAction { file, quote, invoice }

/// Titelzeile in [DashboardDetailChrome] bei geöffnetem Kunden-Detail:
/// Zurück-Button, Kunden-Icon, Titel, Bearbeiten-Knopf und — falls
/// [onAddPressed] gesetzt ist — ein zentraler „Hinzufügen"-Button mit
/// Popup-Menü (Auftrag / Angebot / Rechnung). Der Menü-Aufruf erhält den
/// Button-[BuildContext], damit [showMenu] das Menü direkt unter dem
/// Button platzieren kann.
class _KundenDetailChromeTitleRow extends StatelessWidget {
  const _KundenDetailChromeTitleRow({
    required this.customer,
    required this.onEdit,
    required this.onBack,
    this.onAddPressed,
  });

  final CustomerDraft customer;
  final VoidCallback onEdit;
  final VoidCallback onBack;
  final void Function(BuildContext)? onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kindIcon = switch (customer.kind) {
      CustomerKind.privat => Icons.person_rounded,
      CustomerKind.firma => Icons.factory_outlined,
    };
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final safeLeft = MediaQuery.paddingOf(context).left;
    final safeRight = MediaQuery.paddingOf(context).right;
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16 + safeLeft, right: 4),
            child: IconButton(
              tooltip: 'Zurück zur Kundenliste',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 12),
              child: Row(
                children: [
                  Icon(kindIcon, size: 32, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      customer.displayTitle,
                      style: headlineStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Kunden bearbeiten',
                    child: Tooltip(
                      message: 'Kunden bearbeiten',
                      waitDuration: const Duration(milliseconds: 400),
                      child: Material(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          mouseCursor: SystemMouseCursors.click,
                          onTap: onEdit,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (onAddPressed != null) ...[
                    const SizedBox(width: 12),
                    _DetailAddMenuButton(
                      tooltip: 'Neuen Eintrag für diesen Kunden anlegen',
                      onPressed: onAddPressed!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: ShellSearchLayout.trailingShellActionsReserve + safeRight),
        ],
      ),
    );
  }
}

/// Aktionen des „+"-Popup-Menüs auf der Kundendetail-Seite. Das Menü
/// wird in [_OrdersPageState._openCustomerDetailAddMenu] konfiguriert
/// und direkt unter dem „Hinzufügen"-Button der Titelzeile geöffnet.
enum _CustomerAddAction { order, quote, invoice }

/// Primärer „Neuer …"-Button neben der Überschrift einer Listenansicht
/// (z. B. „Neuer Auftrag" oder „Neuer Kunde"). Einheitlicher Stil, damit
/// die Hauptaktion in jedem Listenkopf gleich aussieht.
class _NewEntityButton extends StatelessWidget {
  const _NewEntityButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 400),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

/// „Hinzufügen"-Button mit Popup-Menü in den Auftrags-/Kunden-Detail-
/// Titelzeilen. Der [onPressed]-Callback bekommt den Button-Kontext und
/// darf darüber [showMenu] direkt unter dem Button öffnen.
class _DetailAddMenuButton extends StatelessWidget {
  const _DetailAddMenuButton({
    required this.tooltip,
    required this.onPressed,
  });

  final String tooltip;
  final void Function(BuildContext) onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Builder(
        builder: (btnCtx) => FilledButton.icon(
          onPressed: () => onPressed(btnCtx),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Hinzufügen'),
          style: FilledButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            minimumSize: const Size(0, 40),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }
}
