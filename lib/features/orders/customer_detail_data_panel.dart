import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/features/orders/new_customer_dialog.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:flutter/material.dart';

/// Stammdaten als eigene Kachel; Höhe nur so groß wie der Inhalt (kein Füllen der Spalte).
const double _kCustomerDataCardRadius = 32;
const double _kCustomerDataCardElevation = 8;

class CustomerDetailDataPanel extends StatelessWidget {
  const CustomerDetailDataPanel({
    super.key,
    required this.customer,
    required this.onJumpToField,
  });

  final CustomerDraft customer;
  final void Function(CustomerFormFocusField field) onJumpToField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void jump(CustomerFormFocusField f) => onJumpToField(f);

    final fieldsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CustomerDetailSectionTitle(theme, 'Kontaktdaten'),
        _CustomerDetailLine(
          theme: theme,
          label: 'Kundennummer',
          value: customer.customerNumber,
          focusField: CustomerFormFocusField.customerNumber,
          onJumpToField: jump,
        ),
        if (customer.kind == CustomerKind.firma) ...[
          _CustomerDetailLine(
            theme: theme,
            label: 'Firmenname',
            value: customer.companyName,
            focusField: CustomerFormFocusField.companyName,
            onJumpToField: jump,
          ),
          _CustomerDetailLine(
            theme: theme,
            label: 'Ansprechpartner',
            value: customer.contactName,
            focusField: CustomerFormFocusField.contactName,
            onJumpToField: jump,
          ),
        ],
        _CustomerDetailLine(
          theme: theme,
          label: 'E-Mail',
          value: customer.email,
          focusField: CustomerFormFocusField.email,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Telefon',
          value: customer.phone,
          focusField: CustomerFormFocusField.phone,
          onJumpToField: jump,
        ),
        const SizedBox(height: 20),
        _CustomerDetailSectionTitle(theme, 'Adresse'),
        _CustomerDetailLine(
          theme: theme,
          label: 'Straße',
          value: customer.street,
          focusField: CustomerFormFocusField.street,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Hausnummer',
          value: customer.houseNumber,
          focusField: CustomerFormFocusField.houseNumber,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'PLZ',
          value: customer.zip,
          focusField: CustomerFormFocusField.zip,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Ort',
          value: customer.city,
          focusField: CustomerFormFocusField.city,
          onJumpToField: jump,
        ),
        const SizedBox(height: 20),
        _CustomerDetailSectionTitle(theme, 'Rechnungsadresse'),
        _CustomerDetailLine(
          theme: theme,
          label: 'Straße',
          value: customer.billingStreet,
          focusField: CustomerFormFocusField.billingStreet,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Hausnummer',
          value: customer.billingHouseNumber,
          focusField: CustomerFormFocusField.billingHouseNumber,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'PLZ',
          value: customer.billingZip,
          focusField: CustomerFormFocusField.billingZip,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Ort',
          value: customer.billingCity,
          focusField: CustomerFormFocusField.billingCity,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Rechnungs-E-Mail',
          value: customer.billingEmail,
          focusField: CustomerFormFocusField.billingEmail,
          onJumpToField: jump,
        ),
        const SizedBox(height: 20),
        _CustomerDetailSectionTitle(theme, 'Rechnungsinformationen'),
        _CustomerDetailLine(
          theme: theme,
          label: 'Umsatzsteuer-ID',
          value: customer.vatId,
          focusField: CustomerFormFocusField.vatId,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Steuernummer',
          value: customer.taxNumber,
          focusField: CustomerFormFocusField.taxNumber,
          onJumpToField: jump,
        ),
        _CustomerDetailLine(
          theme: theme,
          label: 'Zahlungsbedingungen',
          value: customer.paymentTerms,
          focusField: CustomerFormFocusField.paymentTerms,
          onJumpToField: jump,
        ),
        const SizedBox(height: 20),
        _CustomerDetailSectionTitle(theme, 'Notizen'),
        if (customer.notes.trim().isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(customer.notes.trim()),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => jump(CustomerFormFocusField.notes),
                child: Text(
                  'hinzufügen',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kCustomerDetailCardWidth),
        child: Material(
          color: AppColors.surface,
          elevation: _kCustomerDataCardElevation,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(_kCustomerDataCardRadius),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: DefaultTextStyle.merge(
              style: theme.textTheme.bodyLarge,
              child: fieldsColumn,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerDetailSectionTitle extends StatelessWidget {
  const _CustomerDetailSectionTitle(this.theme, this.label);

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
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _CustomerDetailLine extends StatelessWidget {
  const _CustomerDetailLine({
    required this.theme,
    required this.label,
    required this.value,
    required this.focusField,
    required this.onJumpToField,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final CustomerFormFocusField focusField;
  final void Function(CustomerFormFocusField field) onJumpToField;

  @override
  Widget build(BuildContext context) {
    final has = value.trim().isNotEmpty;
    final linkStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.primary,
    );
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueWidget = has
        ? Align(
            alignment: Alignment.centerLeft,
            child: Text(value.trim()),
          )
        : Align(
            alignment: Alignment.centerLeft,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onJumpToField(focusField),
                child: Text('hinzufügen', style: linkStyle),
              ),
            ),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 0,
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                style: labelStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}



