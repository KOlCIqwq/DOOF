import 'package:flutter/material.dart';
import '../services/bmi_recommended_intake.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  /*
    This is a simplified profile page, it should be connected to supabase to save these details 
  */
  double? currentWeight;
  double? currentHeight;
  double? currentAge;

  double? currentBmi;
  String? currentCategory;
  ActivityLevel currentActivity = ActivityLevel.noWorkout;
  double? maintenanceCalories;

  void updateStats() {
    if (currentWeight != null && currentHeight != null && currentAge != null) {
      final bmi = BmiRecommendedIntake.calculateBmi(
        currentWeight!,
        currentHeight!,
      );
      final category = BmiRecommendedIntake.getBmiCategory(bmi);
      final calories = BmiRecommendedIntake.calculateMaintenanceCalories(
        weight: currentWeight!,
        heightCm: currentHeight!,
        age: currentAge!,
        activityLevel: currentActivity,
      );

      setState(() {
        currentBmi = bmi;
        currentCategory = category;
        maintenanceCalories = calories;
      });
    }
  }

  // Generic dialog function for numerical input
  void showAdjustInputDialog({
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
                  onSaved(newValue);
                  updateStats();
                  Navigator.of(context).pop();
                } else {
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
    showAdjustInputDialog(
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
    showAdjustInputDialog(
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

  void adjustAge() {
    showAdjustInputDialog(
      title: "Adjust Age",
      labelText: "Age (years)",
      initialValue: currentAge,
      onSaved: (newValue) {
        setState(() {
          currentAge = newValue;
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

          const SizedBox(height: 24),
          // Age Row
          InkWell(
            onTap: adjustAge,
            child: Row(
              children: [
                const Text("Age", style: TextStyle(fontSize: 16)),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      currentAge != null
                          ? currentAge!.toStringAsFixed(1)
                          : "____",
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "years",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          ToggleButtons(
            borderRadius: BorderRadius.circular(12),
            isSelected: [
              currentActivity == ActivityLevel.noWorkout,
              currentActivity == ActivityLevel.lightWorkout,
              currentActivity == ActivityLevel.heavyWorkout,
            ],
            onPressed: (index) {
              setState(() {
                currentActivity = ActivityLevel.values[index];
              });
              updateStats();
            },
            children: const [
              Text("Workout Level: "),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("None"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("Light"),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text("Heavy"),
              ),
            ],
          ),

          Text(
            currentBmi != null && currentCategory != null
                ? "BMI: ${currentBmi!.toStringAsFixed(1)} ($currentCategory)"
                : "BMI: ____",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            maintenanceCalories != null
                ? "Maintenance Calories: ${maintenanceCalories!.toStringAsFixed(0)} kcal"
                : "Maintenance Calories: ____",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
