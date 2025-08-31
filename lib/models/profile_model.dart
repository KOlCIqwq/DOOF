import '../services/bmi_recommended_intake.dart';

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

  factory ProfileModel.defaults() {
    return ProfileModel(
      weight: null, // A new user profile starts empty
      height: null,
      age: null,
      gender: Gender.male, // Or your preferred default
      activity: ActivityLevel.noWorkout,
      phase: ActivityPhase.keep,
    );
  }

  // Ensure fromJson and toJson handle all fields
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      age: (json['age'] as num).toDouble(),
      // Use default values if a field might be null in old stored data
      gender: Gender.values[json['gender'] ?? 0],
      activity: ActivityLevel.values[json['activity'] ?? 0],
      phase: ActivityPhase.values[json['phase'] ?? 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender.name,
      'activity': activity.name,
      'phase': phase.name,
    };
  }

  static ActivityLevel activityFromNum(dynamic v) {
    if (v is String) {
      return ActivityLevel.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ActivityLevel.noWorkout,
      );
    }
    if (v is num) {
      final i = v.toInt();
      return (i >= 0 && i < ActivityLevel.values.length)
          ? ActivityLevel.values[i]
          : ActivityLevel.noWorkout;
    }
    return ActivityLevel.noWorkout;
  }

  static Gender genderFromNum(dynamic v) {
    if (v is String) {
      return Gender.values.firstWhere(
        (e) => e.name == v,
        orElse: () => Gender.male,
      );
    }
    if (v is num) {
      final i = v.toInt();
      return (i >= 0 && i < Gender.values.length)
          ? Gender.values[i]
          : Gender.male;
    }
    return Gender.male;
  }

  static ActivityPhase phaseFromNum(dynamic v) {
    if (v is String) {
      return ActivityPhase.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ActivityPhase.keep,
      );
    }
    if (v is num) {
      final i = v.toInt();
      return (i >= 0 && i < ActivityPhase.values.length)
          ? ActivityPhase.values[i]
          : ActivityPhase.keep;
    }
    return ActivityPhase.keep;
  }
}
