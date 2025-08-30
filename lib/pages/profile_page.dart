import 'package:flutter/material.dart';
import '../services/bmi_recommended_intake.dart';
import '../utils/recommended_intake_helper.dart';
import '../models/profile_model.dart';
import '../auth/auth_service.dart';
import '../services/user_service.dart';

enum Gender { male, female, other }

enum ActivityPhase { keep, bulk, cut }

class ProfilePage extends StatefulWidget {
  final ProfileModel? profile;
  const ProfilePage({super.key, this.profile});
  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  /*
    TODO: This is a simplified profile page, it should be connected to supabase to save these details 
  */
  late ProfileModel? profile;

  double? currentWeight;
  double? currentHeight;
  double? currentAge;

  double? currentBmi;
  String? currentCategory;
  ActivityLevel currentActivity = ActivityLevel.noWorkout;
  Gender currentGender = Gender.male;
  ActivityPhase currentPhase = ActivityPhase.keep;
  double? maintenanceCalories;

  final authService = AuthService();

  void logout() async {
    await authService.signOut();
  }

  @override
  void initState() {
    super.initState();
    profile = widget.profile;
    loadProfile(); // Consider loading when loaded the main page, not only here
  }
  // We don't load the profile from the storage, rather from server
  /* Future<void> loadProfile() async {
    final saved = await ProfileStorage.loadProfile();
    if (saved != null) {
      setState(() {
        currentWeight = saved.weight;
        currentHeight = saved.height;
        currentAge = saved.age;
        currentActivity = saved.activity;
      });
    }
    updateStats(); // Update stats after loading
  } */

  void loadProfile() {
    if (profile != null) {
      currentWeight = profile!.weight;
      currentHeight = profile!.height;
      currentAge = profile!.age;
      currentGender = profile!.gender;
      currentActivity = profile!.activity;
      currentPhase = profile!.phase;

      updateStats();
    }
  }

  void saveProfile() async {
    if (currentWeight != null && currentHeight != null && currentAge != null) {
      final updatedProfile = ProfileModel(
        weight: currentWeight!,
        height: currentHeight!,
        age: currentAge!,
        gender: currentGender,
        activity: currentActivity,
        phase: currentPhase,
      );

      setState(() {
        profile = updatedProfile;
      });

      // Persist to Supabase
      final user = authService.getCurrentUser();
      if (user != null) {
        await UserService().updateProfile(
          userId: user.id,
          weight: currentWeight,
          height: currentHeight,
          age: currentAge?.toInt(),
          gender: currentGender.index,
          activity: currentActivity.index,
          phase: currentPhase.index,
        );
      }
    }
  }

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
      RecommendedIntakeHelper.update(
        // Also update recommended intake
        weight: currentWeight!,
        heightCm: currentHeight!,
        age: currentAge!,
        activityLevel: currentActivity,
      );
      saveProfile(); // Save profile after updating stats
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
    final currentEmail = authService.getCurrentEmail() ?? "No Email";
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text("Current User: $currentEmail"),
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
          Row(
            children: [
              const Text("Activity", style: TextStyle(fontSize: 16)),
              const SizedBox(width: 16), // spacing between label and buttons
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
                    updateStats();
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
