import '../services/bmi_recommended_intake.dart';
import '../pages/profile_page.dart';

class ProfileModel {
  final double? weight;
  final double? height;
  final double? age;
  final Gender gender;
  final ActivityLevel activity;
  final ActivityPhase phase;

  ProfileModel({
    this.weight,
    this.height,
    this.age,
    required this.gender,
    required this.activity,
    required this.phase,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      age: (map['age'] as num?)?.toDouble(),
      gender: ProfileModel.genderFromNum((map['gender'] as num?)?.toInt()),
      activity: ProfileModel.activityFromNum(
        (map['activity'] as num?)?.toInt(),
      ),
      phase: ProfileModel.phaseFromNum((map['phase'] as num?)?.toInt()),
    );
  }

  static ActivityLevel activityFromNum(int? val) {
    switch (val) {
      case 1:
        return ActivityLevel.noWorkout;
      case 2:
        return ActivityLevel.lightWorkout;
      case 3:
        return ActivityLevel.heavyWorkout;
      default:
        return ActivityLevel.noWorkout;
    }
  }

  static Gender genderFromNum(int? val) {
    switch (val) {
      case 1:
        return Gender.male;
      case 2:
        return Gender.female;
      case 3:
        return Gender.other;
      default:
        return Gender.male;
    }
  }

  static ActivityPhase phaseFromNum(int? val) {
    switch (val) {
      case 1:
        return ActivityPhase.keep;
      case 2:
        return ActivityPhase.cut;
      case 3:
        return ActivityPhase.bulk;
      default:
        return ActivityPhase.keep;
    }
  }
}
