import 'dart:ui';

import 'package:doordesk/core/layout/dashboard_layout.dart';
import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/theme/dashboard_theme.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/features/calendar/calendar_page.dart';
import 'package:doordesk/features/home/home_page.dart';
import 'package:doordesk/features/hours/hours_page.dart';
import 'package:doordesk/features/orders/orders_page.dart';
import 'package:doordesk/features/profile/profile_page.dart';
import 'package:doordesk/features/shell/shell_navigation_items.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  int _activeRailTab = 0;
  int _ordersSubIndex = 0;
  int _customersSubIndex = 0;

  static const int _settingsTab = 5;

  Future<void> _logout() async {
    final auth = ref.read(authServiceProvider);
    await auth?.signOut();
  }

  void _showNotificationsStub() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Noch keine Benachrichtigungen.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _setShellIndex(int value) {
    setState(() {
      _index = value;
      if (value >= 0 && value <= 4) {
        _activeRailTab = value;
      }
    });
  }

  void _onRailSelect(int railIndex) {
    final target = shellRailTargetFromIndex(railIndex);
    setState(() {
      if (target.tabIndex == 1) {
        _ordersSubIndex = target.subIndex;
      } else if (target.tabIndex == 2) {
        _customersSubIndex = target.subIndex;
      }
      _index = target.tabIndex;
      _activeRailTab = target.tabIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(doorDeskSessionProvider).value;
    if (user == null) {
      return const SizedBox.shrink();
    }

    void logout() {
      _logout();
    }

    final selectedRailIndex = shellRailSelectedIndex(
      activeTabIndex: _index == _settingsTab ? _activeRailTab : _index,
      ordersSubIndex: _ordersSubIndex,
      customersSubIndex: _customersSubIndex,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: DashboardTheme.backgroundGradient,
              ),
              child: IndexedStack(
                index: _index,
                children: [
                  HomePage(
                    onLogout: logout,
                    selectedRailIndex: selectedRailIndex,
                    onRailSelect: _onRailSelect,
                  ),
                  OrdersPage(
                    onLogout: logout,
                    selectedRailIndex: selectedRailIndex,
                    openCustomersSection: false,
                    initialSubIndex: _ordersSubIndex,
                    onShellSelect: _setShellIndex,
                    onRailSelect: _onRailSelect,
                  ),
                  OrdersPage(
                    onLogout: logout,
                    selectedRailIndex: selectedRailIndex,
                    openCustomersSection: true,
                    initialSubIndex: _customersSubIndex,
                    onShellSelect: _setShellIndex,
                    onRailSelect: _onRailSelect,
                  ),
                  CalendarPage(
                    onLogout: logout,
                    selectedRailIndex: selectedRailIndex,
                    onRailSelect: _onRailSelect,
                  ),
                  HoursPage(
                    onLogout: logout,
                    selectedRailIndex: selectedRailIndex,
                    onRailSelect: _onRailSelect,
                  ),
                  ProfilePage(
                    user: user,
                    onLogout: logout,
                    selectedShellIndex: _index,
                    onShellSelect: _setShellIndex,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: ShellSearchLayout.searchRowTop(context),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final railW = DashboardLayout.railWidth(constraints.maxWidth);
                return Padding(
                  padding: EdgeInsets.only(left: railW + 16, right: 16),
                  child: _ShellAppBar(
                    onNotificationsTap: _showNotificationsStub,
                    userDisplayName: user.displayName,
                    onAvatarOpenProfile: () => _setShellIndex(_settingsTab),
                    onAvatarLogout: logout,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Kopfleiste für [MainShell]: nur Notifications-Icon und Account-Avatar
/// am rechten Rand. Tab- und Seitentitel werden innerhalb der jeweiligen
/// Seite gerendert; primäre „+"-Aktionen sitzen neben der Seitenüberschrift,
/// nicht hier.
class _ShellAppBar extends StatelessWidget {
  const _ShellAppBar({
    required this.onNotificationsTap,
    required this.userDisplayName,
    required this.onAvatarOpenProfile,
    required this.onAvatarLogout,
  });

  final VoidCallback onNotificationsTap;
  final String userDisplayName;
  final VoidCallback onAvatarOpenProfile;
  final VoidCallback onAvatarLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ShellSearchLayout.searchBarVisualHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          _ShellBarIcon(
            tooltip: 'Benachrichtigungen',
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 8),
          _ShellAvatarButton(
            displayName: userDisplayName,
            onOpenProfile: onAvatarOpenProfile,
            onLogout: onAvatarLogout,
          ),
        ],
      ),
    );
  }
}

/// Einheitlich gestaltetes Icon-Button-Pill für die Kopfleiste —
/// Glass-Hintergrund, z. B. für Benachrichtigungen.
class _ShellBarIcon extends StatelessWidget {
  const _ShellBarIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: DashboardTheme.glassFill,
            child: InkWell(
              onTap: enabled ? onTap : null,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DashboardTheme.glassBorder),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runder Avatar-Button mit den Initialen des angemeldeten Nutzers.
/// Klick öffnet ein kleines Popup-Menü mit „Profil öffnen" und „Abmelden".
class _ShellAvatarButton extends StatelessWidget {
  const _ShellAvatarButton({
    required this.displayName,
    required this.onOpenProfile,
    required this.onLogout,
  });

  final String displayName;
  final VoidCallback onOpenProfile;
  final VoidCallback onLogout;

  /// Ermittelt bis zu zwei Initialen (erster + letzter Namens­bestand).
  /// Fällt auf das erste Zeichen bzw. „?" zurück, wenn nichts Sinnvolles
  /// aus [displayName] herauszulesen ist.
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.characters.first.toUpperCase();
    }
    final first = parts.first.characters.first;
    final last = parts.last.characters.first;
    return '${first.toUpperCase()}${last.toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letters = _initials(displayName);
    return Tooltip(
      message: displayName.isEmpty ? 'Konto' : displayName,
      waitDuration: const Duration(milliseconds: 400),
      child: PopupMenuButton<_AvatarAction>(
        tooltip: '',
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        onSelected: (action) {
          switch (action) {
            case _AvatarAction.profile:
              onOpenProfile();
              break;
            case _AvatarAction.logout:
              onLogout();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _AvatarAction.profile,
            child: Row(
              children: const [
                Icon(Icons.person_outline_rounded, size: 20),
                SizedBox(width: 10),
                Text('Profil öffnen'),
              ],
            ),
          ),
          PopupMenuItem(
            value: _AvatarAction.logout,
            child: Row(
              children: const [
                Icon(Icons.logout_rounded, size: 20),
                SizedBox(width: 10),
                Text('Abmelden'),
              ],
            ),
          ),
        ],
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.75),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Text(
            letters,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

enum _AvatarAction { profile, logout }
