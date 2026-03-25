import '../services/bmi_recommended_intake.dart';

enum CalcMode { standard, percentage }

class ProfileModel {
  final double? weight;
  final double? height;
  final double? age;
  final Gender gender;
  final ActivityLevel activity;
  final ActivityPhase phase;
  final CalcMode calcMode;
  final int carbPercent;
  final int proteinPercent;
  final int fatPercent;

  ProfileModel({
    this.weight,
    this.height,
    this.age,
    required this.gender,
    required this.activity,
    required this.phase,
    // Add safe defaults so you don't have to rewrite every single instance creation
    this.calcMode = CalcMode.percentage,
    this.carbPercent = 40,
    this.proteinPercent = 30,
    this.fatPercent = 30,
  });

  // Used for reading from Supabase
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      age: (map['age'] as num?)?.toDouble(),
      gender: ProfileModel.genderFromNum(map['gender']),
      activity: ProfileModel.activityFromNum(map['activity']),
      phase: ProfileModel.phaseFromNum(map['phase']),

      // Load the new fields
      calcMode: ProfileModel.calcModeFromNum(map['calc_mode']),
      carbPercent: (map['carb_percent'] as num?)?.toInt() ?? 40,
      proteinPercent: (map['protein_percent'] as num?)?.toInt() ?? 30,
      fatPercent: (map['fat_percent'] as num?)?.toInt() ?? 30,
    );
  }

  // Used for a brand new user
  factory ProfileModel.defaults() {
    return ProfileModel(
      weight: null,
      height: null,
      age: null,
      gender: Gender.male,
      activity: ActivityLevel.noWorkout,
      phase: ActivityPhase.keep,
      calcMode: CalcMode.percentage,
      carbPercent: 40,
      proteinPercent: 30,
      fatPercent: 30,
    );
  }

  // Used for reading from local device storage
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      age: (json['age'] as num?)?.toDouble(),
      gender: ProfileModel.genderFromNum(json['gender']),
      activity: ProfileModel.activityFromNum(json['activity']),
      phase: ProfileModel.phaseFromNum(json['phase']),
      calcMode: ProfileModel.calcModeFromNum(json['calcMode']),
      carbPercent: (json['carbPercent'] as num?)?.toInt() ?? 40,
      proteinPercent: (json['proteinPercent'] as num?)?.toInt() ?? 30,
      fatPercent: (json['fatPercent'] as num?)?.toInt() ?? 30,
    );
  }

  // Used for saving to local device storage
  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender.index, // Save as int for consistency
      'activity': activity.index,
      'phase': phase.index,
      'calcMode': calcMode.index,
      'carbPercent': carbPercent,
      'proteinPercent': proteinPercent,
      'fatPercent': fatPercent,
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

  static CalcMode calcModeFromNum(dynamic v) {
    if (v is String) {
      return CalcMode.values.firstWhere(
        (e) => e.name == v,
        orElse: () => CalcMode.percentage,
      );
    }
    if (v is num) {
      final i = v.toInt();
      return (i >= 0 && i < CalcMode.values.length)
          ? CalcMode.values[i]
          : CalcMode.percentage;
    }
    return CalcMode.percentage; // fallback
  }
}
