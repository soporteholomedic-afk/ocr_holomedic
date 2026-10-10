/// Widget tests for the DNI result card.
///
/// Focuses on card details (per-field source badges, missing-field flags,
/// pending-calibration chips for address/ubigeo) that are orthogonal to the
/// flow tests in `test/widget_test.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ocr_dni/src/merge/dni_merger.dart';
import 'package:ocr_dni/src/parser/mrz_td1_parser.dart';
import 'package:ocr_dni/src/parser/pdf417_parser.dart';
import 'package:ocr_dni/src/scan/scan_outcome.dart';
import 'package:ocr_dni/ui/dni_card_screen.dart';

import '../fixtures/dni_payload_fixtures.dart';
import '../fixtures/mrz_fixtures.dart';

/// Builds the outcome with the same parse-and-merge policy the flow uses.
ScanOutcome outcomeFor(String rawPdf417, String? rawMrz) {
  final pdf417Result = Pdf417Parser().parse(rawPdf417);
  final mrzResult =
      rawMrz == null ? null : MrzTd1Parser(clock: _fixedClock).parse(rawMrz);
  final pdf417Data =
      pdf417Result is Pdf417ParseSuccess ? pdf417Result.data : null;
  final mrzData = mrzResult is MrzParseSuccess ? mrzResult.data : null;
  return ScanOutcome(
    rawPdf417Payload: rawPdf417,
    rawMrzText: rawMrz,
    data: const DniMerger().merge(pdf417Data, mrzData),
    pdf417Error:
        pdf417Result is Pdf417ParseFailure ? pdf417Result.error : null,
    mrzError: mrzResult is MrzParseFailure ? mrzResult.error : null,
  );
}

DateTime _fixedClock() => DateTime(2026, 1, 1);

Future<void> pumpCard(WidgetTester tester, ScanOutcome outcome) async {
  await tester.pumpWidget(MaterialApp(home: DniCardScreen(outcome: outcome)));
}

void main() {
  testWidgets(
      'card renders per-field source badges: PDF417 for names, MRZ for birth date',
      (tester) async {
    await pumpCard(
        tester, outcomeFor(canonicalFixedOffset1997Payload, canonicalTd1Mrz));

    expect(
      find.descendant(
        of: find.byKey(const Key('source-badge-docNumber')),
        matching: find.text('PDF417'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('source-badge-firstSurname')),
        matching: find.text('PDF417'),
      ),
      findsOneWidget,
    );
    // Birth date can only come from the MRZ in this prototype.
    expect(
      find.descendant(
        of: find.byKey(const Key('source-badge-birthDate')),
        matching: find.text('MRZ'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'address and ubigeo rows render empty with pending calibration chips, never guessed',
      (tester) async {
    await pumpCard(
        tester, outcomeFor(canonicalFixedOffset1997Payload, canonicalTd1Mrz));

    for (final field in ['address', 'department', 'province', 'district']) {
      expect(find.byKey(Key('pending-calibration-$field')), findsOneWidget);
    }
    // Assumption encoded: exactly the four address/ubigeo rows are flagged.
    expect(find.text('Pending calibration'), findsNWidgets(4));
  });

  testWidgets(
      'missing fields render a subtle not captured flag instead of a value',
      (tester) async {
    // MRZ skipped: birth date (PDF417 never carries it) stays missing.
    await pumpCard(
        tester, outcomeFor(canonicalFixedOffset1997Payload, null));

    expect(find.byKey(const Key('missing-flag-birthDate')), findsOneWidget);
    expect(find.text('12/03/1995'), findsNothing);
  });

  testWidgets(
      'padded-empty surname renders as not captured without fabricating a value',
      (tester) async {
    // Assumption encoded: a fully space-padded payload field is absent data,
    // so the second-surname row shows the missing flag, not a guess.
    final payload = buildFixedOffset1997Payload(secondSurname: '');
    await pumpCard(tester, outcomeFor(payload, null));

    expect(find.text('Castillo'), findsOneWidget);
    expect(find.text('Ceferino'), findsNothing);
    expect(find.byKey(const Key('missing-flag-secondSurname')), findsOneWidget);
  });

  testWidgets(
      'sex renders with a professional label instead of the raw code (M -> Male)',
      (tester) async {
    await pumpCard(
        tester, outcomeFor(canonicalFixedOffset1997Payload, canonicalTd1Mrz));

    expect(find.text('Male'), findsOneWidget);
  });

  testWidgets(
      'card exposes collapsible raw payload and raw MRZ sections for calibration',
      (tester) async {
    // The full card plus both raw sections exceed the default 800x600
    // test surface; use a taller surface instead of scroll choreography.
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpCard(
        tester, outcomeFor(canonicalFixedOffset1997Payload, canonicalTd1Mrz));

    expect(find.byKey(const Key('raw-payload-section')), findsOneWidget);
    expect(find.byKey(const Key('raw-mrz-section')), findsOneWidget);

    await tester.tap(find.text('Raw payload'));
    await tester.pumpAndSettle();
    expect(find.text(canonicalFixedOffset1997Payload), findsOneWidget);

    await tester.tap(find.text('Raw MRZ text'));
    await tester.pumpAndSettle();
    expect(find.text(canonicalTd1Mrz), findsOneWidget);
  });
}
