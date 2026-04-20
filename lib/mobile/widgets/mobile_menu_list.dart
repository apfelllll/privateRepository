import 'package:doordesk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Sektionierte Menue-Liste fuer Drill-Down-Tabs.
///
/// Optik: iOS/Settings-Stil — kleine Sektionsueberschrift, gruppierte Kacheln,
/// klare Trennlinien, grosse Tap-Flaechen (56 dp).
class MobileMenuList extends StatelessWidget {
  const MobileMenuList({
    super.key,
    required this.sections,
    this.leadingPadding = 8,
  });

  final List<MobileMenuSection> sections;
  final double leadingPadding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, leadingPadding, 16, 24),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 24),
          child: _MobileMenuSectionView(section: section),
        );
      },
    );
  }
}

class MobileMenuSection {
  const MobileMenuSection({required this.heading, required this.items});

  final String heading;
  final List<MobileMenuItem> items;
}

class MobileMenuItem {
  const MobileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.trailingCount,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final int? trailingCount;
  final VoidCallback onTap;
}

class _MobileMenuSectionView extends StatelessWidget {
  const _MobileMenuSectionView({required this.section});

  final MobileMenuSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            section.heading.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < section.items.length; i++) ...[
                _MobileMenuTile(
                  item: section.items[i],
                  isFirst: i == 0,
                  isLast: i == section.items.length - 1,
                ),
                if (i < section.items.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 56),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileMenuTile extends StatelessWidget {
  const _MobileMenuTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final MobileMenuItem item;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(16) : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              if (item.trailingCount != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.trailingCount}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
