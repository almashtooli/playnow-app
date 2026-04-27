import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/auth_models.dart';
import 'notification_service.dart';

const _tokenKey = 'jwt_token';

class AuthService extends ChangeNotifier {
  AuthUser? _currentUser;
  bool _isInitializing = true;
  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitializing => _isInitializing;

  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token == null) return;
      apiClient.setToken(token);
      await fetchMe();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final data = await apiClient.post(
        '/auth/login',
        body: LoginRequest(email: email, password: password).toJson(),
      );
      await _saveToken(data['token']);
      _currentUser = AuthUser.fromJson(data);
      notifyListeners();
      await NotificationService.saveFcmToken();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connection failed. Please try again.';
    }
  }

  Future<String?> loginWithPhone(String firebaseIdToken) async {
    try {
      final data = await apiClient.post(
        '/auth/phone-login',
        body: PhoneLoginRequest(firebaseToken: firebaseIdToken).toJson(),
      );
      await _saveToken(data['token']);
      _currentUser = AuthUser.fromJson(data);
      notifyListeners();
      await NotificationService.saveFcmToken();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connection failed. Please try again.';
    }
  }

  Future<String?> register(
    String name,
    String email,
    String password, {
    String? phone,
    String? birthDate,
  }) async {
    try {
      await apiClient.post(
        '/auth/register',
        body: RegisterRequest(
          name: name,
          email: email,
          password: password,
          phone: phone,
          birthDate: birthDate,
        ).toJson(),
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connection failed. Please try again.';
    }
  }

  Future<void> fetchMe() async {
    try {
      final data = await apiClient.get('/auth/me');
      _currentUser = AuthUser.fromJson(data);
      notifyListeners();
    } on ApiException {
      await logout();
    }
  }

  Future<String?> updateProfile({String? name, String? phone}) async {
    try {
      final data = await apiClient.put(
        '/auth/profile',
        body: UpdateProfileRequest(fullName: name, phone: phone).toJson(),
      );
      _currentUser = _currentUser?.copyWith(name: data['fullName'], phone: data['phone']);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Connection failed. Please try again.';
    }
  }

  Future<String?> uploadAvatar(XFile file) async {
    try {
      final data = await apiClient.uploadFile(
        '/auth/avatar',
        bytes: await file.readAsBytes(),
        filename: file.name,
        fieldName: 'file',
      );
      final url = data['avatarUrl'] as String;
      _currentUser = _currentUser?.copyWith(avatarUrl: url);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Upload failed. Please try again.';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    apiClient.setToken(null);
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    apiClient.setToken(token);
  }
}
