import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ── Thay bằng Client ID từ Google Cloud Console ──
  // Web client ID (type: Web application) — dùng cho cả iOS và Android
  static const _webClientId =
      '897631928759-fgcu7r236md0kmt8b1abi6kqcri9bpn0.apps.googleusercontent.com';
  // iOS client ID (type: iOS) — chỉ cần cho iOS
  static const _iosClientId =
      '897631928759-prnmf8ah34t98r57guju9l8dso0ggl65.apps.googleusercontent.com';

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

  /// Đăng ký tài khoản mới.
  /// Nếu Supabase bật "Confirm email", session sẽ null cho đến khi user xác
  /// nhận email. Kiểm tra [AuthResponse.session] để biết.
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

    // Nếu đã có session (email confirm tắt) → đảm bảo profile tồn tại
    if (response.session != null && response.user != null) {
      await _ensureProfile(
        userId: response.user!.id,
        email: email,
        username: username,
      );
    }

    return response;
  }

  // ─────── Google Sign-In (native) ───────

  /// Tạo random nonce string
  static String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Hash nonce bằng SHA-256
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<AuthResponse> signInWithGoogle() async {
    // Tạo nonce: raw cho Supabase, hashed cho Google
    final rawNonce = _generateRawNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    await GoogleSignIn.instance.initialize(
      clientId: _iosClientId,
      serverClientId: _webClientId,
      nonce: hashedNonce,
    );

    // Thử xóa session cũ nếu có (bỏ qua biệt lệ) để fix Account reauth failed
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    final googleUser = await GoogleSignIn.instance.authenticate();
    
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Không lấy được Google ID token');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      nonce: rawNonce,
    );

    // Đảm bảo profile tồn tại sau khi đăng nhập Google
    if (response.user != null) {
      await _ensureProfile(
        userId: response.user!.id,
        email: response.user!.email ?? googleUser.email,
        username:
            googleUser.displayName ??
            response.user!.email?.split('@').first ??
            'User',
      );
    }

    return response;
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

  /// Tạo profile nếu chưa tồn tại (tránh conflict với trigger).
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
