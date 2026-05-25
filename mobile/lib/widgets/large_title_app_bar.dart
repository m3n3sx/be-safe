/// iOS-style LargeTitleSliverAppBar.
///
/// Collapses from 34px bold "Large Title" → 17px centered title on scroll.
/// Background matches `groupedBackground` so the title appears to float
/// above the grouped sections.
///
/// Usage:
///   CustomScrollView(slivers: [
///     LargeTitleSliverAppBar(title: 'Profil'),
///     SliverToBoxAdapter(child: InsetGroupedSection(...)),
///   ])
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class LargeTitleSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const LargeTitleSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: false,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions,
      backgroundColor: SerenityColors.groupedBackground,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      foregroundColor: SerenityColors.primary,
      expandedHeight: 96,
      titleSpacing: 16,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = MediaQuery.of(context).padding.top;
          final collapsed = kToolbarHeight + top;
          final progress =
              ((constraints.maxHeight - collapsed) / (96 + top - collapsed))
                  .clamp(0.0, 1.0);
          return FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
            title: Opacity(
              opacity: progress < 0.3 ? 1.0 : 0,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: SerenityColors.primary,
                ),
              ),
            ),
            background: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Opacity(
                    opacity: progress > 0.3 ? 1.0 : 0,
                    child: Text(title, style: SerenityText.largeTitle),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
