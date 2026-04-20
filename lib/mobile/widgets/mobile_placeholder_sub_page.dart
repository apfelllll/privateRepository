import 'package:doordesk/mobile/widgets/mobile_sub_page.dart';
import 'package:flutter/material.dart';

/// Universelle Platzhalter-Unterseite — Titel + Icon + Nachricht.
///
/// Wird ueberall dort genutzt, wo die echte Funktion noch folgt, damit die
/// Navigation (Slide + Zurueck) schon heute vollstaendig spuerbar ist.
class MobilePlaceholderSubPage extends StatelessWidget {
  const MobilePlaceholderSubPage({
    super.key,
    required this.title,
    required this.icon,
    String? message,
  }) : _message = message;

  final String title;
  final IconData icon;
  final String? _message;

  @override
  Widget build(BuildContext context) {
    return MobileSubPage(
      title: title,
      child: MobileSubPagePlaceholder(
        icon: icon,
        message: _message ?? 'Hier erscheint bald: $title.',
      ),
    );
  }
}

/// Hilfsfunktion — pusht eine Platzhalter-Unterseite mit Standard-Slide-Animation.
void pushMobilePlaceholderPage(
  BuildContext context, {
  required String title,
  required IconData icon,
  String? message,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MobilePlaceholderSubPage(
        title: title,
        icon: icon,
        message: message,
      ),
    ),
  );
}
