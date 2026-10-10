/// Coordinates one scan flow run: barcode step, MRZ step, parse and merge.
///
/// The coordinator owns no UI: it drives the injected ports (which present
/// their own camera screens), runs the pure parsers and merger, and returns
/// a [ScanOutcome] for the caller to present.
library;

import 'package:flutter/widgets.dart';

import '../src/merge/dni_merger.dart';
import '../src/scan/barcode_scanner_port.dart';
import '../src/scan/mrz_scanner_port.dart';
import '../src/scan/scan_outcome.dart';
import '../src/parser/mrz_td1_parser.dart';
import '../src/parser/pdf417_parser.dart';

final class ScanFlowCoordinator {
  ScanFlowCoordinator({
    required this.barcodeScanner,
    required this.mrzScanner,
    DateTime Function()? mrzClock,
  })  : _pdf417Parser = Pdf417Parser(),
        _mrzParser = MrzTd1Parser(clock: mrzClock),
        _merger = const DniMerger();

  final BarcodeScannerPort barcodeScanner;
  final MrzScannerPort mrzScanner;
  final Pdf417Parser _pdf417Parser;
  final MrzTd1Parser _mrzParser;
  final DniMerger _merger;

  /// Runs the full flow. Returns null when the user cancelled the barcode
  /// step (no result screen is produced for a cancelled run).
  Future<ScanOutcome?> run(BuildContext context) async {
    final rawPdf417 = await barcodeScanner.scanRawPayload(context);
    if (rawPdf417 == null || !context.mounted) return null;

    // The MRZ step always runs after a completed barcode scan: the birth
    // date can only come from the MRZ in this prototype.
    final rawMrz = await mrzScanner.scanRawText(context);
    if (!context.mounted) return null;

    return buildOutcome(rawPdf417, rawMrz);
  }

  /// Parses both payloads and merges them into a single outcome.
  ///
  /// A result with data exists as soon as one source parsed; the typed
  /// errors are carried alongside for diagnostics. Fields no source
  /// provided stay missing — nothing is guessed.
  ScanOutcome buildOutcome(String rawPdf417, String? rawMrz) {
    final pdf417Result = _pdf417Parser.parse(rawPdf417);
    final mrzResult =
        rawMrz == null ? null : _mrzParser.parse(rawMrz);

    final pdf417Data =
        pdf417Result is Pdf417ParseSuccess ? pdf417Result.data : null;
    final pdf417Error =
        pdf417Result is Pdf417ParseFailure ? pdf417Result.error : null;
    final mrzData = mrzResult is MrzParseSuccess ? mrzResult.data : null;
    final mrzError =
        mrzResult is MrzParseFailure ? mrzResult.error : null;

    return ScanOutcome(
      rawPdf417Payload: rawPdf417,
      rawMrzText: rawMrz,
      data: _merger.merge(pdf417Data, mrzData),
      pdf417Error: pdf417Error,
      mrzError: mrzError,
    );
  }
}
