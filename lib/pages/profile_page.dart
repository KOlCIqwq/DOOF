import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  double? currentWeight;

  void adjustWeight() {
    final TextEditingController weightController = TextEditingController(
      text: currentWeight?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Adjust Weight"),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Weight (kg)"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newWeight = double.tryParse(weightController.text);
                if (newWeight != null && newWeight > 0) {
                  setState(() {
                    currentWeight = newWeight;
                  });
                  Navigator.of(context).pop();
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

  Widget buildFriendlyMessage(IconData icon, Color color, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildFriendlyMessage(Icons.warning, Colors.grey, "Under Construction"),
        const SizedBox(height: 20),
        // Weight input row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Weight:"),
            GestureDetector(
              onTap: adjustWeight, // Function call on adjust weight
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                child: Text(
                  currentWeight != null
                      ? currentWeight!.toStringAsFixed(1)
                      : "____",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Text("kg"),
          ],
        ),
      ],
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
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16.0)),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }
}
