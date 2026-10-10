/// Outcome of one complete scan flow (barcode step, then MRZ step).
///
/// Carries everything the result screen needs: the merged [DniData] when at
/// least one source parsed, the untouched raw payloads for the collapsible
/// calibration sections, and the typed parse errors for the failure state.
/// Nothing here is ever guessed: absent fields stay absent in [data].
library;

import '../model/dni_data.dart';
import '../parser/dni_parse_error.dart';

/// Result of a scan flow run.
///
/// [data] is null when neither the barcode nor the MRZ payload parsed;
/// the result screen then renders the parse-error state.
final class ScanOutcome {
  const ScanOutcome({
    required this.rawPdf417Payload,
    this.data,
    this.rawMrzText,
    this.pdf417Error,
    this.mrzError,
  });

  /// Untouched raw payload decoded from the PDF417 barcode (always present:
  /// the flow only reaches a result screen when the barcode step completed).
  final String rawPdf417Payload;

  /// Merged data when at least one source parsed, otherwise null.
  final DniData? data;

  /// Untouched raw MRZ text when the MRZ step ran and recognized something;
  /// null when the step was skipped or cancelled.
  final String? rawMrzText;

  /// Typed error when the barcode payload failed to parse.
  final DniParseError? pdf417Error;

  /// Typed error when an MRZ text was captured but failed to parse.
  final DniParseError? mrzError;

  bool get succeeded => data != null;
}
