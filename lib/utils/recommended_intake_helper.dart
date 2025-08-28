import '../services/bmi_recommended_intake.dart'; // adjust path if needed

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

  // Your existing code can still read this:
  static Map<String, double> get dailyValues => _dailyValues;

  // Call this whenever the user updates weight/height/age/activity.
  static void update({
    required double weight,
    required double heightCm,
    required double age,
    required ActivityLevel activityLevel,
  }) {
    final calories = BmiRecommendedIntake.calculateMaintenanceCalories(
      weight: weight,
      heightCm: heightCm,
      age: age,
      activityLevel: activityLevel,
    );

    // You can make this activity-dependent later.
    final macros = BmiRecommendedIntake.calculateMacros(calories: calories);

    _dailyValues['energy-kcal'] = calories;
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
