/// Auftrag für Dropdown (RLS: nur zugewiesene bzw. Admin alle ).
class AssignedOrder {
  const AssignedOrder({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;

  factory AssignedOrder.fromRow(Map<String, dynamic> row) {
    return AssignedOrder(
      id: row['id'] as String,
      title: row['title'] as String,
    );
  }
}
