import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/mobile/auth/mobile_auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// MaterialApp-Baum fuer Android/iOS — eigener Einstieg, getrennt vom Desktop.
class DoorDeskMobileApp extends StatelessWidget {
  const DoorDeskMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoorDesk',
      debugShowCheckedModeBanner: false,
      theme: buildDoorDeskTheme(),
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MobileAuthGate(),
    );
  }
}
