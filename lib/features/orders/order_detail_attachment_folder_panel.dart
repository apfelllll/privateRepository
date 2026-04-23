import 'package:doordesk/models/order_draft.dart';
import 'package:doordesk/services/order_attachment_service.dart';
import 'package:flutter/material.dart';

/// Dateien/Dokumente eines Auftrags als vertikale Liste.
///
/// Das Hinzufügen von Dateien erfolgt zentral über den „Hinzufügen“-Button
/// in der Titelzeile der Auftragsdetailseite. Dieses Panel stellt nur noch
/// die Liste dar — Klick öffnet die Datei mit der System-App, das
/// Papierkorb-Icon entfernt sie aus dem Auftragsordner.
///
/// Über [attachmentsVersion] kann der Parent eine Neuladung anstoßen
/// (z. B. nachdem neue Dateien über die Titelzeile hinzugefügt wurden):
/// bei Änderung des Werts wird die Dateiliste erneut eingelesen.
class OrderDetailAttachmentFolderPanel extends StatefulWidget {
  const OrderDetailAttachmentFolderPanel({
    super.key,
    required this.order,
    this.canManage = true,
    this.attachmentsVersion = 0,
  });

  final OrderDraft order;

  /// Wenn `false`, wird die Löschen-Aktion pro Datei ausgeblendet (Leserechte).
  final bool canManage;

  /// Änderungsmarker: Sobald der Parent diesen Wert verändert, lädt das Panel
  /// die Dateiliste neu. Default 0.
  final int attachmentsVersion;

  @override
  State<OrderDetailAttachmentFolderPanel> createState() =>
      _OrderDetailAttachmentFolderPanelState();
}

class _OrderDetailAttachmentFolderPanelState
    extends State<OrderDetailAttachmentFolderPanel> {
  late Future<List<OrderAttachment>> _future;

  @override
  void initState() {
    super.initState();
    _future = OrderAttachmentService.listAttachments(widget.order.createdAt);
  }

  @override
  void didUpdateWidget(covariant OrderDetailAttachmentFolderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final orderChanged =
        oldWidget.order.createdAt != widget.order.createdAt;
    final versionChanged =
        oldWidget.attachmentsVersion != widget.attachmentsVersion;
    if (orderChanged || versionChanged) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _future = OrderAttachmentService.listAttachments(widget.order.createdAt);
    });
  }

  Future<void> _openFile(OrderAttachment att) async {
    final ok = await OrderAttachmentService.openFile(att.path);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datei konnte nicht geöffnet werden.')),
    );
  }

  Future<void> _openFolder() async {
    final ok = await OrderAttachmentService.openOrderFolder(
      widget.order.createdAt,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ordner konnte nicht geöffnet werden.')),
    );
  }

  Future<void> _confirmDelete(OrderAttachment att) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datei löschen?'),
        content: Text(
          '„${att.name}“ wird endgültig aus dem Auftrag entfernt.',
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
    await OrderAttachmentService.deleteAttachment(att.path);
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Dateien',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Ordner im Dateimanager öffnen',
              child: IconButton(
                onPressed: _openFolder,
                icon: const Icon(Icons.folder_open_rounded),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<OrderAttachment>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (snap.hasError) {
              return Text(
                'Dateien konnten nicht geladen werden.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              );
            }
            final items = snap.data ?? const <OrderAttachment>[];
            if (items.isEmpty) {
              return Text(
                widget.canManage
                    ? 'Noch keine Dateien. Über „Hinzufügen“ oben rechts '
                          'Dokumente zum Auftrag ablegen.'
                    : 'Noch keine Dateien.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _AttachmentListTile(
                    attachment: items[i],
                    onOpen: () => _openFile(items[i]),
                    onDelete: widget.canManage
                        ? () => _confirmDelete(items[i])
                        : null,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentListTile extends StatelessWidget {
  const _AttachmentListTile({
    required this.attachment,
    required this.onOpen,
    this.onDelete,
  });

  final OrderAttachment attachment;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconForName(attachment.name);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attachment.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatSize(attachment.sizeBytes)} • '
                      '${_formatDate(attachment.modifiedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Datei löschen',
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForName(String name) {
    final ext = name.toLowerCase();
    if (ext.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (ext.endsWith('.doc') || ext.endsWith('.docx')) {
      return Icons.description_outlined;
    }
    if (ext.endsWith('.xls') ||
        ext.endsWith('.xlsx') ||
        ext.endsWith('.csv')) {
      return Icons.table_chart_outlined;
    }
    if (ext.endsWith('.ppt') || ext.endsWith('.pptx')) {
      return Icons.slideshow_outlined;
    }
    if (ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.bmp') ||
        ext.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    if (ext.endsWith('.zip') ||
        ext.endsWith('.7z') ||
        ext.endsWith('.rar')) {
      return Icons.folder_zip_outlined;
    }
    if (ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.mkv') ||
        ext.endsWith('.avi')) {
      return Icons.movie_outlined;
    }
    if (ext.endsWith('.mp3') ||
        ext.endsWith('.wav') ||
        ext.endsWith('.flac')) {
      return Icons.audiotrack_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(gb >= 10 ? 0 : 1)} GB';
  }

  static String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}
