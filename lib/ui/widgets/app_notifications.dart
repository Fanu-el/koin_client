import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

void showErrorSnackBar(BuildContext context, String message) {
  showAppSnackBar(
    context,
    message,
    backgroundColor: AppColors.error,
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  showAppSnackBar(
    context,
    message,
    backgroundColor: AppColors.success,
  );
}
