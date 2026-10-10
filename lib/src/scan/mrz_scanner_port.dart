/// App-owned boundary over the MRZ text-recognition plugin.
///
/// Screens depend only on this port (constructor-injected), so widget tests
/// substitute in-memory fakes and never open a real camera.
library;

import 'package:flutter/widgets.dart';

/// Recognizes the MRZ text of a document with live text recognition.
abstract interface class MrzScannerPort {
  /// Presents the MRZ scanning UI and resolves with the recognized raw MRZ
  /// text (the recognized lines joined so the TD1 parser can consume them),
  /// or with null when the user skips or cancels the step.
  ///
  /// Birth dates are only obtainable from the MRZ in this prototype, which
  /// is why this step exists even after a successful barcode scan.
  Future<String?> scanRawText(BuildContext context);
}
