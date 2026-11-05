import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/services/api_client.dart';

import 'auth_helpers.dart';
import 'helpers.dart';

void main() {
  test('authenticate posts username and password to /api/v1/auth/authenticate', () async {
    final server = AuthServer();
    final api = fakeApi(server.handle);

    final result = await api.authenticate(username: 'Ian', password: 'SQEW13');

    expect(result.success, isTrue);
    final req = server.requests.single;
    expect(req.method, 'POST');
    expect(req.url.path, '/api/v1/auth/authenticate');
    expect(server.bodiesFor('/api/v1/auth/authenticate').single,
        {'username': 'Ian', 'password': 'SQEW13'});
  });

  test('validateOtp posts the credentials and the code', () async {
    final server = AuthServer();
    final api = fakeApi(server.handle);

    final result =
        await api.validateOtp(username: 'Ian', password: 'enc', otp: '70000');

    expect(result.success, isTrue);
    expect(result.token, 'jwt-token-123');
    expect(server.bodiesFor('/api/v1/auth/validateOtp').single,
        {'username': 'Ian', 'password': 'enc', 'otp': '70000'});
  });

  test('a FAIL answer with HTTP 200 comes back as a result, not an exception', () async {
    final server = AuthServer(authResponse: authJson(ok: false));
    final result = await fakeApi(server.handle)
        .authenticate(username: 'Ian', password: 'bad');
    expect(result.success, isFalse);
    expect(result.message, 'Invalid Username or Password!');
  });

  test('an HTTP 401 on sign-in shows the server\'s responseMessage', () async {
    final server = AuthServer(
        authResponse: authJson(ok: false, message: 'Invalid Credentials'),
        authStatus: 401);
    final api = fakeApi(server.handle);

    await expectLater(
      api.authenticate(username: 'x', password: 'y'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Invalid Credentials')
          .having((e) => e.statusCode, 'status', 401)),
    );
  });

  test('other calls carry the token once one is set, auth calls never do', () async {
    final server = AuthServer();
    final api = fakeApi(server.handle);

    await api.authenticate(username: 'Ian', password: 'x');
    expect(server.requests.last.headers.containsKey('Authorization'), isFalse);

    api.authToken = 'abc.def';
    await api.logout();
    expect(server.requests.last.headers['Authorization'], 'Bearer abc.def');

    // even with a (possibly stale) token set, the sign-in calls go without it
    await api.validateOtp(username: 'Ian', password: 'x', otp: '1');
    expect(server.requests.last.headers.containsKey('Authorization'), isFalse);

    api.authToken = null;
    await api.logout();
    expect(server.requests.last.headers.containsKey('Authorization'), isFalse);
  });

  test('inventory calls are sent with the token too', () async {
    String? seen;
    final api = fakeApi((req) async {
      seen = req.headers['Authorization'];
      return jsonResponse(pageJson([]));
    });
    api.authToken = 'tok';
    await api.searchBatches();
    expect(seen, 'Bearer tok');
  });

  test('HTTP 401 while holding a token reports an expired session', () async {
    final api = fakeApi((req) async => jsonResponse({}, 401));
    api.authToken = 'old';
    var expired = 0;
    api.onUnauthorized = () => expired++;

    await expectLater(
      api.searchBatches(),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', contains('session has expired'))),
    );
    expect(expired, 1);
  });

  test('HTTP 401 without a token is a normal error and does not signal expiry', () async {
    final api = fakeApi((req) async => jsonResponse({'message': 'Nope'}, 401));
    var expired = 0;
    api.onUnauthorized = () => expired++;

    await expectLater(api.searchBatches(), throwsA(isA<ApiException>()));
    expect(expired, 0);
  });

  test('logout returns the server message', () async {
    final server = AuthServer();
    final api = fakeApi(server.handle)..authToken = 't';
    expect(await api.logout(), 'User Logged Out');
    expect(server.requests.single.url.path, '/api/v1/user/logout');
    expect(server.requests.single.method, 'POST');
  });
}
