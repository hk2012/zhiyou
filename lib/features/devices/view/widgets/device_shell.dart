import 'package:flutter/material.dart';

import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/localization/app_localizations_x.dart';
import '../../../../shared/widgets/ink_app_widgets.dart';

enum DeviceResponsiveMode {
  phone,
  tablet,
  desktop;

  static DeviceResponsiveMode fromWidth(double width) {
    return switch (AppBreakpoint.fromWidth(width)) {
      AppBreakpoint.compact => DeviceResponsiveMode.phone,
      AppBreakpoint.medium => DeviceResponsiveMode.tablet,
      AppBreakpoint.expanded ||
      AppBreakpoint.wide => DeviceResponsiveMode.desktop,
    };
  }
}

class DevicePageShell extends StatelessWidget {
  const DevicePageShell({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.showBack = true,
    this.bottomPadding = 32,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final bool showBack;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InkPalette.rice,
      body: Stack(
        children: [
          const Positioned.fill(child: InkBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (title != null)
                  _DeviceAppBar(
                    title: title!,
                    actions: actions,
                    showBack: showBack,
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mode = DeviceResponsiveMode.fromWidth(
                        constraints.maxWidth,
                      );
                      final maxWidth = switch (mode) {
                        DeviceResponsiveMode.phone => 560.0,
                        DeviceResponsiveMode.tablet => 980.0,
                        DeviceResponsiveMode.desktop => 1280.0,
                      };
                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              mode == DeviceResponsiveMode.phone ? 14 : 22,
                              8,
                              mode == DeviceResponsiveMode.phone ? 14 : 22,
                              bottomPadding,
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceAppBar extends StatelessWidget {
  const _DeviceAppBar({
    required this.title,
    required this.actions,
    required this.showBack,
  });

  final String title;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const SizedBox(width: 8),
          if (showBack)
            IconButton(
              tooltip: context.l10n.actionBack,
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: InkPalette.text,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...actions,
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
