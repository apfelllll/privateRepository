import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_time_entry.dart';
import 'package:flutter/material.dart';

/// Auftragsart (Neuer-Auftrag-Formular).
enum OrderDraftType { tueren, moebel, restauration, innenausbau, anderes }

extension OrderDraftTypeDisplay on OrderDraftType {
  String get displayLabel => switch (this) {
        OrderDraftType.tueren => 'Türen',
        OrderDraftType.moebel => 'Möbel',
        OrderDraftType.restauration => 'Restauration',
        OrderDraftType.innenausbau => 'Innenausbau',
        OrderDraftType.anderes => 'Anderes',
      };
}

/// Passendes Material-Icon pro Auftragstyp (Listen, Formular, Detail).
extension OrderDraftTypeIcon on OrderDraftType {
  IconData get icon => switch (this) {
        OrderDraftType.tueren => Icons.meeting_room_outlined,
        OrderDraftType.moebel => Icons.chair_outlined,
        OrderDraftType.restauration => Icons.handyman_outlined,
        OrderDraftType.innenausbau => Icons.home_work_outlined,
        OrderDraftType.anderes => Icons.widgets_outlined,
      };
}

/// Anzeige-Status für lokal erfasste Aufträge.
enum OrderDraftStatus { entwurf, inBearbeitung, abgeschlossen }

extension OrderDraftStatusDisplay on OrderDraftStatus {
  String get displayLabel => switch (this) {
    OrderDraftStatus.entwurf => 'Entwurf',
    OrderDraftStatus.inBearbeitung => 'In Bearbeitung',
    OrderDraftStatus.abgeschlossen => 'Abgeschlossen',
  };
}

/// Lokal erfasster Auftrag (bis Supabase-Anbindung).
class OrderDraft {
  const OrderDraft({
    required this.createdAt,
    required this.customer,
    required this.title,
    required this.orderNumber,
    this.orderType = OrderDraftType.tueren,
    this.status = OrderDraftStatus.inBearbeitung,
    this.notes = '',
    this.timeEntries = const [],
  });

  final DateTime createdAt;
  final CustomerDraft customer;

  /// Auftragsbezeichnung / Projektname.
  final String title;

  /// Eindeutige Auftragsnummer (z. B. A-00042).
  final String orderNumber;

  /// Auftragsart (Türen, Möbel, …).
  final OrderDraftType orderType;
  final OrderDraftStatus status;
  final String notes;

  /// Lokale Stundenliste (Arbeitszeiterfassungen zu diesem Auftrag).
  final List<OrderTimeEntry> timeEntries;

  OrderDraft copyWith({
    DateTime? createdAt,
    CustomerDraft? customer,
    String? title,
    String? orderNumber,
    OrderDraftType? orderType,
    OrderDraftStatus? status,
    String? notes,
    List<OrderTimeEntry>? timeEntries,
  }) {
    return OrderDraft(
      createdAt: createdAt ?? this.createdAt,
      customer: customer ?? this.customer,
      title: title ?? this.title,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      timeEntries: timeEntries ?? this.timeEntries,
    );
  }
}
