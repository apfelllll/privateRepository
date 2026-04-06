import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/orders/customer_detail_constants.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

const double _kOrderPdfCardRadius = 32;
const double _kOrderPdfCardElevation = 8;

class OrderDetailPdfPanel extends StatefulWidget {
  const OrderDetailPdfPanel({
    super.key,
    required this.attachments,
    required this.onAddAttachments,
    required this.onRemoveAttachment,
    this.fillHeight = false,
  });

  final List<String> attachments;
  final ValueChanged<List<String>> onAddAttachments;
  final ValueChanged<String> onRemoveAttachment;
  final bool fillHeight;

  @override
  State<OrderDetailPdfPanel> createState() => _OrderDetailPdfPanelState();
}

class _OrderDetailPdfPanelState extends State<OrderDetailPdfPanel> {
  int _pageIndex = 0;
  bool _dragging = false;

  @override
  void didUpdateWidget(covariant OrderDetailPdfPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pageIndex >= widget.attachments.length && widget.attachments.isNotEmpty) {
      _pageIndex = widget.attachments.length - 1;
    } else if (widget.attachments.isEmpty) {
      _pageIndex = 0;
    }
  }

  Future<void> _openFile(String path) async {
    final ok = await launchUrl(Uri.file(path));
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datei konnte nicht geöffnet werden.')),
    );
  }

  Future<void> _pickPdfFiles() async {
    final res = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (!mounted || res == null) return;
    final paths = res.paths.whereType<String>().where(_isPdfPath).toList();
    if (paths.isEmpty) return;
    widget.onAddAttachments(paths);
  }

  static bool _isPdfPath(String path) =>
      p.extension(path).toLowerCase() == '.pdf';

  static String _normalizeDroppedPath(String rawPath) {
    if (rawPath.startsWith('file://')) {
      return Uri.parse(rawPath).toFilePath(windows: true);
    }
    return rawPath;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachments = widget.attachments;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Anhänge',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 760,
              maxWidth: kCustomerDetailOrdersCardMaxWidth,
            ),
            child: Material(
              color: AppColors.surface,
              elevation: _kOrderPdfCardElevation,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(_kOrderPdfCardRadius),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: widget.fillHeight
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  children: [
                    if (widget.fillHeight)
                      Expanded(child: _dropSurface(theme, attachments))
                    else
                      _dropSurface(theme, attachments),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropSurface(ThemeData theme, List<String> attachments) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (detail) {
        setState(() => _dragging = false);
        final droppedPdfPaths = detail.files
            .map((f) => _normalizeDroppedPath(f.path))
            .where(_isPdfPath)
            .toList();
        if (droppedPdfPaths.isNotEmpty) {
          widget.onAddAttachments(droppedPdfPaths);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nur PDF-Dateien sind erlaubt.')),
        );
      },
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: widget.fillHeight ? 0 : 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _dragging
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
              : theme.colorScheme.surfaceContainerLowest,
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final carouselHeight = c.hasBoundedHeight
                ? (c.maxHeight - 72).clamp(220.0, 560.0)
                : 340.0;
            if (attachments.isEmpty) {
              return Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 42,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: IconButton(
                      tooltip: 'PDF auswählen',
                      onPressed: _pickPdfFiles,
                      icon: const Icon(Icons.attach_file_rounded),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 8),
                    child: IconButton(
                      tooltip: 'PDF hinzufügen',
                      onPressed: _pickPdfFiles,
                      icon: const Icon(Icons.attach_file_rounded),
                    ),
                  ),
                ),
                SizedBox(
                  height: carouselHeight,
                  child: PageView.builder(
                    itemCount: attachments.length,
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    itemBuilder: (context, index) {
                      final path = attachments[index];
                      final fileName = p.basename(path);
                      return Padding(
                        padding: const EdgeInsets.all(18),
                        child: Material(
                          borderRadius: BorderRadius.circular(14),
                          color: theme.colorScheme.surfaceContainer,
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _openFile(path),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 88,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IconButton(
                                    tooltip: 'Entfernen',
                                    onPressed: () =>
                                        widget.onRemoveAttachment(path),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (attachments.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        attachments.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _pageIndex ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _pageIndex
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
