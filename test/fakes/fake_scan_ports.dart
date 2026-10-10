/// In-memory scanner port fakes for widget tests.
///
/// The production adapters wrap camera plugins that cannot run in tests, so
/// the flow screens depend only on the app-owned ports and tests inject
/// these fakes with canned raw payloads from the parser fixtures.
library;

import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'package:ocr_dni/src/scan/barcode_scanner_port.dart';
import 'package:ocr_dni/src/scan/mrz_scanner_port.dart';

/// Fake barcode port: returns each queued raw payload in order, then null
/// (the contract the screens treat as "user cancelled").
final class FakeBarcodeScanner implements BarcodeScannerPort {
  FakeBarcodeScanner(List<String?> responses)
      : _responses = Queue.of(responses);

  final Queue<String?> _responses;

  /// How many times the flow asked for a barcode scan.
  int scanCallCount = 0;

  @override
  Future<String?> scanRawPayload(BuildContext context) async {
    scanCallCount++;
    return _responses.isEmpty ? null : _responses.removeFirst();
  }
}

/// Fake MRZ port: returns each queued raw text in order, then null (the
/// contract the screens treat as "user skipped the MRZ step").
final class FakeMrzScanner implements MrzScannerPort {
  FakeMrzScanner(List<String?> responses) : _responses = Queue.of(responses);

  final Queue<String?> _responses;

  /// How many times the flow asked for an MRZ scan.
  int scanCallCount = 0;

  @override
  Future<String?> scanRawText(BuildContext context) async {
    scanCallCount++;
    return _responses.isEmpty ? null : _responses.removeFirst();
  }
}
