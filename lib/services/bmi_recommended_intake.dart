enum ActivityLevel { noWorkout, lightWorkout, heavyWorkout }

class BmiRecommendedIntake {
  /// Returns the display label for each activity level
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

  /// Activity multipliers (TDEE factors)
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

  static double calculateBmi(double weight, double heightCm) {
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  static String getBmiCategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal weight";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  static double calculateBmr({
    required double weight,
    required double heightCm,
    required double age,
  }) {
    return 10 * weight + 6.25 * heightCm - 5 * age + 5; // Mifflin-St Jeor male
  }

  static double calculateMaintenanceCalories({
    required double weight,
    required double heightCm,
    required double age,
    required ActivityLevel activityLevel,
  }) {
    final bmr = calculateBmr(weight: weight, heightCm: heightCm, age: age);
    return bmr * activityMultiplier(activityLevel);
  }

  /// Macronutrient breakdown (example: 20% protein, 30% fat, 50% carbs)
  static Map<String, double> calculateMacros({required double calories}) {
    final proteinCals = calories * 0.20;
    final fatCals = calories * 0.30;
    final carbCals = calories * 0.50;

    return {
      "protein_g": proteinCals / 4, // 4 kcal per g
      "fat_g": fatCals / 9, // 9 kcal per g
      "carbs_g": carbCals / 4, // 4 kcal per g
    };
  }
}
