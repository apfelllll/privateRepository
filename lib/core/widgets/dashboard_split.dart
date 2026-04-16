import 'package:doordesk/core/layout/dashboard_layout.dart';
import 'package:flutter/material.dart';

/// Linke Rail + rechter Bereich über volle Höhe (über der Bottom-Navigation).
class DashboardSplit extends StatelessWidget {
  const DashboardSplit({
    super.key,
    required this.leftWidth,
    required this.left,
    required this.detail,
    this.detailTopPadding = 0,
  });

  final double leftWidth;
  final Widget left;
  final Widget detail;

  /// Zusätzlicher Abstand oben nur für die Detail-Spalte (z. B. globale Suchzeile).
  final double detailTopPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final railW = DashboardLayout.railWidth(w, leftWidth: leftWidth);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: railW, child: left),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: detailTopPadding),
                child: detail,
              ),
            ),
          ],
        );
      },
    );
  }
}
