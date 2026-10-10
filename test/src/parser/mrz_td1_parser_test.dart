import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_dni/src/model/dni_data.dart';
import 'package:ocr_dni/src/parser/dni_parse_error.dart';
import 'package:ocr_dni/src/parser/mrz_td1_parser.dart';

import '../../fixtures/mrz_fixtures.dart';

void main() {
  // Fixed clock keeps the birth-century inference deterministic in tests.
  final parser = MrzTd1Parser(clock: () => DateTime(2026, 10, 10));

  DniParseError expectFailure(MrzParseResult result) {
    switch (result) {
      case MrzParseFailure(:final error):
        return error;
      case MrzParseSuccess():
        fail('expected a parse failure but got data: ${result.data}');
    }
  }

  test(
    'when parsing a canonical TD1 MRZ then doc number, birth, sex, expiry and '
    'names map by position (birth century inferred against the injected '
    'clock; line-3 names truncate to 30 characters pending calibration)',
    () {
      final result = parser.parse(canonicalTd1Mrz);

      switch (result) {
        case MrzParseSuccess():
          final data = result.data;
          expect(data.docNumber, '45595338');
          expect(data.birthDate, DateTime(1995, 3, 12));
          expect(data.sex, 'M');
          expect(data.expiryDate, DateTime(2027, 4, 25));
          expect(data.firstSurname, 'CASTILLO');
          expect(data.secondSurname, 'CEFERINO');
          expect(data.givenNames, 'NORMAN');
          expect(data.sourceOf(DniField.docNumber), FieldSource.mrz);
          expect(data.sourceOf(DniField.birthDate), FieldSource.mrz);
          expect(data.missingFields, isEmpty);
        case MrzParseFailure():
          fail('expected success but got: ${result.error}');
      }
    },
  );

  test(
    'when the MRZ does not have three lines then a typed malformedMrz error '
    'carries the raw payload',
    () {
      final result = parser.parse(twoLinesOnlyMrz);

      final error = expectFailure(result);
      expect(error.reason, DniParseErrorReason.malformedMrz);
      expect(error.rawPayload, twoLinesOnlyMrz);
    },
  );

  test(
    'when an MRZ line is not 30 characters then a typed malformedMrz error '
    'carries the raw payload',
    () {
      final result = parser.parse(wrongLineLengthMrz);

      final error = expectFailure(result);
      expect(error.reason, DniParseErrorReason.malformedMrz);
      expect(error.rawPayload, wrongLineLengthMrz);
    },
  );

  test(
    'when the MRZ document number is not 8 digits after removing filler then '
    'a typed invalidDocumentNumber error carries the raw payload',
    () {
      final result = parser.parse(invalidDocNumberMrz);

      final error = expectFailure(result);
      expect(error.reason, DniParseErrorReason.invalidDocumentNumber);
      expect(error.rawPayload, invalidDocNumberMrz);
    },
  );

  test(
    'when the MRZ sex position holds a filler character then sex stays null '
    'and is flagged missing',
    () {
      final result = parser.parse(fillerSexMrz);

      switch (result) {
        case MrzParseSuccess():
          expect(result.data.sex, isNull);
          expect(result.data.missingFields, contains(DniField.sex));
        case MrzParseFailure():
          fail('expected success but got: ${result.error}');
      }
    },
  );
}
