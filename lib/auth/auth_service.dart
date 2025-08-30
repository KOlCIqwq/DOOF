import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<AuthResponse> signWithEmailPassword(
    String email,
    String password,
  ) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user != null) {
      // If we got a new user init stats
      final userService = UserService();
      await userService.createProfile(
        userId: user.id,
        weight: null,
        height: null,
        age: null,
        gender: null,
        activity: null,
        phase: null,
      );
    }
    return response;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  String? getCurrentEmail() {
    final session = supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }
}
