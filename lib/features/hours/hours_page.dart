import 'package:doordesk/core/widgets/dashboard_detail_chrome.dart';
import 'package:doordesk/core/widgets/dashboard_left_rail.dart';
import 'package:doordesk/core/widgets/dashboard_split.dart';
import 'package:doordesk/core/widgets/shell_search_layout.dart';
import 'package:doordesk/core/widgets/dashboard_white_card.dart';
import 'package:doordesk/features/hours/new_time_entry_dialog.dart';
import 'package:doordesk/providers/door_desk_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Breite der Arbeitszeiten-Kachel: Anteil des verfügbaren Platzes, mit Min/Max.
const double _kHoursTileWidthFactor = 0.52;
const double _kHoursTileMinWidth = 300;
const double _kHoursTileMaxWidth = 540;

class HoursPage extends ConsumerStatefulWidget {
  const HoursPage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  ConsumerState<HoursPage> createState() => _HoursPageState();
}

class _HoursPageState extends ConsumerState<HoursPage> {
  /// Weiße Kachel (4:3), Breite kommt vom umgebenden [SizedBox].
  Widget _emptyWhiteTile() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DashboardWhiteCard(
        padding: EdgeInsets.zero,
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(doorDeskSessionProvider).value;
    if (user == null) return const SizedBox.shrink();

    const railItems = [
      DashboardRailItem(
        icon: Icons.schedule_rounded,
        label: 'Arbeitszeiten',
      ),
    ];

    return DashboardSplit(
      leftWidth: 272,
      detailTopPadding: ShellSearchLayout.detailColumnTopPadding(context),
      left: DashboardLeftRail(
        sections: [DashboardRailSection(items: railItems)],
        selectedIndex: 0,
        onSelect: (_) {},
        onLogout: widget.onLogout,
        footerHint: 'Hauptkachel · Arbeitszeiten',
      ),
      detail: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardDetailChrome(
              greeting: 'Arbeitszeiten',
              showTopBar: false,
              titleTrailingSpacing: 16,
              titleTrailing: Tooltip(
                message: 'Neue Arbeitszeiterfassung',
                child: FilledButton(
                  onPressed: () => showNewTimeEntryDialog(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(10),
                    minimumSize: const Size(40, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.add_rounded, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final w = (constraints.maxWidth * _kHoursTileWidthFactor)
                    .clamp(_kHoursTileMinWidth, _kHoursTileMaxWidth)
                    .clamp(0.0, constraints.maxWidth);
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: w,
                    child: _emptyWhiteTile(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
