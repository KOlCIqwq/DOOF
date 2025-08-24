import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  double? currentWeight;
  double? currentHeight;

  // Generic dialog function for numerical input
  void _showAdjustInputDialog({
    required String title,
    required String labelText,
    double? initialValue,
    required ValueChanged<double> onSaved,
  }) {
    final TextEditingController controller = TextEditingController(
      text: initialValue?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: labelText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newValue = double.tryParse(controller.text);
                if (newValue != null && newValue > 0) {
                  onSaved(
                    newValue,
                  ); // Use the callback to update the specific state
                  Navigator.of(context).pop();
                } else {
                  // Optionally show an error message or shake the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter a valid positive number."),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // Wrapper for adjusting weight using the generic dialog
  void adjustWeight() {
    _showAdjustInputDialog(
      title: "Adjust Weight",
      labelText: "Weight (kg)",
      initialValue: currentWeight,
      onSaved: (newValue) {
        setState(() {
          currentWeight = newValue;
        });
      },
    );
  }

  // Wrapper for adjusting height using the generic dialog
  void adjustHeight() {
    _showAdjustInputDialog(
      title: "Adjust Height",
      labelText: "Height (cm)",
      initialValue: currentHeight,
      onSaved: (newValue) {
        setState(() {
          currentHeight = newValue;
        });
      },
    );
  }

  Widget buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Row for Weight
          // Wrapped with InkWell for tap detection
          InkWell(
            onTap: adjustWeight,
            child: Row(
              children: [
                const Text("Weight", style: TextStyle(fontSize: 16)),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      currentWeight != null
                          ? currentWeight!.toStringAsFixed(1)
                          : "____",
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "kg",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divide the row
          const SizedBox(height: 24),

          // Height Row
          InkWell(
            onTap: adjustHeight,
            child: Row(
              children: [
                const Text("Height", style: TextStyle(fontSize: 16)),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      currentHeight != null
                          ? currentHeight!.toStringAsFixed(1)
                          : "____",
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "cm",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: buildBody(),
    );
  }
}
