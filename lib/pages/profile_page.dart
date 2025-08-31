import 'package:flutter/material.dart';
import '../services/bmi_recommended_intake.dart';
import '../utils/recommended_intake_helper.dart';
import '../models/profile_model.dart';
import '../auth/auth_service.dart';

class ProfilePage extends StatefulWidget {
  final ProfileModel? profile;
  final ValueChanged<ProfileModel> onProfileChanged;

  const ProfilePage({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  double? currentWeight;
  double? currentHeight;
  double? currentAge;
  Gender currentGender = Gender.male;
  ActivityLevel currentActivity = ActivityLevel.noWorkout;
  ActivityPhase currentPhase = ActivityPhase.keep;

  double? currentBmi;
  String? currentCategory;
  double? maintenanceCalories;

  final authService = AuthService();

  void logout() async {
    await authService.signOut();
  }

  @override
  void initState() {
    super.initState();
    loadProfileFromWidget();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      loadProfileFromWidget();
    }
  }

  void loadProfileFromWidget() {
    if (widget.profile != null) {
      setState(() {
        currentWeight = widget.profile!.weight;
        currentHeight = widget.profile!.height;
        currentAge = widget.profile!.age;
        currentGender = widget.profile!.gender;
        currentActivity = widget.profile!.activity;
        currentPhase = widget.profile!.phase;
      });
    }
    calculateDisplayStats();
  }

  void handleUpdate() {
    if (currentWeight != null && currentHeight != null && currentAge != null) {
      final updatedProfile = ProfileModel(
        weight: currentWeight!,
        height: currentHeight!,
        age: currentAge!,
        gender: currentGender,
        activity: currentActivity,
        phase: currentPhase,
      );
      widget.onProfileChanged(updatedProfile); // Signal the changes to mainPage
      calculateDisplayStats();
    }
  }

  void calculateDisplayStats() {
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
        gender: currentGender,
        activityLevel: currentActivity,
      );

      setState(() {
        currentBmi = bmi;
        currentCategory = category;
        maintenanceCalories = calories;
      });

      RecommendedIntakeHelper.update(
        weight: currentWeight!,
        heightCm: currentHeight!,
        age: currentAge!,
        gender: currentGender,
        activityLevel: currentActivity,
        activityPhase: currentPhase,
      );
    }
  }

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

  void adjustWeight() {
    showAdjustInputDialog(
      title: "Adjust Weight",
      labelText: "Weight (kg)",
      initialValue: currentWeight,
      onSaved: (newValue) {
        setState(() {
          currentWeight = newValue;
        });
        handleUpdate();
      },
    );
  }

  void adjustHeight() {
    showAdjustInputDialog(
      title: "Adjust Height",
      labelText: "Height (cm)",
      initialValue: currentHeight,
      onSaved: (newValue) {
        setState(() {
          currentHeight = newValue;
        });
        handleUpdate();
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
        handleUpdate();
      },
    );
  }

  Widget buildBody() {
    final currentEmail = authService.getCurrentEmail() ?? "No Email";
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Current User: $currentEmail"),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
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
            Row(
              children: [
                const Text("Gender", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(12),
                    isSelected: [
                      currentGender == Gender.male,
                      currentGender == Gender.female,
                      currentGender == Gender.other,
                    ],
                    onPressed: (index) {
                      setState(() {
                        currentGender = Gender.values[index];
                      });
                      handleUpdate();
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Male"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Female"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Other"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                            ? currentAge!.toStringAsFixed(0)
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
            const SizedBox(height: 24),
            Row(
              children: [
                const Text("Activity", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: ToggleButtons(
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
                      handleUpdate();
                    },
                    children: const [
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
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text("Phase", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(12),
                    isSelected: [
                      currentPhase == ActivityPhase.keep,
                      currentPhase == ActivityPhase.bulk,
                      currentPhase == ActivityPhase.cut,
                    ],
                    onPressed: (index) {
                      setState(() {
                        currentPhase = ActivityPhase.values[index];
                      });
                      handleUpdate();
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Keep"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Bulk"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Cut"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              currentBmi != null && currentCategory != null
                  ? "BMI: ${currentBmi!.toStringAsFixed(1)} ($currentCategory)"
                  : "BMI: ____",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              maintenanceCalories != null
                  ? "Maintenance Calories: ${maintenanceCalories!.toStringAsFixed(0)} kcal"
                  : "Maintenance Calories: ____",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: buildBody(),
    );
  }
}
