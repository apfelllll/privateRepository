import 'package:flutter/material.dart';

/// Weiße Material-Karte wie in den Vollbild-Formularen („Neuer Kunde“, …).
class DoorDeskFormCard extends StatelessWidget {
  const DoorDeskFormCard({
    super.key,
    required this.child,
    this.borderRadius = 28,
  });

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 6,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
