import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tmdss/components/auth/data/auth_service.dart';
import 'package:tmdss/components/auth/domain/entities/app_user.dart';
import 'package:tmdss/components/auth/domain/repos/auth_repo.dart';

class SupabaseAuthRepo implements AuthRepo {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String contactNum,
    String password,
  ) async {
    try {
      // Convert email to lowercase for consistency
      final lowerCaseEmail = email.toLowerCase().trim();

      // Validate inputs
      if (name.isEmpty ||
          lowerCaseEmail.isEmpty ||
          contactNum.isEmpty ||
          password.isEmpty) {
        debugPrint('SupabaseAuthRepo: Invalid input provided');
        throw Exception('All fields are required');
      }

      // Register user with Supabase Auth
      final authResponse = await _authService.signUpWithEmailPassword(
        lowerCaseEmail,
        password,
      );

      // Check if user was created
      final user = authResponse.user;
      if (user == null) {
        debugPrint('SupabaseAuthRepo: Registration failed, no user returned');
        throw Exception('Registration failed: No user returned');
      }

      // Store additional user data in 'users' table
      final userData = AppUser(
        uid: user.id,
        name: name.trim(),
        email: lowerCaseEmail,
        contactNum: contactNum.trim(),
      );

      final response = await _supabase
          .from('users')
          .insert({
            'uid': user.id,
            'name': name.trim(),
            'email': lowerCaseEmail,
            'contact_num': contactNum.trim(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      debugPrint('SupabaseAuthRepo: User data stored: $response');

      // Return AppUser instance
      return AppUser.fromJson(response);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthRepo: Auth error: ${e.message}');
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      debugPrint('SupabaseAuthRepo: Unexpected error: $e');
      throw Exception('An unexpected error occurred during registration: $e');
    }
  }

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      // Sign in with Supabase Auth
      final authResponse = await _authService.signInWithEmailPassword(
        email,
        password,
      );

      // Check if user exists in auth response
      final user = authResponse.user;
      if (user == null) {
        debugPrint('SupabaseAuthRepo: Login failed, no user returned');
        throw Exception('Login failed: Invalid credentials');
      }

      // Fetch user data from 'users' table
      final response =
          await _supabase.from('users').select().eq('uid', user.id).single();
      debugPrint('SupabaseAuthRepo: User data retrieved: $response');

      // Explicitly check if the response contains valid data
      if (response == null || response.isEmpty) {
        debugPrint('SupabaseAuthRepo: No user data found for uid: ${user.id}');
        throw Exception('Login failed: User data not found');
      }

      return AppUser.fromJson(response);
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthRepo: Login error: ${e.message}');
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      debugPrint('SupabaseAuthRepo: Unexpected error during login: $e');
      throw Exception('An unexpected error occurred during login: $e');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      debugPrint('SupabaseAuthRepo: Current session: $session');
      if (session == null || session.user == null) {
        debugPrint('SupabaseAuthRepo: No active session found');
        return null;
      }

      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', session.user.id)
          .single();
      debugPrint('SupabaseAuthRepo: Raw response: $response');

      if (response == null) {
        debugPrint('SupabaseAuthRepo: Response is null');
        return null;
      }

      // Check individual fields
      final uid = response['uid'] as String?;
      final email = response['email'] as String?;
      final contactNum = response['contact_num'] as String?;
      final name = response['name'] as String?;
      debugPrint(
          'SupabaseAuthRepo: Fields - uid: $uid, email: $email, contactNum: $contactNum, name: $name');

      return AppUser.fromJson(response);
    } catch (e) {
      debugPrint('SupabaseAuthRepo: Error getting current user: $e');
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authService.signOut();
      debugPrint('SupabaseAuthRepo: User signed out successfully');
    } catch (e) {
      debugPrint('SupabaseAuthRepo: Error during logout: $e');
      throw Exception('Logout failed: $e');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      // Convert email to lowercase for consistency
      final lowerCaseEmail = email.toLowerCase().trim();

      if (lowerCaseEmail.isEmpty) {
        debugPrint('SupabaseAuthRepo: Invalid email provided');
        throw Exception('Email is required');
      }

      // Send password reset email
      await _supabase.auth.resetPasswordForEmail(lowerCaseEmail);
      debugPrint(
          'SupabaseAuthRepo: Password reset email sent to $lowerCaseEmail');
    } on AuthException catch (e) {
      debugPrint('SupabaseAuthRepo: Password reset error: ${e.message}');
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      debugPrint(
          'SupabaseAuthRepo: Unexpected error during password reset: $e');
      throw Exception('An unexpected error occurred during password reset: $e');
    }
  }
}
