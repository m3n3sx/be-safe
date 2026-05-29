/// iOS-style InsetGroupedSection — Apple Settings/Preferences look.
///
/// Renders a list of rows inside a single white rounded card with
/// hairline separators inset to the right of the leading icon (16dp + icon
/// width + 12dp). The whole card sits on `groupedBackground` (#F2F2F7) with
/// 16dp horizontal insets.
///
/// Usage:
///   InsetGroupedSection(
///     header: 'Konto',
///     footer: 'Twoje dane personalne i preferencje.',
///     children: [
///       InsetGroupedRow(icon: Icons.person, title: 'Nazwa', value: 'Jan', onTap: ...),
///       InsetGroupedRow(icon: Icons.email, title: 'Email', value: 'jan@x.pl'),
///     ],
///   )
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/ios_surfaces.dart';
import 'pressable_scale.dart';

/// A grouped, inset section like iOS Settings.
class InsetGroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsets margin;

  const InsetGroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
              child: Text(
                header!.toUpperCase(),
                style: SerenityText.iosSectionHeader.copyWith(
                  color: context.iosSecondaryLabel,
                ),
              ),
            ),
          ],
          ClipRRect(
            borderRadius: SerenityShapes.iosGroupedCard(),
            child: Container(
              decoration: BoxDecoration(
                color: context.iosCardSurface,
                borderRadius: SerenityShapes.iosGroupedCard(),
              ),
              child: Column(
                children: _withSeparators(children),
              ),
            ),
          ),
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                footer!,
                style: SerenityText.iosFootnote.copyWith(
                  color: context.iosSecondaryLabel,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _withSeparators(List<Widget> rows) {
    if (rows.isEmpty) return rows;
    final out = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      out.add(rows[i]);
      if (i < rows.length - 1) {
        out.add(const _InsetSeparator());
      }
    }
    return out;
  }
}

class _InsetSeparator extends StatelessWidget {
  const _InsetSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 0.5,
        thickness: 0.5,
        color: context.iosSeparator,
      ),
    );
  }
}

/// Single tappable row inside InsetGroupedSection — iOS style.
class InsetGroupedRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const InsetGroupedRow({
    super.key,
    this.icon,
    this.iconColor,
    this.leading,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        destructive ? SerenityColors.glowAlertCoral : context.iosLabel;
    final iconBgColor =
        iconColor ?? (destructive ? SerenityColors.glowAlertCoral : SerenityColors.primaryContainer);

    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: context.iosSeparator.withValues(alpha: 0.5),
        highlightColor: context.iosSeparator.withValues(alpha: 0.2),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ] else if (icon != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SerenityText.iosBody.copyWith(color: titleColor),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: SerenityText.iosSubhead.copyWith(
                            color: context.iosSecondaryLabel,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Text(
                    value!,
                    style: SerenityText.iosSubhead.copyWith(
                      color: context.iosSecondaryLabel,
                    ),
                  ),
                ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: context.iosSecondaryLabel,
                ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return row;
    return PressableScale(
      scaleOnly: true,
      pressedScale: 0.985,
      child: row,
    );
  }
}
