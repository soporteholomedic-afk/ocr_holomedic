/// Parser for the PDF417 barcode payload of the Peruvian DNI.
///
/// RENIEC publishes no official payload specification, so every layout below
/// is a hypothesis pending real-card calibration (see
/// `.agents/skills/dni-pdf417-parsing/references/payload-layout-notes.md`):
///
/// 1. 1997 adult DNI, fixed byte offsets (documented community layout).
/// 2. Delimited payload with `|` or `@` separators (unverified format from
///    early planning, kept as a hypothesis branch).
///
/// The layout is detected before any field is mapped; unknown layouts and
/// field-count mismatches surface a typed error carrying the raw payload
/// instead of guessed values.
library;

import '../model/dni_data.dart';
import 'date_parsing.dart';
import 'dni_parse_error.dart';

/// Result of parsing a PDF417 payload.
sealed class Pdf417ParseResult {
  const Pdf417ParseResult();
}

/// Successful parse; [data] carries the fields the layout documents.
final class Pdf417ParseSuccess extends Pdf417ParseResult {
  const Pdf417ParseSuccess(this.data);

  final DniData data;
}

/// Failed parse; [error] carries the reason and the untouched raw payload.
final class Pdf417ParseFailure extends Pdf417ParseResult {
  const Pdf417ParseFailure(this.error);

  final DniParseError error;
}

/// Parses raw PDF417 payloads into [DniData] or a typed [Pdf417ParseFailure].
final class Pdf417Parser {
  /// Minimum length of the 1997 fixed-offset layout (bytes 0-471).
  static const int _fixedLayoutMinLength = 472;

  /// Token count of the delimited hypothesis:
  /// `DNI|docNumber|firstSurname|secondSurname|givenNames|sex|date`.
  static const int _delimitedTokenCount = 7;

  static final RegExp _eightDigits = RegExp(r'^\d{8}$');

  /// Parses [rawPayload] untouched (no preprocessing).
  ///
  /// Layout detection happens before any field is mapped: fixed-offset 1997
  /// first, then the delimited hypothesis, then a typed error carrying the
  /// raw payload.
  Pdf417ParseResult parse(String rawPayload) {
    if (_matchesFixedOffsetLayout(rawPayload)) {
      return Pdf417ParseSuccess(_mapFixedOffset(rawPayload));
    }
    if (rawPayload.contains('|') || rawPayload.contains('@')) {
      return _parseDelimited(rawPayload);
    }
    if (rawPayload.length < _fixedLayoutMinLength) {
      return Pdf417ParseFailure(DniParseError(
        reason: DniParseErrorReason.payloadTooShort,
        rawPayload: rawPayload,
        message: 'Payload has ${rawPayload.length} characters; the 1997 '
            'fixed-offset layout requires at least $_fixedLayoutMinLength.',
      ));
    }
    return _parseUnknown(rawPayload);
  }

  /// Layout signature of the 1997 fixed-offset hypothesis: long enough, no
  /// delimited separators, and an 8-digit document number at bytes 2-9.
  bool _matchesFixedOffsetLayout(String payload) {
    if (payload.length < _fixedLayoutMinLength) return false;
    if (payload.contains('|') || payload.contains('@')) return false;
    return _eightDigits.hasMatch(payload.substring(2, 10));
  }

  /// Maps the documented byte table:
  /// 0-1 NI, 2-9 doc number, 10-49 first surname, 50-89 second surname,
  /// 90-124 given names, 125 sex (1=M / 2=F), 448-455 date yyyyMMdd.
  ///
  /// The date at 448-455 is labeled only as "Fecha" in the community source
  /// and its example is a future date, so it maps to [DniData.expiryDate];
  /// the PDF417 payload never yields a birth date (pending calibration).
  DniData _mapFixedOffset(String payload) {
    return DniData.fromPdf417(
      docNumber: payload.substring(2, 10),
      firstSurname: _cleanTextField(payload.substring(10, 50)),
      secondSurname: _cleanTextField(payload.substring(50, 90)),
      givenNames: _cleanTextField(payload.substring(90, 125)),
      sex: _mapSex(payload.substring(125, 126)),
      expiryDate: parseYmd(payload.substring(448, 456)),
    );
  }

  /// Maps the delimited hypothesis by token index:
  /// 0 header `DNI`, 1 doc number (8 digits), 2 first surname,
  /// 3 second surname, 4 given names, 5 sex (1/2), 6 date yyyyMMdd
  /// (mapped to expiry under the same pending-calibration assumption).
  Pdf417ParseResult _parseDelimited(String rawPayload) {
    final separator = rawPayload.contains('|') ? '|' : '@';
    final tokens = rawPayload.split(separator);
    if (tokens.length != _delimitedTokenCount) {
      return Pdf417ParseFailure(DniParseError(
        reason: DniParseErrorReason.fieldCountMismatch,
        rawPayload: rawPayload,
        message: 'Delimited payload has ${tokens.length} tokens; the '
            'hypothesis defines $_delimitedTokenCount.',
      ));
    }
    if (tokens[0] != 'DNI') {
      return _parseUnknown(rawPayload);
    }
    if (!_eightDigits.hasMatch(tokens[1])) {
      return Pdf417ParseFailure(DniParseError(
        reason: DniParseErrorReason.invalidDocumentNumber,
        rawPayload: rawPayload,
        message: 'Document number "${tokens[1]}" is not exactly 8 digits.',
      ));
    }
    return Pdf417ParseSuccess(
      DniData.fromPdf417(
        docNumber: tokens[1],
        firstSurname: _cleanTextField(tokens[2]),
        secondSurname: _cleanTextField(tokens[3]),
        givenNames: _cleanTextField(tokens[4]),
        sex: _mapSex(tokens[5]),
        expiryDate: parseYmd(tokens[6]),
      ),
    );
  }

  Pdf417ParseFailure _parseUnknown(String rawPayload) {
    return Pdf417ParseFailure(
      DniParseError(
        reason: DniParseErrorReason.unknownLayout,
        rawPayload: rawPayload,
        message: 'Payload matches neither the 1997 fixed-offset layout nor '
            'the delimited hypothesis.',
      ),
    );
  }

  /// Trims space padding; a fully padded field yields null (flagged missing).
  String? _cleanTextField(String raw) {
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  /// 1997 sex encoding: '1' = M, '2' = F; anything else stays missing.
  String? _mapSex(String raw) => switch (raw) {
        '1' => 'M',
        '2' => 'F',
        _ => null,
      };
}
