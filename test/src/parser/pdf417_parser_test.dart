import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_dni/src/model/dni_data.dart';
import 'package:ocr_dni/src/parser/dni_parse_error.dart';
import 'package:ocr_dni/src/parser/pdf417_parser.dart';

import '../../fixtures/dni_payload_fixtures.dart';

void main() {
  final parser = Pdf417Parser();

  DniParseError expectFailure(Pdf417ParseResult result) {
    switch (result) {
      case Pdf417ParseFailure(:final error):
        return error;
      case Pdf417ParseSuccess():
        fail('expected a parse failure but got data: ${result.data}');
    }
  }

  test(
    'when parsing the canonical 1997 fixed-offset payload then fields map per '
    'the documented byte table (bytes 448-455 mapped to expiry pending '
    'calibration)',
    () {
      final result = parser.parse(canonicalFixedOffset1997Payload);

      switch (result) {
        case Pdf417ParseSuccess():
          final data = result.data;
          expect(data.docNumber, '45595338');
          expect(data.firstSurname, 'Castillo');
          expect(data.secondSurname, 'Ceferino');
          expect(data.givenNames, 'Norman Valery');
          expect(data.sex, 'M');
          expect(data.expiryDate, DateTime(2027, 4, 25));
          expect(data.birthDate, isNull);
          expect(data.missingFields, contains(DniField.birthDate));
          expect(data.sourceOf(DniField.docNumber), FieldSource.pdf417);
          expect(data.sourceOf(DniField.expiryDate), FieldSource.pdf417);
          expect(data.address, isNull);
        case Pdf417ParseFailure():
          fail('expected success but got: ${result.error}');
      }
    },
  );

  test(
    'when the fixed-offset payload encodes sex 2 then sex maps to F '
    '(1997 sex encoding: 1=M, 2=F)',
    () {
      final payload = buildFixedOffset1997Payload(sex: '2');

      final result = parser.parse(payload);

      switch (result) {
        case Pdf417ParseSuccess():
          expect(result.data.sex, 'F');
        case Pdf417ParseFailure():
          fail('expected success but got: ${result.error}');
      }
    },
  );

  test(
    'when the fixed-offset date at bytes 448-455 is in the past then it still '
    'maps to expiryDate and never to birthDate (date semantics pending '
    'calibration)',
    () {
      final payload = buildFixedOffset1997Payload(dateAtOffset448: '19950312');

      final result = parser.parse(payload);

      switch (result) {
        case Pdf417ParseSuccess():
          expect(result.data.expiryDate, DateTime(1995, 3, 12));
          expect(result.data.birthDate, isNull);
          expect(result.data.missingFields, contains(DniField.birthDate));
        case Pdf417ParseFailure():
          fail('expected success but got: ${result.error}');
      }
    },
  );

  test(
    'when parsing a pipe-delimited payload then fields map by token index '
    '(delimited layout is an unverified hypothesis)',
    () {
      final result = parser.parse(delimitedPipePayload);

      switch (result) {
        case Pdf417ParseSuccess():
          final data = result.data;
          expect(data.docNumber, '45595338');
          expect(data.firstSurname, 'Castillo');
          expect(data.secondSurname, 'Ceferino');
          expect(data.givenNames, 'Norman Valery');
          expect(data.sex, 'M');
          expect(data.expiryDate, DateTime(2027, 4, 25));
          expect(data.birthDate, isNull);
        case Pdf417ParseFailure():
          fail('expected success but got: ${result.error}');
      }
    },
  );

  test(
    'when parsing an at-delimited payload then fields map by token index '
    '(delimited layout is an unverified hypothesis)',
    () {
      final result = parser.parse(delimitedAtPayload);

      switch (result) {
        case Pdf417ParseSuccess():
          final data = result.data;
          expect(data.docNumber, '45595338');
          expect(data.firstSurname, 'Castillo');
          expect(data.secondSurname, 'Ceferino');
          expect(data.givenNames, 'Norman Valery');
          expect(data.sex, 'M');
          expect(data.expiryDate, DateTime(2027, 4, 25));
        case Pdf417ParseFailure():
          fail('expected success but got: ${result.error}');
      }
    },
  );

  test(
    'when the payload matches no documented layout then a typed '
    'unknownLayout error carries the raw payload',
    () {
      final result = parser.parse(unknownLayoutPayload);

      final error = expectFailure(result);
      expect(error.reason, DniParseErrorReason.unknownLayout);
      expect(error.rawPayload, unknownLayoutPayload);
    },
  );

  test(
    'when the payload is shorter than the 472-character fixed-offset layout '
    'then a typed payloadTooShort error carries the raw payload',
    () {
      final result = parser.parse(shortTruncatedPayload);

      final error = expectFailure(result);
      expect(error.reason, DniParseErrorReason.payloadTooShort);
      expect(error.rawPayload, shortTruncatedPayload);
    },
  );

  test(
    'when a delimited payload has the wrong token count then a typed '
    'fieldCountMismatch error carries the raw payload',
    () {
      final result = parser.parse(delimitedWrongTokenCountPayload);

      final error = expectFailure(result);
      expect(error.reason, DniParseErrorReason.fieldCountMismatch);
      expect(error.rawPayload, delimitedWrongTokenCountPayload);
    },
  );

  test(
    'when a delimited payload carries a document number that is not 8 digits '
    'then a typed invalidDocumentNumber error carries the raw payload',
    () {
      final result = parser.parse(delimitedInvalidDocNumberPayload);

      final error = expectFailure(result);
      expect(error.reason, DniParseErrorReason.invalidDocumentNumber);
      expect(error.rawPayload, delimitedInvalidDocNumberPayload);
    },
  );
}
