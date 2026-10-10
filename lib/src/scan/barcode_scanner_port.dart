/// App-owned boundary over the barcode-scanning plugin.
///
/// Screens depend only on this port (constructor-injected), so widget tests
/// substitute in-memory fakes and never open a real camera.
library;

import 'package:flutter/widgets.dart';

/// Scans a PDF417 barcode and returns its raw decoded payload.
abstract interface class BarcodeScannerPort {
  /// Presents the scanning UI and resolves with the raw decoded PDF417
  /// payload string, or with null when the user cancels the scan.
  ///
  /// The payload is handed to the parser untouched: no preprocessing,
  /// trimming, or encoding assumptions happen at this boundary.
  Future<String?> scanRawPayload(BuildContext context);
}
