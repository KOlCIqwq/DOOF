import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_item.dart';

class DeleteQuantity extends StatefulWidget {
  final FoodItem item;
  const DeleteQuantity({super.key, required this.item});

  @override
  State<DeleteQuantity> createState() => _DeleteQuantityDialogState();
}

class _DeleteQuantityDialogState extends State<DeleteQuantity> {
  late double _sliderValue;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _sliderValue = 1.0;
    _textController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double value) {
    final int intValue = value.round();
    setState(() {
      _sliderValue = intValue.toDouble();
      _textController.text = intValue.toString();
    });
  }

  void _onTextChanged(String value) {
    int intValue = int.tryParse(value) ?? 1;
    if (intValue > widget.item.quantity) intValue = widget.item.quantity;
    if (intValue < 1) intValue = 1;

    setState(() {
      _sliderValue = intValue.toDouble();
      if (_textController.text != intValue.toString()) {
        _textController.text = intValue.toString();
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete ${widget.item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select how many items to delete (Total: ${widget.item.quantity})',
          ),
          const SizedBox(height: 24),
          Slider(
            value: _sliderValue,
            min: 1,
            max: widget.item.quantity.toDouble(),
            divisions: (widget.item.quantity - 1).clamp(1, 100),
            label: _sliderValue.round().toString(),
            onChanged: _onSliderChanged,
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _textController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _onTextChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _sliderValue.round()),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
