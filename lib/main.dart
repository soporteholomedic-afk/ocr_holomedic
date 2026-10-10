/// Application root of the DNI scanner prototype.
///
/// Wires the app theme (light/dark following the system) and the
/// production scanner adapters. Tests inject in-memory port fakes through
/// the same constructor so no camera is ever opened in a test.
library;

import 'package:flutter/material.dart';

import 'src/scan/barcode_scanner_port.dart';
import 'src/scan/mlkit_mrz_adapter.dart';
import 'src/scan/mobile_scanner_barcode_adapter.dart';
import 'src/scan/mrz_scanner_port.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const OcrDniApp());
}

class OcrDniApp extends StatelessWidget {
  const OcrDniApp({
    super.key,
    this.barcodeScanner,
    this.mrzScanner,
    this.mrzClock,
  });

  /// Production default: [MobileScannerBarcodeAdapter]. Tests inject fakes.
  final BarcodeScannerPort? barcodeScanner;

  /// Production default: [MlkitMrzAdapter]. Tests inject fakes.
  final MrzScannerPort? mrzScanner;

  /// Injectable clock for deterministic MRZ century resolution in tests.
  final DateTime Function()? mrzClock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DNI Scanner',
      theme: appThemeLight,
      darkTheme: appThemeDark,
      themeMode: ThemeMode.system,
      home: HomeScreen(
        barcodeScanner: barcodeScanner ?? MobileScannerBarcodeAdapter(),
        mrzScanner: mrzScanner ?? MlkitMrzAdapter(),
        mrzClock: mrzClock,
      ),
    );
  }
}
