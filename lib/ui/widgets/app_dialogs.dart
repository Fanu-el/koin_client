import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? AppColors.error : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).then((value) => value == true);
}

Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String hintText = '',
  String initialValue = '',
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
  bool autofocus = true,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
}) {
  final controller = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).then((value) {
    controller.dispose();
    return value;
  });
}
