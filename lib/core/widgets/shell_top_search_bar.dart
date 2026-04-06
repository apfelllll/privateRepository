import 'dart:ui';

import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/theme/dashboard_theme.dart';
import 'package:flutter/material.dart';

/// Zentrierte Glass-Suchleiste für die [MainShell]-Kopfzeile.
class ShellTopSearchBar extends StatelessWidget {
  const ShellTopSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Suchen…',
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextField(
          controller: controller,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyLarge,
          cursorColor: theme.colorScheme.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            filled: true,
            fillColor: DashboardTheme.glassFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: DashboardTheme.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: DashboardTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 14,
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
