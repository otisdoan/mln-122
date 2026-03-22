import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // ─────── Email / Password ───────

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.session != null && response.user != null) {
      await _ensureProfile(
        userId: response.user!.id,
        email: email,
        username: username,
      );
    }
    return response;
  }

  // ─────── Google Sign-In (OAuth Localhost Intercept Hack) ───────

  /// Dùng trình duyệt ẩn danh thay vì SDK native để bypass trọn vẹn
  /// yêu cầu cung cấp SHA-1 của Android/Google. Đồng thời dùng 
  /// http://localhost:3000 (URL mặc định của Supabase) để tránh
  /// phải setup Redirect URI bên Supabase Dashboard.
  static Future<bool> signInWithGoogle() async {
    final success = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'http://localhost:3000/',
    );
    return success;
  }

  static Future<void> ensureGoogleProfile() async {
    final user = currentUser;
    if (user == null) return;

    await _ensureProfile(
      userId: user.id,
      email: user.email ?? '',
      username: user.userMetadata?['full_name'] as String? ??
          user.userMetadata?['name'] as String? ??
          user.email?.split('@').first ??
          'User',
    );
  }

  // ─────── Session / Profile ───────

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }

  static Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  static Future<void> _ensureProfile({
    required String userId,
    required String email,
    required String username,
  }) async {
    final existing = await _client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'username': username,
        'avatar': '',
        'xp': 0,
        'level': 1,
      });
    }
  }
}
