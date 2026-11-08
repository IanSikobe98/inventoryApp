import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stockroom_app/app.dart';
import 'package:stockroom_app/models/permissions.dart';
import 'package:stockroom_app/services/api_client.dart';
import 'package:stockroom_app/services/picture_service.dart';
import 'package:stockroom_app/utils/picture_encoder.dart';
import 'package:stockroom_app/theme/app_theme.dart';

/// Call at the top of main() in every widget test file so the fonts package
/// doesn't try to download anything.
void disableGoogleFonts() {
  AppText.useGoogleFonts = false;
}

http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// A real 1x1 pixel PNG as base64: what a stored photo looks like coming back from the API.
const String tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGM4MU0XAAO1AYxKk7cJAAAAAElFTkSuQmCC';

Map<String, dynamic> batchJson({
  int id = 1,
  String code = 'SB-2201',
  int remaining = 24,
  int received = 24,
  String? picture,
}) =>
    {
      'id': id,
      'shoeCode': code,
      'size': '42',
      'type': 'Sneaker',
      'colour': 'Black',
      'pictureUrl': picture,
      'quantityReceived': received,
      'quantityRemaining': remaining,
      'costPerShoe': 1800.0,
      'wholesalePrice': 2500.0,
      'retailPrice': 3200.0,
      'lowStock': remaining > 0 && remaining <= 5,
      'outOfStock': remaining <= 0,
    };

Map<String, dynamic> pageJson(List<Map<String, dynamic>> content) => {
      'content': content,
      'totalElements': content.length,
      'totalPages': 1,
      'number': 0,
      'last': true,
    };

Map<String, dynamic> saleJson() => {
      'id': 10,
      'shoeBatchId': 1,
      'shoeCode': 'SB-2201',
      'shoeDescription': 'SB-2201 · Sneaker · Black',
      'actualSellingPrice': 3200.0,
      'quantitySold': 2,
      'paymentModeId': 2,
      'paymentModeName': 'M-Pesa',
      'totalAmount': 6400.0,
      'remarks': null,
      'createdAt': '2026-09-28T10:15:30.123456',
      'createdBy': 1,
    };

ApiClient fakeApi(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(baseUrl: 'http://test', client: MockClient(handler));

/// Stands in for the camera/gallery in widget tests.
class FakePictureService implements PictureService {
  FakePictureService({this.result, this.camera = false, this.error});

  /// What "choosing a photo" returns. Null behaves like the user cancelling.
  final EncodedPicture? result;
  final bool camera;
  final PictureException? error;

  int calls = 0;
  PictureSource? lastSource;

  @override
  bool get cameraAvailable => camera;

  @override
  Future<EncodedPicture?> pickAndEncode(PictureSource source) async {
    calls++;
    lastSource = source;
    if (error != null) throw error!;
    return result;
  }
}

/// A ready-made picked photo (the tiny PNG, pretending to be the compressed result).
EncodedPicture fakeEncodedPicture() => const EncodedPicture(
    base64: tinyPngBase64, bytes: 70, width: 1, height: 1);

/// Wraps [child] with all providers and the app theme.
///
/// [permissions] are what the signed-in person may do; by default everything,
/// so screens can be tested without going through sign-in.
Widget harness(ApiClient api, Widget child,
        {PictureService? pictures, Set<String>? permissions}) =>
    AppProviders(
      api: api,
      pictures: pictures,
      permissions: permissions ?? Perm.all,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );

/// Gives widget tests a big, 1:1 screen so nothing needs scrolling.
void useBigSurface(WidgetTester tester,
    {double width = 1000, double height = 1600}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
