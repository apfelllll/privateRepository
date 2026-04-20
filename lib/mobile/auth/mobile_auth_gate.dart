import 'package:doordesk/core/config/supabase_config.dart';
import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/mobile/auth/mobile_login_page.dart';
import 'package:doordesk/mobile/shell/mobile_shell.dart';
import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entscheidet: Ladebildschirm, Login, Haupt-Shell oder Fehlerzustand.
class MobileAuthGate extends ConsumerWidget {
  const MobileAuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isConfigured) {
      return const _MobileSupabaseMissingScreen();
    }

    final sessionAsync = ref.watch(doorDeskSessionProvider);

    return sessionAsync.when(
      data: (DoorDeskUser? user) {
        if (user == null) {
          return const MobileLoginPage();
        }
        return const MobileShell();
      },
      loading: () => const _MobileBootstrappingScreen(),
      error: (err, _) => _MobileSessionErrorScreen(error: err),
    );
  }
}

class _MobileBootstrappingScreen extends StatelessWidget {
  const _MobileBootstrappingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _MobileSupabaseMissingScreen extends StatelessWidget {
  const _MobileSupabaseMissingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'DoorDesk',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Supabase ist nicht konfiguriert.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Start der App mit den Umgebungsvariablen SUPABASE_URL und SUPABASE_ANON_KEY.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileSessionErrorScreen extends ConsumerWidget {
  const _MobileSessionErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final message = error is UserProfileMissingException
        ? error.toString()
        : error.toString();

    Future<void> signOut() async {
      final auth = ref.read(authServiceProvider);
      await auth?.signOut();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Anmeldung unvollstaendig',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: signOut,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.accent,
                ),
                child: const Text('Abmelden und erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
