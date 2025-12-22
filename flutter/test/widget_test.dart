import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:attendancesystem/main.dart';

class _TestAssetBundle extends CachingAssetBundle {
  static final Uint8List _pngBytes = Uint8List.fromList(const <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  @override
  Future<ByteData> load(String key) async {
    switch (key) {
      case 'AssetManifest.bin':
        return const StandardMessageCodec()
            .encodeMessage(<String, List<String>>{})!;
      case 'AssetManifest.json':
        return ByteData.sublistView(
          Uint8List.fromList(utf8.encode('{}')),
        );
      case 'FontManifest.json':
        return ByteData.sublistView(
          Uint8List.fromList(utf8.encode('[]')),
        );
      case 'assets/attt.png':
      case 'assets/download.png':
        return ByteData.sublistView(_pngBytes);
      default:
        throw FlutterError('Unexpected asset requested in test: $key');
    }
  }
}

void main() {
  testWidgets('Renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
    expect(find.text('Welcome to Attendance System'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      findsOneWidget,
    );
    expect(find.text('Select User Type'), findsOneWidget);
  });
}
