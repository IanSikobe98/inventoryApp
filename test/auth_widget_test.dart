import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockroom_app/app.dart';
import 'package:stockroom_app/models/permissions.dart';
import 'package:stockroom_app/services/password_cipher.dart';

import 'auth_helpers.dart';
import 'helpers.dart';

void main() {
  setUpAll(disableGoogleFonts);

  late AuthServer server;

  Future<void> openApp(WidgetTester tester, {Size size = const Size(1000, 1600)}) async {
    useBigSurface(tester, width: size.width, height: size.height);
    server = AuthServer();
    final api = fakeApi((req) async {
      if (req.url.path.startsWith('/api/v1/')) return server.handle(req);
      return jsonResponse({'message': 'Not mocked in this test'}, 404);
    });
    await tester.pumpWidget(
        StockroomApp(api: api, cipher: const PlainPasswordCipher()));
    await tester.pumpAndSettle();
  }

  Future<void> typeCredentials(WidgetTester tester) async {
    await tester.enterText(find.byKey(const Key('loginUsername')), 'Ian');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'SQEW13');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();
  }

  /// Ends a test that is sitting on the code screen: its countdown timer must be disposed.
  Future<void> leave(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('the app opens on the sign-in screen, not the dashboard', (tester) async {
    await openApp(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('loginUsername')), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('the password is hidden until the eye is tapped', (tester) async {
    await openApp(tester);
    TextField field() =>
        tester.widget<TextField>(find.byKey(const Key('loginPassword')));
    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('togglePassword')));
    await tester.pump();
    expect(field().obscureText, isFalse);
  });

  testWidgets('empty fields show a message and call nothing', (tester) async {
    await openApp(tester);
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username and password.'), findsOneWidget);
    expect(server.requests, isEmpty);
  });

  testWidgets('a wrong password shows the server message', (tester) async {
    await openApp(tester);
    server.authResponse = authJson(ok: false);
    await typeCredentials(tester);
    expect(find.text('Invalid Username or Password!'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('a good password leads to the code screen', (tester) async {
    await openApp(tester);
    await typeCredentials(tester);

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.byKey(const Key('otpField')), findsOneWidget);
    expect(find.text('Expires in 05:00'), findsNothing); // a few ms have passed
    expect(find.textContaining('Expires in 04:5'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('a wrong code shows the message and stays', (tester) async {
    await openApp(tester);
    await typeCredentials(tester);
    server.otpResponse = otpJson(ok: false);

    await tester.enterText(find.byKey(const Key('otpField')), '11111');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('wrong OTP Provided'), findsOneWidget);
    expect(find.byKey(const Key('otpField')), findsOneWidget);
    await leave(tester);
  });

  testWidgets('"Use a different account" returns to sign-in', (tester) async {
    await openApp(tester);
    await typeCredentials(tester);
    await tester.tap(find.byKey(const Key('otpBack')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('"Send a new code" asks the server again', (tester) async {
    await openApp(tester);
    await typeCredentials(tester);
    await tester.tap(find.byKey(const Key('otpResend')));
    await tester.pumpAndSettle();

    expect(server.bodiesFor('/api/v1/auth/authenticate'), hasLength(2));
    expect(find.text('A new code has been sent.'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('the right code opens the app and shows who is signed in', (tester) async {
    await openApp(tester);
    await typeCredentials(tester);
    await tester.enterText(find.byKey(const Key('otpField')), '70000');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Dashboard'), findsWidgets); // sidebar entry
    expect(find.text('Ian Walter'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.byKey(const Key('signOut')), findsOneWidget);
  });

  testWidgets('a cashier does not get the inventory or payment tabs', (tester) async {
    await openApp(tester);
    server.otpResponse =
        otpJson(role: 'Employee', perms: [Perm.createSales, Perm.viewSales]);
    await typeCredentials(tester);
    await tester.enterText(find.byKey(const Key('otpField')), '1');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Record sale'), findsWidgets);
    expect(find.text('Inventory'), findsNothing);
    expect(find.text('Payment modes'), findsNothing);
  });

  testWidgets('the tabs follow the permissions from sign-in', (tester) async {
    await openApp(tester);
    // the account from the real server reply: no payment permissions
    server.otpResponse = otpJson(role: 'SYSTEM_ADMIN', perms: [
      Perm.viewInventory,
      Perm.createInventory,
      Perm.updateInventory,
      Perm.createSales,
      Perm.viewSales,
    ]);
    await typeCredentials(tester);
    await tester.enterText(find.byKey(const Key('otpField')), '1');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Inventory'), findsWidgets);
    expect(find.text('Record sale'), findsWidgets);
    expect(find.text('Sales log'), findsWidgets);
    expect(find.text('Payment modes'), findsNothing);
  });

  testWidgets('an account with no permissions sees a "No access" page and can sign out',
      (tester) async {
    await openApp(tester);
    server.otpResponse = otpJson(perms: const []);
    await typeCredentials(tester);
    await tester.enterText(find.byKey(const Key('otpField')), '1');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('No access yet'), findsOneWidget);
    expect(find.byKey(const Key('signOut')), findsOneWidget);
  });

  testWidgets('a single permitted screen works (no bottom bar on a phone)',
      (tester) async {
    await openApp(tester, size: const Size(420, 900));
    server.otpResponse = otpJson(perms: [Perm.viewSales]);
    await typeCredentials(tester);
    await tester.enterText(find.byKey(const Key('otpField')), '1');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Sales log'), findsWidgets);
  });

  testWidgets('Sign out asks first, then returns to sign-in', (tester) async {
    await openApp(tester);
    await typeCredentials(tester);
    await tester.enterText(find.byKey(const Key('otpField')), '70000');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('signOut')));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    // changing your mind keeps you in
    await tester.tap(find.byKey(const Key('cancelSignOut')));
    await tester.pumpAndSettle();
    expect(server.logouts, 0);
    expect(find.byKey(const Key('signOut')), findsOneWidget);

    await tester.tap(find.byKey(const Key('signOut')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmSignOut')));
    await tester.pumpAndSettle();

    expect(server.logouts, 1);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Ian Walter'), findsNothing);
  });

  testWidgets('on a phone, sign out lives in the avatar menu', (tester) async {
    await openApp(tester, size: const Size(420, 900));
    await typeCredentials(tester);
    await tester.enterText(find.byKey(const Key('otpField')), '70000');
    await tester.tap(find.byKey(const Key('otpSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('IW'), findsOneWidget); // avatar initials
    await tester.tap(find.byKey(const Key('accountMenu')));
    await tester.pumpAndSettle();
    expect(find.text('Ian Walter'), findsOneWidget);
    expect(find.text('ADMIN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('signOutItem')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmSignOut')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
