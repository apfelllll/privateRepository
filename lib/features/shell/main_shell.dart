import 'dart:ui';

import 'package:doordesk/core/theme/app_theme.dart';
import 'package:doordesk/core/theme/dashboard_theme.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/core/widgets/shell_top_search_bar.dart';
import 'package:doordesk/features/calendar/calendar_page.dart';
import 'package:doordesk/features/home/home_page.dart';
import 'package:doordesk/features/hours/hours_page.dart';
import 'package:doordesk/features/orders/orders_page.dart';
import 'package:doordesk/features/profile/profile_page.dart';
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
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final auth = ref.read(authServiceProvider);
    await auth?.signOut();
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

    final hideSearchForOrderDetail =
        _index == 1 && ref.watch(hideShellTopSearchBarProvider);
    final showOrdersFilterInShell =
        _index == 1 && ref.watch(showShellOrdersFilterButtonProvider);
    final ordersFilterActive = ref.watch(ordersListFilterActiveProvider);
    final onOrdersFilterTap = ref.watch(orderFilterShellOpenProvider);

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
                  HomePage(onLogout: logout),
                  OrdersPage(onLogout: logout),
                  CalendarPage(onLogout: logout),
                  HoursPage(onLogout: logout),
                  ProfilePage(user: user, onLogout: logout),
                ],
              ),
            ),
          ),
          if (!hideSearchForOrderDetail)
            Positioned(
              left: 16,
              right: 16,
              top: ShellSearchLayout.searchRowTop(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ShellTopSearchBar(controller: _searchController),
                    ),
                  ),
                  if (showOrdersFilterInShell) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: 'Filtern',
                      waitDuration: const Duration(milliseconds: 400),
                      child: IconButton(
                        onPressed: onOrdersFilterTap,
                        icon: Badge(
                          isLabelVisible: ordersFilterActive,
                          smallSize: 6,
                          child: const Icon(
                            Icons.filter_list_rounded,
                            size: 22,
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: _CompactGlassTabBar(
        selectedIndex: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Zentrierte, niedrige Glas-Leiste — Icons dicht beieinander, kein Vollpfeil über die Breite.
class _CompactGlassTabBar extends StatelessWidget {
  const _CompactGlassTabBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _tooltips = [
    'Start',
    'Aufträge und Kunden',
    'Kalender',
    'Arbeitszeiten',
    'Einstellungen',
  ];

  static const _iconsOutlined = [
    Icons.home_outlined,
    Icons.corporate_fare_outlined,
    Icons.calendar_month_outlined,
    Icons.schedule_outlined,
    Icons.settings_outlined,
  ];

  static const _iconsFilled = [
    Icons.home_rounded,
    Icons.corporate_fare,
    Icons.calendar_month,
    Icons.schedule,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.hardEdge,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.white.withValues(alpha: 0.6),
                shadowColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final selected = i == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _CompactNavItem(
                          selected: selected,
                          tooltip: _tooltips[i],
                          icon: selected ? _iconsFilled[i] : _iconsOutlined[i],
                          onTap: () => onSelect(i),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavItem extends StatelessWidget {
  const _CompactNavItem({
    required this.selected,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // InkWell setzt auf manchen Desktops einen eigenen Cursor und kann MouseRegion
    // „überschreiben“ — GestureDetector + MouseRegion zuverlässiger für die Hand.
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 25,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
