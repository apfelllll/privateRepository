import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/orders/customer_delivery_map_card.dart';
import 'package:doordesk/features/orders/new_customer_dialog.dart';
import 'package:doordesk/features/orders/new_order_dialog.dart';
import 'package:doordesk/mobile/orders/mobile_order_card.dart';
import 'package:doordesk/mobile/orders/mobile_order_detail_page.dart';
import 'package:doordesk/mobile/providers/mobile_orders_providers.dart';
import 'package:doordesk/mobile/widgets/mobile_sub_page.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/number_generation_settings.dart';
import 'package:doordesk/services/permissions/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kundendetail-Seite fuer Mobile (Android): Karte, Stammdaten, Auftraege.
///
/// Liest den aktuellen Kundenzustand ueber [mobileCustomersProvider]
/// (identifiziert ueber [CustomerDraft.createdAt]), sodass Aenderungen
/// durch den Bearbeiten-Dialog sofort reflektiert werden.
class MobileCustomerDetailPage extends ConsumerWidget {
  const MobileCustomerDetailPage({super.key, required this.customerCreatedAt});

  /// Stabiler Identifier des Kunden — bleibt ueber Edits hinweg gleich.
  final DateTime customerCreatedAt;

  CustomerDraft? _currentCustomer(List<CustomerDraft> all) {
    for (final c in all) {
      if (c.createdAt == customerCreatedAt) return c;
    }
    return null;
  }

  List<OrderDraft> _ordersForCustomer(
    List<OrderDraft> all,
    CustomerDraft customer,
  ) {
    final list = all
        .where((o) => o.customer.createdAt == customer.createdAt)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    CustomerDraft current, [
    CustomerFormFocusField? focusField,
  ]) async {
    final updated = await showNewCustomerDialog(
      context,
      initial: current,
      focusField: focusField,
    );
    if (updated == null) return;
    final list = ref.read(mobileCustomersProvider);
    ref.read(mobileCustomersProvider.notifier).state = [
      for (final c in list)
        if (c.createdAt == updated.createdAt) updated else c,
    ];
  }

  Future<String> _nextOrderNumberArg(WidgetRef ref) async {
    final settings = await NumberGenerationSettings.load();
    if (settings.autoOrderNumber) return '';
    final seq = ref.read(mobileOrderNumberSeqProvider);
    final next = seq + 1;
    ref.read(mobileOrderNumberSeqProvider.notifier).state = next;
    return 'A-${next.toString().padLeft(5, '0')}';
  }

  Future<void> _openNewOrder(
    BuildContext context,
    WidgetRef ref,
    CustomerDraft current,
  ) async {
    final customers = ref.read(mobileCustomersProvider);
    final orderNumberArg = await _nextOrderNumberArg(ref);
    if (!context.mounted) return;
    final draft = await showNewOrderDialog(
      context,
      customers: customers,
      orderNumber: orderNumberArg,
      initialCustomer: current,
    );
    if (draft == null) return;
    final orders = ref.read(mobileOrdersProvider);
    ref.read(mobileOrdersProvider.notifier).state = [...orders, draft];
  }

  void _openOrderDetail(BuildContext context, OrderDraft order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileOrderDetailPage(orderCreatedAt: order.createdAt),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(doorDeskSessionProvider).value;
    final canManage =
        user != null && PermissionService.canCreateAndManageOrders(user.role);

    final customers = ref.watch(mobileCustomersProvider);
    final customer = _currentCustomer(customers);

    if (customer == null) {
      return const MobileSubPage(
        title: 'Kunde',
        child: MobileSubPagePlaceholder(
          icon: Icons.person_off_outlined,
          message: 'Dieser Kunde ist nicht mehr verfügbar.',
        ),
      );
    }

    final orders = _ordersForCustomer(
      ref.watch(mobileOrdersProvider),
      customer,
    );

    return MobileSubPage(
      title: customer.displayTitle,
      actions: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Kunde bearbeiten',
              onPressed: () => _openEdit(context, ref, customer),
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.textPrimary,
            ),
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CustomerHeader(customer: customer),
          const SizedBox(height: 16),
          _MapCard(customer: customer),
          const SizedBox(height: 20),
          _DataSection(
            customer: customer,
            onJumpToField: canManage
                ? (field) => _openEdit(context, ref, customer, field)
                : null,
          ),
          const SizedBox(height: 20),
          _OrdersSection(
            orders: orders,
            onOpenOrder: (o) => _openOrderDetail(context, o),
            onNewOrder: canManage
                ? () => _openNewOrder(context, ref, customer)
                : null,
          ),
        ],
      ),
    );
  }
}

/// Kopfzeile: Icon, Titel, Kundennummer — kurzer Kontext auf schmalen Displays.
class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.customer});

  final CustomerDraft customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompany = customer.kind == CustomerKind.firma;
    final icon = isCompany ? Icons.apartment_rounded : Icons.person_rounded;
    final subtitle = isCompany ? 'Firma' : 'Privatkunde';
    final number = customer.customerNumber.trim();

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customer.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                number.isEmpty ? subtitle : '$subtitle  ·  $number',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Karten-Kachel mit Lieferadresse — gleiche Embed-Logik wie Desktop.
class _MapCard extends StatelessWidget {
  const _MapCard({required this.customer});

  final CustomerDraft customer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: CustomerDeliveryMapCard(customer: customer),
      ),
    );
  }
}

/// Stammdaten in einer weissen Kachel — Abschnitte wie im Desktop-Detail.
class _DataSection extends StatelessWidget {
  const _DataSection({required this.customer, required this.onJumpToField});

  final CustomerDraft customer;

