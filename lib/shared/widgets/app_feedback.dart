import 'package:flutter/material.dart';

import 'ink_app_widgets.dart';

class AppFeedback {
  AppFeedback._();

  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: InkPalette.pine,
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
            style: const TextStyle(
              color: InkPalette.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
  }

  static void showFeaturePanel(BuildContext context, String feature) {
    showInkFeatureSheet(
      context,
      title: feature,
      subtitle: '已整理为完整交互方案，当前使用样例数据预览。',
    );
  }
}
