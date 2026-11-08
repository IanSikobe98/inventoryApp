import 'package:flutter/foundation.dart';

import '../models/auth.dart';
import '../services/api_client.dart';
import '../services/password_cipher.dart';
import 'session_provider.dart';

/// Where the person is in the sign-in flow.
enum AuthStage { signedOut, otpPending, signedIn }

/// Runs the two-step sign-in (password, then one-time code) and sign-out.
///
/// The token lives in memory only, so closing the app signs the person out.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiClient api,
    required PasswordCipher cipher,
    required SessionProvider session,
    DateTime Function()? clock,
  })  : _api = api,
        _cipher = cipher,
        _session = session,
        _now = clock ?? DateTime.now {
    _api.onUnauthorized = _sessionExpired;
  }

  final ApiClient _api;
  final PasswordCipher _cipher;
  final SessionProvider _session;
  final DateTime Function() _now;

  AuthStage _stage = AuthStage.signedOut;
  bool _busy = false;
  String? _error;
  String? _notice;
  String _username = '';
  String? _protectedPassword; // kept only between step 1 and step 2
  DateTime? _otpExpiresAt;
  AuthUser? _user;

  AuthStage get stage => _stage;
  bool get busy => _busy;

  /// Problem to show on the current screen (wrong password, wrong code ...).
  String? get error => _error;

  /// Good news to show (e.g. "A new code was sent").
  String? get notice => _notice;
  String get username => _username;
  DateTime? get otpExpiresAt => _otpExpiresAt;
  AuthUser? get user => _user;
  bool get isSignedIn => _stage == AuthStage.signedIn;

  /// True once the current code has passed its expiry time.
  bool get otpExpired =>
      _otpExpiresAt != null && !_now().isBefore(_otpExpiresAt!);

  /// Step 1. Returns true when the server accepted the password and sent a code.
  Future<bool> signIn(String username, String password) async {
    final name = username.trim();
    if (name.isEmpty || password.isEmpty) {
      _setError('Enter your username and password.');
      return false;
    }
    return _authenticate(name, _cipher.protect(password), fresh: true);
  }

  /// Asks for another code using the credentials from step 1.
  Future<bool> resendCode() async {
    final pw = _protectedPassword;
    if (pw == null) return false;
    return _authenticate(_username, pw, fresh: false);
  }

  Future<bool> _authenticate(String username, String password,
      {required bool fresh}) async {
    _begin();
    try {
      final result =
          await _api.authenticate(username: username, password: password);
      if (!result.success) {
        _setError(result.message);
        return false;
      }
      _username = username;
      _protectedPassword = password;
      _otpExpiresAt = _now().add(Duration(minutes: result.otpExpiryMinutes));
      _stage = AuthStage.otpPending;
      _busy = false;
      _notice = fresh ? null : 'A new code has been sent.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  /// Step 2. Returns true when the code was right and the person is signed in.
  Future<bool> verifyOtp(String code) async {
    final otp = code.trim();
    final pw = _protectedPassword;
    if (pw == null) {
      backToLogin();
      return false;
    }
    if (otp.isEmpty) {
      _setError('Enter the code we sent you.');
      return false;
    }
    _begin();
    try {
      final result =
          await _api.validateOtp(username: _username, password: pw, otp: otp);
      final token = result.token;
      if (!result.success || token == null) {
        _setError(result.message);
        return false;
      }
      _api.authToken = token;
      final user = result.user ??
          AuthUser(name: _username, username: _username, role: '');
      _user = user;
      _protectedPassword = null;
      _otpExpiresAt = null;
      _stage = AuthStage.signedIn;
      _busy = false;
      _session.applyUser(user);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  /// Leaves the code screen to sign in as someone else.
  void backToLogin() {
    _clear();
    notifyListeners();
  }

  /// Ends the session. The server is told, but the person is signed out here
  /// even if that call fails (offline, token already expired ...).
  Future<void> signOut() async {
    _begin();
    try {
      await _api.logout();
    } on ApiException {
      // Signing out locally is what matters.
    }
    _finishSignOut();
  }

  void _sessionExpired() {
    if (_stage != AuthStage.signedIn) return;
    _finishSignOut();
    _error = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }

  void _finishSignOut() {
    _api.authToken = null;
    _session.reset();
    _clear();
    notifyListeners();
  }

  void _clear() {
    _stage = AuthStage.signedOut;
    _busy = false;
    _error = null;
    _notice = null;
    _username = '';
    _protectedPassword = null;
    _otpExpiresAt = null;
    _user = null;
  }

  void _begin() {
    _busy = true;
    _error = null;
    _notice = null;
    notifyListeners();
  }

  void _setError(String message) {
    _busy = false;
    _error = message;
    notifyListeners();
  }
}
