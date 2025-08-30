import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Create Profile with parameters, required userId
  Future<void> createProfile({
    required String userId,
    double? weight,
    double? height,
    int? age,
    int? gender,
    int? activity,
    int? phase,
  }) async {
    await supabase.from('profiles').insert({
      'id': userId,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
      'activity': activity,
      'phase': phase,
    });
  }

  /// Get all info of profile using userId
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> updateProfile({
    required String userId,
    double? weight,
    double? height,
    int? age,
    int? gender,
    int? activity,
    int? phase,
  }) async {
    await supabase
        .from('profiles')
        .update({
          if (weight != null) 'weight': weight,
          if (height != null) 'height': height,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
          if (activity != null) 'activity': activity,
          if (phase != null) 'phase': phase,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }
}
