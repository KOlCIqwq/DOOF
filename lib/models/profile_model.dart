import '../services/bmi_recommended_intake.dart';

class ProfileModel {
  double weight;
  double height;
  double age;
  ActivityLevel activity;

  ProfileModel({
    required this.weight,
    required this.height,
    required this.age,
    required this.activity,
  });

  // JSON serialization (for storage)
  Map<String, dynamic> toJson() => {
    'weight': weight,
    'height': height,
    'age': age,
    'activity': activity.index, // store enum as int
  };

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    weight: (json['weight'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    age: (json['age'] as num).toDouble(),
    activity: ActivityLevel.values[json['activity'] as int],
  );
}
