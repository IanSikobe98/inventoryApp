import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/providers/auth_provider.dart';
import 'package:stockroom_app/providers/session_provider.dart';
import 'package:stockroom_app/services/api_client.dart';
import 'package:stockroom_app/services/password_cipher.dart';

import 'auth_helpers.dart';
import 'helpers.dart';

/// Pretends to encrypt, so tests can see it was applied.
class _TaggingCipher implements PasswordCipher {
  @override
  String protect(String plainPassword) => 'enc($plainPassword)';
}

void main() {
  late AuthServer server;
  late ApiClient api;
  late SessionProvider session;
  late DateTime now;
  late AuthProvider auth;

  setUp(() {
    server = AuthServer();
    api = fakeApi(server.handle);
    session = SessionProvider();
    now = DateTime(2026, 11, 5, 12, 0, 0);
    auth = AuthProvider(
        api: api, cipher: _TaggingCipher(), session: session, clock: () => now);
  });

  test('starts signed out', () {
    expect(auth.stage, AuthStage.signedOut);
    expect(auth.isSignedIn, isFalse);
    expect(auth.user, isNull);
  });

  test('empty fields never reach the server', () async {
    expect(await auth.signIn('  ', 'x'), isFalse);
    expect(await auth.signIn('Ian', ''), isFalse);
    expect(auth.error, 'Enter your username and password.');
    expect(server.requests, isEmpty);
  });

  test('step 1 sends the protected password and moves to the code step', () async {
    expect(await auth.signIn(' Ian ', 'SQEW13'), isTrue);

    expect(auth.stage, AuthStage.otpPending);
    expect(auth.username, 'Ian');
    expect(server.bodiesFor('/api/v1/auth/authenticate').single,
        {'username': 'Ian', 'password': 'enc(SQEW13)'});
    expect(auth.otpExpiresAt, now.add(const Duration(minutes: 5)));
    expect(auth.otpExpired, isFalse);
  });

  test('wrong password stays on the login step with the server message', () async {
    server.authResponse = authJson(ok: false);
    expect(await auth.signIn('Ian', 'bad'), isFalse);
    expect(auth.stage, AuthStage.signedOut);
    expect(auth.error, 'Invalid Username or Password!');
    expect(auth.busy, isFalse);
  });

  test('an HTTP error on step 1 shows its message', () async {
    server.authStatus = 401;
    server.authResponse = authJson(ok: false, message: 'Invalid Credentials');
    expect(await auth.signIn('x', 'y'), isFalse);
    expect(auth.error, 'Invalid Credentials');
  });

  test('the right code signs in, stores the token and applies the role', () async {
    await auth.signIn('Ian', 'SQEW13');
    expect(await auth.verifyOtp(' 70000 '), isTrue);

    expect(auth.stage, AuthStage.signedIn);
    expect(auth.user!.name, 'Ian Walter');
    expect(api.authToken, 'jwt-token-123');
    expect(session.isAdmin, isTrue);
    expect(server.bodiesFor('/api/v1/auth/validateOtp').single,
        {'username': 'Ian', 'password': 'enc(SQEW13)', 'otp': '70000'});
  });

  test('a non-admin role only gets the employee screens', () async {
    server.otpResponse = otpJson(role: 'Employee');
    await auth.signIn('mary', 'pw');
    await auth.verifyOtp('1');
    expect(session.isAdmin, isFalse);
    expect(session.routes, [AppRoute.sell, AppRoute.sales]);
    expect(session.route, AppRoute.sell);
  });

  test('a wrong code keeps the person on the code step', () async {
    server.otpResponse = otpJson(ok: false);
    await auth.signIn('Ian', 'pw');
    expect(await auth.verifyOtp('00000'), isFalse);

    expect(auth.stage, AuthStage.otpPending);
    expect(auth.error, 'wrong OTP Provided');
    expect(api.authToken, isNull);
  });

  test('an empty code is not sent', () async {
    await auth.signIn('Ian', 'pw');
    expect(await auth.verifyOtp('  '), isFalse);
    expect(auth.error, 'Enter the code we sent you.');
    expect(server.bodiesFor('/api/v1/auth/validateOtp'), isEmpty);
  });

  test('the code expires with the clock', () async {
    await auth.signIn('Ian', 'pw');
    now = now.add(const Duration(minutes: 4, seconds: 59));
    expect(auth.otpExpired, isFalse);
    now = now.add(const Duration(seconds: 1));
    expect(auth.otpExpired, isTrue);
  });

  test('resend asks for a new code with the same credentials', () async {
    server.authResponse = authJson(otpExpiry: '3');
    await auth.signIn('Ian', 'pw');
    now = now.add(const Duration(minutes: 4));
    expect(auth.otpExpired, isTrue);

    expect(await auth.resendCode(), isTrue);
    expect(auth.otpExpired, isFalse);
    expect(auth.otpExpiresAt, now.add(const Duration(minutes: 3)));
    expect(auth.notice, 'A new code has been sent.');
    final bodies = server.bodiesFor('/api/v1/auth/authenticate');
    expect(bodies, hasLength(2));
    expect(bodies.last, {'username': 'Ian', 'password': 'enc(pw)'});
  });

  test('"use a different account" forgets the credentials', () async {
    await auth.signIn('Ian', 'pw');
    auth.backToLogin();
    expect(auth.stage, AuthStage.signedOut);
    expect(auth.username, '');
    expect(await auth.resendCode(), isFalse);
  });

  test('sign out calls the server, drops the token and resets the role', () async {
    await auth.signIn('Ian', 'pw');
    await auth.verifyOtp('1');
    expect(api.authToken, isNotNull);

    await auth.signOut();

    expect(server.logouts, 1);
    expect(auth.stage, AuthStage.signedOut);
    expect(auth.user, isNull);
    expect(api.authToken, isNull);
    expect(session.isAdmin, isFalse);
  });

  test('sign out still works when the server cannot be reached', () async {
    final offline = AuthProvider(
      api: fakeApi((req) async {
        if (req.url.path == '/api/v1/user/logout') {
          throw ApiException('offline');
        }
        return AuthServer().handle(req);
      }),
      cipher: _TaggingCipher(),
      session: session,
    );
    await offline.signIn('Ian', 'pw');
    await offline.verifyOtp('1');
    await offline.signOut();
    expect(offline.stage, AuthStage.signedOut);
  });

  test('an expired session sends the person back to sign in', () async {
    var expire = false;
    final api2 = fakeApi((req) async {
      if (expire && req.url.path == '/api/shoe-batches') {
        return jsonResponse({}, 401);
      }
      return server.handle(req);
    });
    final a = AuthProvider(
        api: api2, cipher: _TaggingCipher(), session: session);
    await a.signIn('Ian', 'pw');
    await a.verifyOtp('1');
    expect(a.isSignedIn, isTrue);

    expire = true;
    await expectLater(api2.searchBatches(), throwsA(isA<ApiException>()));

    expect(a.stage, AuthStage.signedOut);
    expect(a.error, contains('session has expired'));
    expect(api2.authToken, isNull);
  });
}
