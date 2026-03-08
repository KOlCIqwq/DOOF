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
    double maintenance,
    ActivityPhase phase,
  ) {
    switch (phase) {
      case ActivityPhase.keep:
        return maintenance;
      case ActivityPhase.bulk:
        return maintenance * 1.15; // +15% for bulk
      case ActivityPhase.cut:
        return maintenance * 0.80; // –20% for cut
    }
  }

  /// Macro breakdown (20% protein, 30% fat, 50% carbs)
  static Map<String, double> calculateMacros({
    required double calories,
    required double weight,
    required ActivityLevel activityLevel,
    required ActivityPhase phase,
  }) {
    double proteinPerKg;
    if (phase == ActivityPhase.cut) {
      // Preserve muscle on a cut
      proteinPerKg = activityLevel == ActivityLevel.heavyWorkout ? 2.2 : 2.0;
    } else if (phase == ActivityPhase.bulk) {
      // Less protein needed to spare muscle in a surplus
      proteinPerKg = activityLevel == ActivityLevel.heavyWorkout ? 1.8 : 1.6;
    } else {
      // Maintenance
      proteinPerKg = activityLevel == ActivityLevel.heavyWorkout ? 2.0 : 1.6;
    }

    // Minimum protein for non-active individuals
    if (activityLevel == ActivityLevel.noWorkout) {
      proteinPerKg = 1.2;
    }

    final proteinGrams = weight * proteinPerKg;
    final proteinCalories = proteinGrams * 4;

    // Calculate Fat
    double fatPercentage = 0.25; // 25% baseline
    if (phase == ActivityPhase.cut) fatPercentage = 0.20;
    if (phase == ActivityPhase.bulk) fatPercentage = 0.30;

    final fatCalories = calories * fatPercentage;
    final fatGrams = fatCalories / 9;

    // Fill the remaining calories with Carbohydrates
    double remainingCalories = calories - proteinCalories - fatCalories;
    // Fallback to prevent negative carbs on extreme, unhealthy low-calorie diets
    if (remainingCalories < 0) remainingCalories = 0;

    final carbGrams = remainingCalories / 4;

    return {"protein_g": proteinGrams, "carbs_g": carbGrams, "fat_g": fatGrams};
  }

  /// Full calculation: BMI, category, calories, macros
  /// Full calculation including macro phase logic
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
    final macros = calculateMacros(
      calories: targetCalories,
      weight: weight,
      activityLevel: activityLevel,
      phase: phase,
    );

    return {
      "bmi": bmi,
      "bmi_category": category,
      "maintenance_calories": maintenance,
      "target_calories": targetCalories,
      "macros": macros,
    };
  }

  static Map<String, double> macroPercents({
    required ActivityLevel activityLevel,
    required ActivityPhase phase,
  }) {
    // Base macro percentages by activity level
    double proteinPct, carbPct, fatPct;
    switch (activityLevel) {
      case ActivityLevel.noWorkout:
        proteinPct = 0.25;
        carbPct = 0.50;
        fatPct = 0.25;
        break;
      case ActivityLevel.lightWorkout:
        proteinPct = 0.30;
        carbPct = 0.50;
        fatPct = 0.20;
        break;
      case ActivityLevel.heavyWorkout:
        proteinPct = 0.30;
        carbPct = 0.55;
        fatPct = 0.15;
        break;
    }

    // Adjust based on phase
    switch (phase) {
      case ActivityPhase.keep:
        // keep base
        break;
      case ActivityPhase.bulk:
        carbPct += 0.05;
        fatPct += 0.05; // extra energy from carbs/fat
        proteinPct -= 0.05;
        break;
      case ActivityPhase.cut:
        fatPct -= 0.05;
        carbPct -= 0.05;
        proteinPct += 0.10; // prioritize protein
        break;
    }

    // Normalize sums
    final sum = proteinPct + carbPct + fatPct;
    return {
      "protein": proteinPct / sum,
      "carbs": carbPct / sum,
      "fat": fatPct / sum,
    };
  }
}
