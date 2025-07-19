import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/quantity_parser.dart';

class AdjustPackageSizeDialog extends StatefulWidget {
  final String initialValue;
  const AdjustPackageSizeDialog({super.key, required this.initialValue});

  @override
  State<AdjustPackageSizeDialog> createState() =>
      _AdjustPackageSizeDialogState();
}

class _AdjustPackageSizeDialogState extends State<AdjustPackageSizeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  String _selectedUnit = 'g';
  final List<String> _units = ['g', 'kg', 'ml', 'L', 'oz', 'lb'];

  @override
  void initState() {
    super.initState();
    final (value, unit) = QuantityParser.parse(widget.initialValue);
    _valueController = TextEditingController(
      text: value > 0 ? value.toString() : '',
    );
    if (_units.contains(unit)) {
      _selectedUnit = unit;
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final value = _valueController.text;
      final newSize = '$value $_selectedUnit';
      Navigator.pop(context, newSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Package Size'),
      content: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _valueController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      double.tryParse(value) == null) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedUnit,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedUnit = newValue;
                    });
                  }
                },
                items: _units.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _onSave, child: const Text('Save')),
      ],
    );
  }
}
