import '../models/user_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class AuthService {
  final ApiClient _api;
  final TokenService _tokenService;

  AuthService(this._api, this._tokenService);

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      auth: false,
    );
    // Returns AuthMessageResponse — user may be null until email verified
    final user = data['user'];
    if (user != null) {
      return UserModel.fromJson(user as Map<String, dynamic>);
    }
    // Return a placeholder; the real user comes after email verification
    throw const ApiException('Registration successful. Please verify your email.');
  }

  /// Returns the message from the server (e.g. "Verification email sent")
  Future<String> registerAndGetMessage({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      auth: false,
    );
    return data['message'] as String? ?? 'Registration successful';
  }

  Future<UserModel> verifyEmail({
    required String email,
    required String code,
  }) async {
    final data = await _api.post(
      '/auth/verify-email',
      body: {'email': email, 'code': code},
      auth: false,
    );
    return _handleTokenResponse(data);
  }

  Future<String> resendVerificationCode(String email) async {
    final data = await _api.post(
      '/auth/resend-verification-code',
      body: {'email': email},
      auth: false,
    );
    return data['message'] as String? ?? 'Code sent';
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    return _handleTokenResponse(data);
  }

  Future<String> forgotPassword(String email) async {
    final data = await _api.post(
      '/auth/forgot-password',
      body: {'email': email},
      auth: false,
    );
    return data['message'] as String? ?? 'Reset code sent';
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final data = await _api.post(
      '/auth/reset-password',
      body: {'email': email, 'code': code, 'new_password': newPassword},
      auth: false,
    );
    return data['message'] as String? ?? 'Password reset successful';
  }

  Future<UserModel> refreshToken() async {
    final refreshToken = await _tokenService.getRefreshToken();
    if (refreshToken == null) throw const ApiException('No refresh token');
    final data = await _api.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
      auth: false,
    );
    return _handleTokenResponse(data);
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Best-effort — always clear local tokens
    }
    await _tokenService.clearAll();
  }

  Future<UserModel> getMe() async {
    final data = await _api.get('/auth/me');
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> _handleTokenResponse(dynamic data) async {
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await _tokenService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _tokenService.saveUser(user);
    return user;
  }
}
