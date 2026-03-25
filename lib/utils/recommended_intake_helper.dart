import '../services/bmi_recommended_intake.dart'; // adjust path if needed
import 'package:DOOF/models/profile_model.dart';

class RecommendedIntakeHelper {
  // Backwards-compatible storage
  static final Map<String, double> _dailyValues = {
    'energy-kcal': 2000,
    'fat': 70, // g
    'saturated-fat': 20, // g
    'carbohydrates': 260, // g
    'sugars': 90, // g
    'proteins': 50, // g
    'salt': 6, // g
  };

  static Map<String, double> get dailyValues => _dailyValues;
  // Call this whenever the user updates weight/height/age/activity.
  static void update({
    required double weight,
    required double heightCm,
    required double age,
    required Gender gender,
    required ActivityLevel activityLevel,
    required ActivityPhase activityPhase,
    CalcMode mode = CalcMode.percentage,
    int carbPercent = 40,
    int proteinPercent = 30,
    int fatPercent = 30,
  }) {
    if (mode == CalcMode.percentage) {
      // USE THE NEW TDEE MATH
      final bmr = TdeeCalculator.calculateBMR(
        weight: weight,
        heightCm: heightCm,
        age: age.toInt(),
        gender: gender,
      );
      final tdee = TdeeCalculator.calculateTDEE(
        bmr: bmr,
        activityLevel: activityLevel,
      );
      final targetCals = TdeeCalculator.getTargetCalories(tdee, activityPhase);

      final macros = TdeeCalculator.calculateMacros(
        targetCalories: targetCals,
        carbPercent: carbPercent,
        proteinPercent: proteinPercent,
        fatPercent: fatPercent,
      );

      dailyValues['energy-kcal'] = targetCals;
      dailyValues['carbohydrates'] = macros['carbs']!;
      dailyValues['proteins'] = macros['protein']!;
      dailyValues['fat'] = macros['fat']!;
    } else {
      final maintainCalories =
          BmiRecommendedIntake.calculateMaintenanceCalories(
            weight: weight,
            heightCm: heightCm,
            age: age,
            gender: gender,
            activityLevel: activityLevel,
          );

      final targetCalories = BmiRecommendedIntake.adjustCaloriesForPhase(
        maintainCalories,
        activityPhase,
      );

      // You can make this activity-dependent later.
      final macros = BmiRecommendedIntake.calculateMacros(
        calories: targetCalories,
        weight: weight,
        activityLevel: activityLevel,
        phase: activityPhase,
      );

      _dailyValues['energy-kcal'] = targetCalories;
      _dailyValues['proteins'] = macros['protein_g'] ?? 0;
      _dailyValues['fat'] = macros['fat_g'] ?? 0;
      _dailyValues['saturated-fat'] =
          (_dailyValues['fat'] ?? 0) * 0.30; // assume 30% of fat as saturated
      _dailyValues['carbohydrates'] = macros['carbs_g'] ?? 0;
      _dailyValues['sugars'] =
          (_dailyValues['carbohydrates'] ?? 0) * 0.35; // assume 35% sugars
      _dailyValues['salt'] = 6; // keep static for now
    }
  }
}
