enum ActivityLevel { noWorkout, lightWorkout, heavyWorkout }

enum Gender { male, female, other }

enum ActivityPhase { keep, bulk, cut }

/// Display label for activity levels
class BmiRecommendedIntake {
  static String activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.noWorkout:
        return "No Workout";
      case ActivityLevel.lightWorkout:
        return "A bit of Workout";
      case ActivityLevel.heavyWorkout:
        return "Heavy Workout";
    }
  }

  /// TDEE activity multipliers
  static double activityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.noWorkout:
        return 1.2;
      case ActivityLevel.lightWorkout:
        return 1.375;
      case ActivityLevel.heavyWorkout:
        return 1.725;
    }
  }

  /// BMI calculation
  static double calculateBmi(double weight, double heightCm) {
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  /// BMI category
  static String getBmiCategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal weight";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  /// BMR with gender consideration (Mifflin-St Jeor)
  static double calculateBmr({
    required double weight,
    required double heightCm,
    required double age,
    required Gender gender,
  }) {
    final base = 10 * weight + 6.25 * heightCm - 5 * age;
    switch (gender) {
      case Gender.male:
        return base + 5;
      case Gender.female:
        return base - 161;
      case Gender.other:
        return base - 78; // midpoint adjustment
    }
  }

  /// Maintenance calories (TDEE)
  static double calculateMaintenanceCalories({
    required double weight,
    required double heightCm,
    required double age,
    required Gender gender,
    required ActivityLevel activityLevel,
  }) {
    final bmr = calculateBmr(
      weight: weight,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    return bmr * activityMultiplier(activityLevel);
  }

  /// Adjust calories based on phase
  static double adjustCaloriesForPhase(
    double maintenanceCalories,
    ActivityPhase phase,
  ) {
    switch (phase) {
      case ActivityPhase.keep:
        return maintenanceCalories;
      case ActivityPhase.bulk:
        return maintenanceCalories * 1.15; // +15%
      case ActivityPhase.cut:
        return maintenanceCalories * 0.80; // -20%
    }
  }

  /// Macro breakdown (20% protein, 30% fat, 50% carbs)
  static Map<String, double> calculateMacros(double calories) {
    final proteinCals = calories * 0.20;
    final fatCals = calories * 0.30;
    final carbCals = calories * 0.50;

    return {
      "protein_g": proteinCals / 4,
      "fat_g": fatCals / 9,
      "carbs_g": carbCals / 4,
    };
  }

  /// Full calculation: BMI, category, calories, macros
  static Map<String, dynamic> calculateAll({
    required double weight,
    required double heightCm,
    required double age,
    required Gender gender,
    required ActivityLevel activityLevel,
    required ActivityPhase phase,
  }) {
    final bmi = calculateBmi(weight, heightCm);
    final category = getBmiCategory(bmi);

    final maintenance = calculateMaintenanceCalories(
      weight: weight,
      heightCm: heightCm,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
    );

    final targetCalories = adjustCaloriesForPhase(maintenance, phase);
    final macros = calculateMacros(targetCalories);

    return {
      "bmi": bmi,
      "bmi_category": category,
      "maintenance_calories": maintenance,
      "target_calories": targetCalories,
      "macros": macros,
    };
  }
}
