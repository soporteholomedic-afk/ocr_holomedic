/// Parser for the MRZ TD1 block of the Peruvian DNI.
///
/// TD1 shape (ICAO 9303): three lines of 30 characters.
/// - Line 1: document code (2) + issuing state (3) + document number (9) +
///   check digit (1) + optional data (15).
/// - Line 2: birth date yyMMdd (6) + check digit (1) + sex M/F/< (1) +
///   expiry yyMMdd (6) + check digit (1) + optional data (15).
/// - Line 3: names, `SURNAME<SURNAME<<GIVEN<NAMES` padded with `<`.
///
/// Check digits are not validated in this prototype; unparsable or missing
/// values stay null and are flagged missing rather than guessed.
library;

import '../model/dni_data.dart';
import 'date_parsing.dart';
import 'dni_parse_error.dart';

/// Result of parsing an MRZ TD1 payload.
sealed class MrzParseResult {
  const MrzParseResult();
}

/// Successful parse; [data] carries the fields the MRZ documents.
final class MrzParseSuccess extends MrzParseResult {
  const MrzParseSuccess(this.data);

  final DniData data;
}

/// Failed parse; [error] carries the reason and the untouched raw payload.
final class MrzParseFailure extends MrzParseResult {
  const MrzParseFailure(this.error);

  final DniParseError error;
}

/// Parses raw MRZ TD1 payloads into [DniData] or a typed [MrzParseFailure].
final class MrzTd1Parser {
  /// Creates a parser. [clock] provides the reference year used to resolve
  /// the birth-date century (yy dates that land in the future belong to the
  /// 1900s); inject a fixed clock in tests for determinism.
  MrzTd1Parser({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Parses [rawPayload] untouched (only line splitting; check digits are
  /// not validated in this prototype).
  MrzParseResult parse(String rawPayload) {
    final lines = rawPayload.split(RegExp(r'\r?\n'));
    if (lines.length != 3) {
      return _malformed(rawPayload,
          'TD1 MRZ must have exactly 3 lines, got ${lines.length}.');
    }
    final badLine = lines.indexWhere((line) => line.length != 30);
    if (badLine >= 0) {
      return _malformed(
        rawPayload,
        'TD1 MRZ line ${badLine + 1} has ${lines[badLine].length} '
        'characters; expected 30.',
      );
    }

    final docNumber = lines[0]
        .substring(5, 14)
        .replaceAll('<', '')
        .trim();
    if (!RegExp(r'^\d{8}$').hasMatch(docNumber)) {
      return MrzParseFailure(DniParseError(
        reason: DniParseErrorReason.invalidDocumentNumber,
        rawPayload: rawPayload,
        message: 'MRZ document number "$docNumber" is not exactly 8 digits.',
      ));
    }

    final referenceYear = _clock().year;
    final names = _parseNameLine(lines[2]);
    return MrzParseSuccess(
      DniData.fromMrz(
        docNumber: docNumber,
        birthDate: parseBirthYymmdd(lines[1].substring(0, 6),
            referenceYear: referenceYear),
        sex: switch (lines[1].substring(7, 8)) {
          'M' => 'M',
          'F' => 'F',
          _ => null,
        },
        expiryDate: parseExpiryYymmdd(lines[1].substring(8, 14)),
        firstSurname: names.firstSurname,
        secondSurname: names.secondSurname,
        givenNames: names.givenNames,
      ),
    );
  }

  MrzParseFailure _malformed(String rawPayload, String message) {
    return MrzParseFailure(DniParseError(
      reason: DniParseErrorReason.malformedMrz,
      rawPayload: rawPayload,
      message: message,
    ));
  }

  /// Parses TD1 line 3 (`SURNAME<SURNAME<<GIVEN<NAMES` padded with `<`).
  ///
  /// Calibration assumptions: surnames sit before the first `<<` and `<`
  /// separates at most two surnames (paternal, maternal); everything after
  /// the first `<<` is the given-name list.
  ({String? firstSurname, String? secondSurname, String? givenNames})
      _parseNameLine(String line) {
    final trimmed = line.replaceFirst(RegExp(r'<+$'), '');
    final separator = trimmed.indexOf('<<');
    final surnameSection =
        separator >= 0 ? trimmed.substring(0, separator) : trimmed;
    final givenSection =
        separator >= 0 ? trimmed.substring(separator + 2) : null;

    final surnameTokens = surnameSection.split('<');
    return (
      firstSurname: _cleanName(surnameTokens.isNotEmpty
          ? surnameTokens.first
          : null),
      secondSurname:
          surnameTokens.length > 1 ? _cleanName(surnameTokens[1]) : null,
      givenNames:
          _cleanName(givenSection?.replaceAll('<', ' ')),
    );
  }

  /// Emptied or filler-only fragments yield null (flagged missing).
  String? _cleanName(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }
}
