import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/services/order_attachment_service.dart';
import 'package:flutter/material.dart';

const double _kFolderIconSize = 112;

/// Öffnet den Auftragsordner im Dateimanager.
class OrderDetailAttachmentFolderPanel extends StatelessWidget {
  const OrderDetailAttachmentFolderPanel({super.key, required this.order});

  final OrderDraft order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Dateien',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () => _openFolder(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.folder_rounded,
                size: _kFolderIconSize,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder(BuildContext context) async {
    final ok = await OrderAttachmentService.openOrderFolder(order.createdAt);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ordner konnte nicht geöffnet werden.'),
      ),
    );
  }
}
