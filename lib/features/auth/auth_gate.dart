import 'package:doordesk/core/config/supabase_config.dart';
import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/features/auth/login_page.dart';
import 'package:doordesk/features/shell/main_shell.dart';
import 'package:doordesk/models/door_desk_user.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:doordesk/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseConfig.isConfigured) {
      return const _SupabaseMissingScreen();
    }

    final sessionAsync = ref.watch(doorDeskSessionProvider);

    return sessionAsync.when(
      data: (DoorDeskUser? user) {
        if (user == null) {
          return const LoginPage();
        }
        return const MainShell();
      },
      loading: () => const _BootstrappingScreen(),
      error: (err, stack) => _SessionErrorScreen(error: err),
    );
  }
}

class _BootstrappingScreen extends StatelessWidget {
  const _BootstrappingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 20),
            Text(
              'DoorDesk wird geladen…',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupabaseMissingScreen extends StatelessWidget {
  const _SupabaseMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DoorDesk',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supabase nicht konfiguriert',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Starte die App mit:\n\n'
                      'flutter run --dart-define=SUPABASE_URL=https://… '
                      '--dart-define=SUPABASE_ANON_KEY=…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionErrorScreen extends ConsumerWidget {
  const _SessionErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = error is UserProfileMissingException
        ? error.toString()
        : error.toString();

    Future<void> signOut() async {
      final auth = ref.read(authServiceProvider);
      await auth?.signOut();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Anmeldung unvollständig',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(message, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: signOut,
                      child: const Text('Abmelden und erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
