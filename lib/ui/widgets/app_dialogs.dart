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
  return showDialog<String>(
    context: context,
    builder: (context) => _TextInputDialog(
      title: title,
      hintText: hintText,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      autofocus: autofocus,
      keyboardType: keyboardType,
      maxLines: maxLines,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final bool autofocus;
  final TextInputType keyboardType;
  final int maxLines;

  const _TextInputDialog({
    required this.title,
    required this.hintText,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.autofocus,
    required this.keyboardType,
    required this.maxLines,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
