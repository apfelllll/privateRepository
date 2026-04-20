import 'package:doordesk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Kompakter Plus-Button fuer die AppBar von Unterseiten —
/// visuell analog zum Windows-„Neuer Auftrag"-/„Neuer Kunde"-Button.
class MobileAppBarPlusButton extends StatelessWidget {
  const MobileAppBarPlusButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.add_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}
