class RecommendedIntakeHelper {
  // NOTE: These are example values based on a standard 2000 kcal diet.
  // For a real app, this should be personalized based on user data
  // (e.g., using the Harris-Benedict equation).
  static final Map<String, double> dailyValues = {
    'energy-kcal': 2000,
    'fat': 70, // g
    'saturated-fat': 20, // g
    'carbohydrates': 260, // g
    'sugars': 90, // g
    'proteins': 50, // g
    'salt': 6, // g
  };
}
