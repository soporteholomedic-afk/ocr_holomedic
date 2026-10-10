/// Widget tests for the camera scan-guide overlay (dark scrim + bracket
/// frame + hint).
///
/// The overlay is plugin-free, so it is tested directly on a fixed
/// 800x600 test surface. The plugin-bound capture screens that wire this
/// overlay in (`BarcodeScanScreen`, `MrzScanScreen`) stay out of widget
/// tests as before; their wiring is verified by `flutter analyze`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ocr_dni/theme/app_theme.dart';
import 'package:ocr_dni/ui/widgets/scan_guide_overlay.dart';

const Size _surface = Size(800, 600);

Future<void> _pumpOverlay(
  WidgetTester tester, {
  ScanGuideOverlay? overlay,
  Widget? behindOverlay,
}) async {
  await tester.binding.setSurfaceSize(_surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: appThemeLight,
      home: Scaffold(
        body: Stack(
          children: [
            ?behindOverlay,
            overlay ?? const ScanGuideOverlay(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('overlay renders the hint text below the guide window',
      (tester) async {
    await _pumpOverlay(
      tester,
      overlay: const ScanGuideOverlay(
          hint: 'Align the barcode on the back of the DNI inside the frame'),
    );

    expect(
        find.text('Align the barcode on the back of the DNI inside the frame'),
        findsOneWidget);

    final frame = tester.getRect(find.byKey(const Key('scan-guide-frame')));
    final hint = tester.getRect(find.byKey(const Key('scan-guide-hint')));
    expect(hint.top, greaterThanOrEqualTo(frame.bottom));
  });

  testWidgets('overlay exposes keys for the frame window and the four corner brackets',
      (tester) async {
    await _pumpOverlay(tester);

    expect(find.byKey(const Key('scan-guide-frame')), findsOneWidget);
    for (final corner in ['top-left', 'top-right', 'bottom-left', 'bottom-right']) {
      expect(find.byKey(Key('scan-guide-bracket-$corner')), findsOneWidget);
    }
  });

  testWidgets('window spans 90% of the surface width and honors a custom aspect ratio',
      (tester) async {
    // Assumption encoded: the guide window takes 90% of the available
    // width and derives its height as width / aspectRatio.
    await _pumpOverlay(
        tester, overlay: const ScanGuideOverlay(aspectRatio: 2));

    expect(
      tester.getSize(find.byKey(const Key('scan-guide-frame'))),
      const Size(720, 360), // 800 * 0.9 wide, 720 / 2 tall.
    );
  });

  testWidgets('window sits in the lower third of the surface when aligned off-center',
      (tester) async {
    // Assumption encoded: lower-third MRZ placement — the window starts at
    // or below the vertical middle, its center falls past 2/3 of the
    // height, and it stays fully on screen so the hint below still fits.
    await _pumpOverlay(
      tester,
      overlay: const ScanGuideOverlay(
        aspectRatio: 3.4,
        alignment: Alignment(0, 0.6),
      ),
    );

    final frame = tester.getRect(find.byKey(const Key('scan-guide-frame')));
    expect(frame.top, greaterThan(_surface.height / 2 - 10));
    expect(frame.center.dy, greaterThan(_surface.height * 2 / 3));
    expect(frame.bottom, lessThan(_surface.height));
  });

  testWidgets('overlay passes taps through so underlying camera controls keep working',
      (tester) async {
    var cancelTaps = 0;
    await _pumpOverlay(
      tester,
      behindOverlay: Center(
        child: FilledButton(
          onPressed: () => cancelTaps++,
          child: const Text('Cancel'),
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));

    expect(cancelTaps, 1);
  });
}
