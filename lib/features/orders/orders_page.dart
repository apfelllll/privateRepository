import 'package:doordesk/core/widgets/dashboard_detail_chrome.dart';
import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/features/orders/customer_detail_view.dart';
import 'package:doordesk/features/orders/customer_draft_card.dart';
import 'package:doordesk/features/orders/new_customer_dialog.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/features/orders/order_detail_view.dart';
import 'package:doordesk/features/orders/order_draft_card.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
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
    super.dispose();
  }

  int _railIndex = 0;
  final List<OrderDraft> _orders = [];
  final List<CustomerDraft> _customers = [];
  final Map<DateTime, List<String>> _orderAttachmentPathsByOrder = {};
  DateTime? _selectedCustomerCreatedAt;
  DateTime? _selectedOrderCreatedAt;
  int _orderNumberSeq = 0;

  /// `null` = alle Aufträge (Listenansicht).
  OrderDraftStatus? _orderStatusFilter;

  String _nextOrderNumber() {
    _orderNumberSeq += 1;
    return 'A-${_orderNumberSeq.toString().padLeft(5, '0')}';
  }

  List<OrderDraft> _ordersForCustomer(CustomerDraft c) {
    final list = _orders
        .where((o) => o.customer.createdAt == c.createdAt)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  void _showOrdersFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(
                  'Aufträge filtern',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Alle Status'),
                leading: Icon(
                  _orderStatusFilter == null
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: _orderStatusFilter == null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  setState(() => _orderStatusFilter = null);
                  Navigator.pop(ctx);
                },
              ),
              for (final s in OrderDraftStatus.values)
                ListTile(
                  title: Text(s.displayLabel),
                  leading: Icon(
                    _orderStatusFilter == s
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: _orderStatusFilter == s
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    setState(() => _orderStatusFilter = s);
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
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
    final showAuftraegeListenChrome =
        isAuftraegeSection && detailOrder == null;

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
          _orderStatusFilter != null;
      ref.read(orderFilterShellOpenProvider.notifier).state =
          showAuftraegeListenChrome
          ? () => _showOrdersFilterSheet(context)
          : null;
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
                          titleTrailing: showAuftraegeListenChrome &&
                                  showNeuerAuftrag
                              ? Tooltip(
                                  message: 'Neuer Auftrag',
                                  child: FilledButton(
                                    onPressed: () async {
                                      final draft = await showNewOrderDialog(
                                        context,
                                        customers: _customers,
                                        orderNumber: _nextOrderNumber(),
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
                                    attachments:
                                        _orderAttachmentPathsByOrder[detailOrder
                                            .createdAt] ??
                                        const <String>[],
                                    onAddAttachments: (paths) {
                                      if (paths.isEmpty) return;
                                      setState(() {
                                        final existing =
                                            _orderAttachmentPathsByOrder[detailOrder
                                                .createdAt] ??
                                            <String>[];
                                        final merged = <String>[
                                          ...existing,
                                          ...paths.where(
                                            (p) => !existing.contains(p),
                                          ),
                                        ];
                                        _orderAttachmentPathsByOrder[detailOrder
                                            .createdAt] = merged;
                                      });
                                    },
                                    onRemoveAttachment: (path) {
                                      setState(() {
                                        final existing =
                                            _orderAttachmentPathsByOrder[detailOrder
                                                .createdAt];
                                        if (existing == null) return;
                                        existing.remove(path);
                                        if (existing.isEmpty) {
                                          _orderAttachmentPathsByOrder.remove(
                                            detailOrder.createdAt,
                                          );
                                        } else {
                                          _orderAttachmentPathsByOrder[detailOrder
                                              .createdAt] = List<String>.from(
                                            existing,
                                          );
                                        }
                                      });
                                    },
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
                                        if (_orders.isNotEmpty) ...[
                                          const SizedBox(
                                            height:
                                                20 +
                                                _kExtraGapBeforeFirstCustomerCard,
                                          ),
                                          ..._orders
                                              .where(
                                                (o) =>
                                                    _orderStatusFilter ==
                                                        null ||
                                                    o.status ==
                                                        _orderStatusFilter,
                                              )
                                              .toList()
                                              .reversed
                                              .map(
                                            (o) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: FractionallySizedBox(
                                                  widthFactor: 0.5,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: OrderDraftCard(
                                                    order: o,
                                                    onOpenDetail: () =>
                                                        _openOrderDetail(o),
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
                                  )
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (_customers.isNotEmpty) ...[
                                          const SizedBox(
                                            height:
                                                20 +
                                                _kExtraGapBeforeFirstCustomerCard,
                                          ),
                                          ..._customers.reversed.map(
                                            (c) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: FractionallySizedBox(
                                                  widthFactor: 0.5,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: CustomerDraftCard(
                                                    customer: c,
                                                    onOpenDetail: () =>
                                                        _openCustomerDetail(c),
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
