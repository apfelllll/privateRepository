import 'package:doordesk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        mouseCursor:
            onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onTap: onTap,
        hoverColor: AppColors.accentSoft.withValues(alpha: 0.35),
        splashColor: AppColors.accentSoft.withValues(alpha: 0.5),
        child: Padding(padding: padding, child: child),
      ),
    );

    return _HoverElevation(child: card);
  }
}

class _HoverElevation extends StatefulWidget {
  const _HoverElevation({required this.child});

  final Widget child;

  @override
  State<_HoverElevation> createState() => _HoverElevationState();
}

class _HoverElevationState extends State<_HoverElevation> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (_hover)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
