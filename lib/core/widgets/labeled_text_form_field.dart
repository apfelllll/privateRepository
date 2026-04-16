import 'package:flutter/material.dart';

/// Blendet das app-weite [ThemeData.inputDecorationTheme] für das Kind aus,
/// damit [doorDeskFormInputDecoration] beim Merge nicht mit den globalen Rändern
/// kollidiert (sonst fehlt oft der sichtbare Fokus-Rand unter M3).
Widget doorDeskInputFieldTheme(BuildContext context, Widget child) {
  return Theme(
    data: Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationThemeData(),
    ),
    child: child,
  );
}

/// Überschrift + optionaler Untertitel — Inhalt beliebig ([TextField] o. ä.).
class LabeledFormBlock extends StatelessWidget {
  const LabeledFormBlock({
    super.key,
    required this.label,
    this.subtitle,
    required this.child,
  });

  final String label;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// [InputDecoration] wie Dialog „Neuer Kunde“ (hellgrau gefüllt, Radius 12).
InputDecoration doorDeskFormInputDecoration(
  BuildContext context, {
  String? hintText,
  Widget? suffixIcon,
}) {
  final theme = Theme.of(context);
  final radius = BorderRadius.circular(12);
  final outlineSide = BorderSide(
    color: theme.colorScheme.outline.withValues(alpha: 0.35),
  );
  final focusedSide = BorderSide(
    color: theme.colorScheme.primary,
    width: 2,
  );
  return InputDecoration(
    hintText: hintText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.35,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: radius, borderSide: outlineSide),
    enabledBorder:
        OutlineInputBorder(borderRadius: radius, borderSide: outlineSide),
    focusedBorder:
        OutlineInputBorder(borderRadius: radius, borderSide: focusedSide),
    disabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: outlineSide.copyWith(
        color: outlineSide.color.withValues(alpha: 0.45),
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: theme.colorScheme.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
    ),
  );
}

/// Eingabefeld im Stil „Neuer Kunde“.
class LabeledTextFormField extends StatelessWidget {
  const LabeledTextFormField({
    super.key,
    required this.label,
    this.subtitle,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
    this.readOnly = false,
    this.enabled = true,
    this.style,
    this.onTap,
    this.autofocus = false,
    this.textAlignVertical,
    this.suffixIcon,
    this.focusNode,
  });

  final String label;
  final String? subtitle;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final bool enabled;
  final TextStyle? style;
  final VoidCallback? onTap;
  final bool autofocus;
  final TextAlignVertical? textAlignVertical;
  final Widget? suffixIcon;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return LabeledFormBlock(
      label: label,
      subtitle: subtitle,
      child: doorDeskInputFieldTheme(
        context,
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: enabled,
          style: style,
          onTap: onTap,
          autofocus: autofocus,
          textAlignVertical: textAlignVertical,
          mouseCursor: onTap != null && readOnly
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          decoration: doorDeskFormInputDecoration(
            context,
            hintText: hint,
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }
}
