import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:doordesk/features/orders/customer_delivery_map_card.dart';
import 'package:doordesk/models/customer_draft.dart';
import 'package:flutter/material.dart';

/// Eigene Kachel für Google Maps (analog zur Wetterkarte auf der Startseite).
const double _kCustomerMapCardRadius = 32;
const double _kCustomerMapCardElevation = 8;

class CustomerDetailMapPanel extends StatelessWidget {
  const CustomerDetailMapPanel({super.key, required this.customer});

  final CustomerDraft customer;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kCustomerDetailCardWidth),
        child: Material(
          color: AppColors.surface,
          elevation: _kCustomerMapCardElevation,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(_kCustomerMapCardRadius),
          clipBehavior: Clip.antiAlias,
          child: CustomerDeliveryMapCard(customer: customer),
        ),
      ),
    );
  }
}
