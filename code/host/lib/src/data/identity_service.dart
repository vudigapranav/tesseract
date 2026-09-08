import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Public Firebase API key is build configuration, never an Admin credential.
/// Email/password provider is an optional adapter pending the project choice.
class IdentityService {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const backendUrl = String.fromEnvironment('TESSERACT_API_URL');
  static bool get configured =>
      apiKey.isNotEmpty && backendUrl.startsWith('https://');
  final _storage = const FlutterSecureStorage();
  String? _idToken;
  DateTime _expires = DateTime(2000);

  /// Stable provider user id. Used to partition durable local data so a
  /// shared device never shows one caregiver another's patient content.
  /// Null until sign-in or a successful token refresh establishes it.
  String? uid;
  Future<void> signIn(String email, String password) async {
    if (!configured) {
      throw StateError(
          'Real sign-in needs public Firebase and HTTPS backend configuration.');
    }
    final response = await http
        .post(
            Uri.https('identitytoolkit.googleapis.com',
                '/v1/accounts:signInWithPassword', {'key': apiKey}),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true
            }))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
          'Sign-in was not accepted. Check your details and connection.');
    }
    final data = jsonDecode(response.body) as Map;
    _idToken = data['idToken'] as String;
    uid = data['localId'] as String?;
    _expires = DateTime.now().add(const Duration(minutes: 55));
    await _storage.write(
        key: 'firebase_refresh', value: data['refreshToken'] as String);
  }

  Future<String> token() async {
    if (_idToken != null && DateTime.now().isBefore(_expires)) {
      return _idToken!;
    }
    final refresh = await _storage.read(key: 'firebase_refresh');
    if (refresh == null || !configured) {
      throw StateError('Please sign in again.');
    }
    final response = await http.post(
        Uri.https('securetoken.googleapis.com', '/v1/token', {'key': apiKey}),
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refresh
        }).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError('Identity expired. Please sign in again.');
    }
    final data = jsonDecode(response.body) as Map;
    _idToken = data['id_token'] as String;
    uid = data['user_id'] as String? ?? uid;
    _expires = DateTime.now().add(const Duration(minutes: 55));
    await _storage.write(
        key: 'firebase_refresh', value: data['refresh_token'] as String);
    return _idToken!;
  }

  Future<void> signOut() async {
    _idToken = null;
    uid = null;
    await _storage.delete(key: 'firebase_refresh');
  }

  Future<bool> unlock() async {
    try {
      return await LocalAuthentication().authenticate(
          localizedReason:
              'Unlock the caregiver area using your device security',
          persistAcrossBackgrounding: true);
    } catch (_) {
      return false;
    }
  }
}
