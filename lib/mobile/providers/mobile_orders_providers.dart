import 'package:doordesk/models/customer_draft.dart';
import 'package:doordesk/models/order_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

/// Geteilter Auftrags-Zustand fuer Mobile — in einer Session gueltig,
/// spiegelt das Verhalten der Windows-OrdersPage (lokale `_orders`-Liste).
/// Spaeter wird das ueber Supabase persistiert.
final mobileOrdersProvider = StateProvider<List<OrderDraft>>((ref) => const []);

/// Geteilter Kunden-Zustand fuer Mobile.
final mobileCustomersProvider =
    StateProvider<List<CustomerDraft>>((ref) => const []);

/// Fortlaufender Zaehler fuer manuelle Auftragsnummern.
/// Analog zu `_orderNumberSeq` in der Windows-OrdersPage.
final mobileOrderNumberSeqProvider = StateProvider<int>((ref) => 0);
