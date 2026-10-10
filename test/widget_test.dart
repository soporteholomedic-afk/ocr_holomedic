/// Widget tests for the scan flow driven through the real app root.
///
/// The scanner plugins cannot run in tests, so the app root accepts
/// constructor-injected port implementations and these tests use in-memory
/// fakes returning canned payloads from the parser fixtures.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ocr_dni/main.dart';

import 'fakes/fake_scan_ports.dart';
import 'fixtures/dni_payload_fixtures.dart';
import 'fixtures/mrz_fixtures.dart';

void main() {
  testWidgets('home renders the app title and the primary Scan DNI button',
      (tester) async {
    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner(const []),
      mrzScanner: FakeMrzScanner(const []),
    ));

    expect(find.text('DNI Scanner'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Scan DNI'), findsOneWidget);
  });

  testWidgets(
      'successful barcode and MRZ flow renders the parsed card with birth date from MRZ',
      (tester) async {
    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner([canonicalFixedOffset1997Payload]),
      mrzScanner: FakeMrzScanner([canonicalTd1Mrz]),
    ));

    await tester.tap(find.byKey(const Key('scan-dni-button')));
    await tester.pumpAndSettle();

    // Names come from the PDF417 payload (merger prefers it over the MRZ,
    // whose 30-char lines truncate given names).
    expect(find.text('45595338'), findsOneWidget);
    expect(find.text('Castillo'), findsOneWidget);
    expect(find.text('Ceferino'), findsOneWidget);
    expect(find.text('Norman Valery'), findsOneWidget);
    // Birth date comes only from the MRZ (1995-03-12 -> dd/MM/yyyy).
    expect(find.text('12/03/1995'), findsOneWidget);
    expect(find.byKey(const Key('missing-flag-birthDate')), findsNothing);
  });

  testWidgets(
      'barcode-only flow with MRZ skipped marks the birth date as not captured',
      (tester) async {
    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner([canonicalFixedOffset1997Payload]),
      mrzScanner: FakeMrzScanner([null]), // user pressed Skip
    ));

    await tester.tap(find.byKey(const Key('scan-dni-button')));
    await tester.pumpAndSettle();

    expect(find.text('45595338'), findsOneWidget);
    expect(find.byKey(const Key('missing-flag-birthDate')), findsOneWidget);
    expect(find.text('12/03/1995'), findsNothing);
  });

  testWidgets(
      'unknown-layout payload renders the parse-error state with the raw payload after expanding',
      (tester) async {
    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner([unknownLayoutPayload]),
      mrzScanner: FakeMrzScanner([null]),
    ));

    await tester.tap(find.byKey(const Key('scan-dni-button')));
    await tester.pumpAndSettle();

    expect(find.text('Could not read the document'), findsOneWidget);
    expect(find.byKey(const Key('raw-payload-section')), findsOneWidget);
    // Collapsed by default; nothing is guessed or rendered as data.
    expect(find.text(unknownLayoutPayload), findsNothing);

    await tester.tap(find.text('Raw payload'));
    await tester.pumpAndSettle();
    expect(find.text(unknownLayoutPayload), findsOneWidget);
  });

  testWidgets(
      'error state exposes the raw MRZ text collapsible when the MRZ was attempted',
      (tester) async {
    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner([unknownLayoutPayload]),
      mrzScanner: FakeMrzScanner([twoLinesOnlyMrz]),
    ));

    await tester.tap(find.byKey(const Key('scan-dni-button')));
    await tester.pumpAndSettle();

    expect(find.text('Could not read the document'), findsOneWidget);
    expect(find.byKey(const Key('raw-mrz-section')), findsOneWidget);

    await tester.tap(find.text('Raw MRZ text'));
    await tester.pumpAndSettle();
    expect(find.text(twoLinesOnlyMrz), findsOneWidget);
  });

  testWidgets('cancelling the barcode scan returns to home without a result',
      (tester) async {
    final mrzScanner = FakeMrzScanner(const []);
    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner([null]), // user pressed Cancel
      mrzScanner: mrzScanner,
    ));

    await tester.tap(find.byKey(const Key('scan-dni-button')));
    await tester.pumpAndSettle();

    expect(find.text('DNI Scanner'), findsOneWidget);
    expect(find.text('Scan result'), findsNothing);
    // The MRZ step is never started when the barcode step was cancelled.
    expect(mrzScanner.scanCallCount, 0);
  });

  testWidgets('home shows the last result summary after returning from the card',
      (tester) async {
    // The full card plus actions exceed the default 800x600 surface.
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner([canonicalFixedOffset1997Payload]),
      mrzScanner: FakeMrzScanner([canonicalTd1Mrz]),
    ));

    await tester.tap(find.byKey(const Key('scan-dni-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('done-button')));
    await tester.pumpAndSettle();

    expect(find.text('DNI 45595338'), findsOneWidget);
    expect(find.text('Scan DNI'), findsOneWidget);
  });

  testWidgets('Scan again resets the flow and accepts a new scan',
      (tester) async {
    await tester.pumpWidget(OcrDniApp(
      barcodeScanner: FakeBarcodeScanner(
          [unknownLayoutPayload, canonicalFixedOffset1997Payload]),
      mrzScanner: FakeMrzScanner([null, canonicalTd1Mrz]),
    ));

    await tester.tap(find.byKey(const Key('scan-dni-button')));
    await tester.pumpAndSettle();
    expect(find.text('Could not read the document'), findsOneWidget);

    await tester.tap(find.byKey(const Key('scan-again-button')));
    await tester.pumpAndSettle();

    // Fresh flow over the second payloads: parsed card, no stale error.
    expect(find.text('45595338'), findsOneWidget);
    expect(find.text('Could not read the document'), findsNothing);
  });
}