  /// `null` wenn der User keinen Edit-Zugriff hat — „hinzufügen“-Links werden inert.
  final void Function(CustomerFormFocusField field)? onJumpToField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(theme, 'Kontaktdaten'),
          _Line(
            theme: theme,
            label: 'Kundennummer',
            value: customer.customerNumber,
            field: CustomerFormFocusField.customerNumber,
            onJumpToField: onJumpToField,
          ),
          if (customer.kind == CustomerKind.firma) ...[
            _Line(
              theme: theme,
              label: 'Firmenname',
              value: customer.companyName,
              field: CustomerFormFocusField.companyName,
              onJumpToField: onJumpToField,
            ),
            _Line(
              theme: theme,
              label: 'Ansprechpartner',
              value: customer.contactName,
              field: CustomerFormFocusField.contactName,
              onJumpToField: onJumpToField,
            ),
          ],
          _Line(
            theme: theme,
            label: 'E-Mail',
            value: customer.email,
            field: CustomerFormFocusField.email,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Telefon',
            value: customer.phone,
            field: CustomerFormFocusField.phone,
            onJumpToField: onJumpToField,
          ),
          const SizedBox(height: 18),
          _SectionTitle(theme, 'Adresse'),
          _Line(
            theme: theme,
            label: 'Straße',
            value: customer.street,
            field: CustomerFormFocusField.street,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Hausnummer',
            value: customer.houseNumber,
            field: CustomerFormFocusField.houseNumber,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'PLZ',
            value: customer.zip,
            field: CustomerFormFocusField.zip,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Ort',
            value: customer.city,
            field: CustomerFormFocusField.city,
            onJumpToField: onJumpToField,
          ),
          const SizedBox(height: 18),
          _SectionTitle(theme, 'Rechnungsadresse'),
          _Line(
            theme: theme,
            label: 'Straße',
            value: customer.billingStreet,
            field: CustomerFormFocusField.billingStreet,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Hausnummer',
            value: customer.billingHouseNumber,
            field: CustomerFormFocusField.billingHouseNumber,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'PLZ',
            value: customer.billingZip,
            field: CustomerFormFocusField.billingZip,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Ort',
            value: customer.billingCity,
            field: CustomerFormFocusField.billingCity,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Rechnungs-E-Mail',
            value: customer.billingEmail,
            field: CustomerFormFocusField.billingEmail,
            onJumpToField: onJumpToField,
          ),
          const SizedBox(height: 18),
          _SectionTitle(theme, 'Rechnungsinformationen'),
          _Line(
            theme: theme,
            label: 'Umsatzsteuer-ID',
            value: customer.vatId,
            field: CustomerFormFocusField.vatId,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Steuernummer',
            value: customer.taxNumber,
            field: CustomerFormFocusField.taxNumber,
            onJumpToField: onJumpToField,
          ),
          _Line(
            theme: theme,
            label: 'Zahlungsbedingungen',
            value: customer.paymentTerms,
            field: CustomerFormFocusField.paymentTerms,
            onJumpToField: onJumpToField,
          ),
          const SizedBox(height: 18),
          _SectionTitle(theme, 'Notizen'),
          if (customer.notes.trim().isNotEmpty)
            Text(customer.notes.trim(), style: theme.textTheme.bodyLarge)
          else
            _AddLink(
              theme: theme,
              onTap: onJumpToField == null
                  ? null
                  : () => onJumpToField!(CustomerFormFocusField.notes),
            ),
        ],
      ),
    );
  }
}

/// Auftragsliste in eigener Sektion — kompakte [MobileOrderCard]s.
class _OrdersSection extends StatelessWidget {
  const _OrdersSection({
    required this.orders,
    required this.onOpenOrder,
    required this.onNewOrder,
  });

  final List<OrderDraft> orders;
  final void Function(OrderDraft order) onOpenOrder;
  final VoidCallback? onNewOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Aufträge',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onNewOrder != null)
              Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onNewOrder,
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Keine Aufträge für diesen Kunden.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else
          for (var i = 0; i < orders.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            MobileOrderCard(
              order: orders[i],
              onTap: () => onOpenOrder(orders[i]),
            ),
          ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Container (statt Ink) damit der Karten-Hintergrund im Scroll-Viewport
    // gemalt wird — Ink malt auf der naechsten Material oberhalb, was im
    // Scaffold-Body dazu fuehrt, dass der Hintergrund beim Scrollen/Overscroll
    // stehen bleibt, waehrend der Text mitwandert.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.theme, this.label);

  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Eine Datenzeile: Label oben, Wert bzw. „hinzufügen“-Link darunter.
///
/// Vertikales Layout ist mobil lesbarer als die Desktop-Row mit breitem Label-Spalten.
class _Line extends StatelessWidget {
  const _Line({
    required this.theme,
    required this.label,
    required this.value,
    required this.field,
    required this.onJumpToField,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final CustomerFormFocusField field;
  final void Function(CustomerFormFocusField field)? onJumpToField;

  @override
  Widget build(BuildContext context) {
    final has = value.trim().isNotEmpty;
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      fontSize: 12.5,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 2),
          if (has)
            Text(value.trim(), style: theme.textTheme.bodyLarge)
          else
            _AddLink(
              theme: theme,
              onTap: onJumpToField == null ? null : () => onJumpToField!(field),
            ),
        ],
      ),
    );
  }
}

class _AddLink extends StatelessWidget {
  const _AddLink({required this.theme, required this.onTap});

  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.bodyLarge?.copyWith(
      color: onTap == null
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.primary,
    );
    final label = Text('hinzufügen', style: style);
    if (onTap == null) return label;
    return GestureDetector(onTap: onTap, child: label);
  }
}
