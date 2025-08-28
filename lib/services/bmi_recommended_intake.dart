//import '../pages/profile_page.dart';

class BmiRecommendedIntake {
  /// Calculate BMI given weight (kg) and height (cm)
  static double calculateBmi(double weight, double heightCm) {
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  /// Return a BMI category string
  static String getBmiCategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal weight";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }
}
