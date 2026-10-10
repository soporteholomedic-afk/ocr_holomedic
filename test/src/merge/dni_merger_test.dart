import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_dni/src/merge/dni_merger.dart';
import 'package:ocr_dni/src/model/dni_data.dart';
import 'package:ocr_dni/src/parser/mrz_td1_parser.dart';
import 'package:ocr_dni/src/parser/pdf417_parser.dart';

import '../../fixtures/dni_payload_fixtures.dart';
import '../../fixtures/mrz_fixtures.dart';

void main() {
  const merger = DniMerger();
  final pdf417Parser = Pdf417Parser();
  final mrzParser = MrzTd1Parser(clock: () => DateTime(2026, 10, 10));

  DniData parsePdf417Ok() =>
      (pdf417Parser.parse(canonicalFixedOffset1997Payload)
          as Pdf417ParseSuccess)
          .data;

  DniData parseMrzOk() =>
      (mrzParser.parse(canonicalTd1Mrz) as MrzParseSuccess).data;

  test(
    'when merging PDF417 and MRZ results then birth date comes from MRZ and '
    'surnames are preferred from PDF417',
    () {
      final merged = merger.merge(parsePdf417Ok(), parseMrzOk());

      expect(merged, isNotNull);
      final data = merged!;
      expect(data.birthDate, DateTime(1995, 3, 12));
      expect(data.sourceOf(DniField.birthDate), FieldSource.mrz);
      // PDF417 casing wins over the uppercase MRZ surnames.
      expect(data.firstSurname, 'Castillo');
      expect(data.sourceOf(DniField.firstSurname), FieldSource.pdf417);
      expect(data.secondSurname, 'Ceferino');
      expect(data.sourceOf(DniField.secondSurname), FieldSource.pdf417);
      // Full PDF417 given names beat the truncated MRZ line.
      expect(data.givenNames, 'Norman Valery');
      expect(data.sourceOf(DniField.givenNames), FieldSource.pdf417);
      expect(data.docNumber, '45595338');
      expect(data.sourceOf(DniField.docNumber), FieldSource.pdf417);
      expect(data.sex, 'M');
      // MRZ expiry preferred: ICAO semantics are confirmed while the PDF417
      // date mapping is a hypothesis.
      expect(data.expiryDate, DateTime(2027, 4, 25));
      expect(data.sourceOf(DniField.expiryDate), FieldSource.mrz);
      expect(data.missingFields, isEmpty);
    },
  );

  test(
    'when merging with only an MRZ result then fields are filled and sourced '
    'from mrz',
    () {
      final merged = merger.merge(null, parseMrzOk());

      expect(merged, isNotNull);
      final data = merged!;
      expect(data.docNumber, '45595338');
      expect(data.sourceOf(DniField.docNumber), FieldSource.mrz);
      expect(data.birthDate, DateTime(1995, 3, 12));
      expect(data.sourceOf(DniField.birthDate), FieldSource.mrz);
      expect(data.firstSurname, 'CASTILLO');
      expect(data.sourceOf(DniField.firstSurname), FieldSource.mrz);
      expect(data.givenNames, 'NORMAN');
      expect(data.sourceOf(DniField.givenNames), FieldSource.mrz);
      expect(data.missingFields, isEmpty);
    },
  );

  test(
    'when merging with only a PDF417 result then birth date stays missing and '
    'flagged (PDF417 never provides birth)',
    () {
      final merged = merger.merge(parsePdf417Ok(), null);

      expect(merged, isNotNull);
      final data = merged!;
      expect(data.birthDate, isNull);
      expect(data.missingFields, {DniField.birthDate});
      expect(data.sourceOf(DniField.docNumber), FieldSource.pdf417);
      expect(data.expiryDate, DateTime(2027, 4, 25));
      expect(data.sourceOf(DniField.expiryDate), FieldSource.pdf417);
    },
  );

  test('when both results are null then merge returns null', () {
    expect(merger.merge(null, null), isNull);
  });

  test(
    'when merging then address and ubigeo fields stay null pending '
    'real-card calibration',
    () {
      final merged = merger.merge(parsePdf417Ok(), parseMrzOk());

      final data = merged!;
      expect(data.address, isNull);
      expect(data.department, isNull);
      expect(data.province, isNull);
      expect(data.district, isNull);
      expect(DniData.addressFieldsPendingCalibration, isTrue);
    },
  );
}
