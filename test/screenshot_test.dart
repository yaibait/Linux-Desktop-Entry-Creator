import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_launcher_creator/main.dart';

void main() {
  testWidgets('Capture screenshot', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 750);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: const DesktopEntryCreatorApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        final dir = Directory('assets/screenshots');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        File('assets/screenshots/main_window.png').writeAsBytesSync(buffer);
        // ignore: avoid_print
        print('SCREENSHOT_SAVED_SUCCESSFULLY');
      }
    }
  });
}
