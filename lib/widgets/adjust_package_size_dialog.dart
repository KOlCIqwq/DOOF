// lib/widgets/adjust_package_size_dialog.dart

import 'package:flutter/material.dart';

class AdjustPackageSizeDialog extends StatefulWidget {
  final String initialValue;
  const AdjustPackageSizeDialog({super.key, required this.initialValue});

  @override
  State<AdjustPackageSizeDialog> createState() =>
      _AdjustPackageSizeDialogState();
}

class _AdjustPackageSizeDialogState extends State<AdjustPackageSizeDialog> {
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
      title: const Text('Adjust Package Size'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Size (e.g., "500 g", "1.5 L")',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
