import 'package:doordesk/core/layout/dashboard_layout.dart';
import 'package:doordesk/core/widgets/dashboard_detail_chrome.dart';
import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
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
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/number_generation_settings.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
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

const _ordersRailSections = [
  DashboardRailSection(heading: 'Aufträge', items: _ordersRailItems),
  DashboardRailSection(heading: 'Kunden', items: _kundenRailItems),
];

/// Zusätzlicher Abstand vor der ersten Kundenkarte (ca. 2 cm bei üblicher logischer Auflösung).
const double _kExtraGapBeforeFirstCustomerCard = 76;

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
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
  DateTime? _selectedCustomerCreatedAt;
  DateTime? _selectedOrderCreatedAt;
  int _orderNumberSeq = 0;

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
    final idx = _railIndex.clamp(
      0,
      flattenDashboardRailSections(_ordersRailSections).length - 1,
    );
    final isAuftraegeSection = idx < _ordersRailItems.length;
    final showNeuerAuftrag = isAuftraegeSection && canManage;
    final showNeuerKunde = !isAuftraegeSection && canManage;
    final detailCustomer = !isAuftraegeSection
        ? _resolveDetailCustomer()
        : null;
    final detailOrder = isAuftraegeSection ? _resolveDetailOrder() : null;
    final showAuftraegeListenChrome = isAuftraegeSection && detailOrder == null;
    final showKundenListenChrome =
        !isAuftraegeSection && detailCustomer == null;
    final visibleCustomers = _visibleCustomersOrdered();
    final visibleOrders = _visibleOrdersOrdered();

    final hideShellTopSearch =
        (isAuftraegeSection && detailOrder != null) ||
        (!isAuftraegeSection && detailCustomer != null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(hideShellTopSearchBarProvider.notifier);
      if (notifier.state != hideShellTopSearch) {
        notifier.state = hideShellTopSearch;
      }
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
      detailTopPadding:
          MediaQuery.paddingOf(context).top + ShellSearchLayout.detailTopAlign,
      left: DashboardLeftRail(
        sections: _ordersRailSections,
        selectedIndex: idx,
        onSelect: (i) => setState(() {
          _railIndex = i;
          if (i < _ordersRailItems.length) {
            _selectedCustomerCreatedAt = null;
          } else {
            _selectedOrderCreatedAt = null;
          }
        }),
        onLogout: widget.onLogout,
      ),
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: isAuftraegeSection
                  ? (detailOrder != null
                        ? const EdgeInsets.only(bottom: 32)
                        : const EdgeInsets.fromLTRB(28, 0, 32, 32))
                  : detailCustomer != null
                  ? const EdgeInsets.only(bottom: 32)
                  : const EdgeInsets.fromLTRB(28, 0, 32, 32),
              child: isAuftraegeSection
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DashboardDetailChrome(
                          greeting: 'Aufträge',
                          showTopBar: false,
                          reserveSpaceForGlobalSearch: false,
                          titleRowOverride: detailOrder != null
                              ? _AuftraegeDetailChromeTitleRow(
                                  order: detailOrder,
                                  onBack: _closeOrderDetail,
                                  onEdit: canManage
                                      ? () => _editOrder(detailOrder)
                                      : null,
                                )
                              : null,
                          titleTrailingSpacing:
                              showAuftraegeListenChrome && showNeuerAuftrag
                              ? 16
                              : null,
                          titleTrailing:
                              showAuftraegeListenChrome && showNeuerAuftrag
                              ? Tooltip(
                                  message: 'Neuer Auftrag',
                                  child: FilledButton(
                                    onPressed: () async {
                                      final orderArg =
                                          await _orderNumberArgForNewOrderDialog();
                                      if (!context.mounted) return;
                                      final draft = await showNewOrderDialog(
                                        context,
                                        customers: _customers,
                                        orderNumber: orderArg,
                                      );
                                      if (!context.mounted || draft == null) {
                                        return;
                                      }
                                      setState(() => _orders.add(draft));
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.all(10),
                                      minimumSize: const Size(40, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: Padding(
                            padding: detailOrder != null
                                ? const EdgeInsets.fromLTRB(28, 0, 32, 0)
                                : EdgeInsets.zero,
                            child: detailOrder != null
                                ? OrderDetailShell(
                                    key: ValueKey(detailOrder.createdAt),
                                    initialOrder: detailOrder,
                                    onClose: _closeOrderDetail,
                                    customers: _customers,
                                    canManageOrders: canManage,
                                    onOpenCustomerDetail: (customer) {
                                      setState(() {
                                        _railIndex = _ordersRailItems.length;
                                        _selectedOrderCreatedAt = null;
                                        _selectedCustomerCreatedAt =
                                            customer.createdAt;
                                      });
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
                        DashboardDetailChrome(
                          greeting: 'Kunden',
                          showTopBar: false,
                          reserveSpaceForGlobalSearch: false,
                          titleRowOverride: detailCustomer != null
                              ? _KundenDetailChromeTitleRow(
                                  customer: detailCustomer,
                                  onEdit: () => _editCustomer(detailCustomer),
                                  onBack: _closeCustomerDetail,
                                )
                              : null,
                          titleTrailingSpacing:
                              detailCustomer == null && showNeuerKunde
                              ? 16
                              : null,
                          titleTrailing:
                              detailCustomer == null && showNeuerKunde
                              ? Tooltip(
                                  message: 'Neuer Kunde',
                                  child: FilledButton(
                                    onPressed: () async {
                                      final draft = await showNewCustomerDialog(
                                        context,
                                      );
                                      if (!context.mounted || draft == null) {
                                        return;
                                      }
                                      setState(() => _customers.add(draft));
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.all(10),
                                      minimumSize: const Size(40, 40),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : null,
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
                                    onOpenOrderDetail: (o) {
                                      setState(() {
                                        _railIndex = 0;
                                        _selectedCustomerCreatedAt = null;
                                        _selectedOrderCreatedAt = o.createdAt;
                                      });
                                    },
                                    onNewOrder: canManage
                                        ? () async {
                                            final orderArg =
                                                await _orderNumberArgForNewOrderDialog();
                                            if (!context.mounted) return;
                                            final draft =
                                                await showNewOrderDialog(
                                              context,
                                              customers: _customers,
                                              orderNumber: orderArg,
                                              initialCustomer: detailCustomer,
                                            );
                                            if (!context.mounted ||
                                                draft == null) {
                                              return;
                                            }
                                            setState(() => _orders.add(draft));
                                          }
                                        : null,
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

/// Titelzeile bei geöffnetem Auftrags-Detail.
class _AuftraegeDetailChromeTitleRow extends StatelessWidget {
  const _AuftraegeDetailChromeTitleRow({
    required this.order,
    required this.onBack,
    this.onEdit,
  });

  final OrderDraft order;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    );
    final safeRight = MediaQuery.paddingOf(context).right;
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 28, right: 12),
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
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8 + safeRight),
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
        ],
      ),
    );
  }
}

/// Titelzeile in [DashboardDetailChrome] nur bei geöffnetem Kunden-Detail (ersetzt „Kunden“ + Neuer-Kunde-Button).
class _KundenDetailChromeTitleRow extends StatelessWidget {
  const _KundenDetailChromeTitleRow({
    required this.customer,
    required this.onEdit,
    required this.onBack,
  });

  final CustomerDraft customer;
  final VoidCallback onEdit;
  final VoidCallback onBack;

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
    final safeRight = MediaQuery.paddingOf(context).right;
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 28, right: 12),
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
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 8 + safeRight),
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
        ],
      ),
    );
  }
}
