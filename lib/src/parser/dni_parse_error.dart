/// Typed parse errors surfaced by the DNI parsers.
///
/// Parsers never throw across their API boundary: any layout or field-count
/// problem is returned as a [DniParseError] carrying the untouched raw
/// payload so callers can log it and request a calibration capture.
library;

/// Why a payload could not be parsed.
enum DniParseErrorReason {
  /// Payload matches no documented layout hypothesis.
  unknownLayout,

  /// Payload is shorter than the minimum length of the documented layouts.
  payloadTooShort,

  /// Delimited payload does not carry the expected token count.
  fieldCountMismatch,

  /// Document number is not exactly 8 digits.
  invalidDocumentNumber,

  /// MRZ payload does not have the TD1 shape (three 30-character lines).
  malformedMrz,
}

/// A typed parse failure carrying the raw payload.
final class DniParseError {
  const DniParseError({
    required this.reason,
    required this.rawPayload,
    required this.message,
  });

  final DniParseErrorReason reason;

  /// Untouched raw payload, kept for diagnostics and calibration captures.
  final String rawPayload;

  final String message;

  @override
  String toString() => 'DniParseError(reason: $reason, message: $message)';
}
