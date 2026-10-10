/// Production barcode adapter around `mobile_scanner`, restricted to PDF417.
///
/// The adapter pushes a full-screen scanning route and resolves the port
/// call with the raw decoded payload (or null on cancel). All plugin
/// interaction stays inside this file; screens depend only on
/// [BarcodeScannerPort].
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'barcode_scanner_port.dart';
import '../../ui/widgets/scan_guide_overlay.dart';

/// Guide window shape for the barcode step: a wide horizontal strip,
/// centered (PDF417 is a wide barcode). Visual assumption pending
/// on-device calibration.
const double _pdf417GuideAspectRatio = 4.0;

/// Scans a PDF417 barcode with the device camera.
final class MobileScannerBarcodeAdapter implements BarcodeScannerPort {
  @override
  Future<String?> scanRawPayload(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const BarcodeScanScreen(),
      ),
    );
  }
}

/// Full-screen PDF417 scanning page.
///
/// Pops with the raw decoded payload string when a PDF417 barcode is read,
/// or with null when the user cancels.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.pdf417],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _didPop = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      if (barcode.format != BarcodeFormat.pdf417) {
        continue;
      }
      final String? payload = _extractPayload(barcode);
      if (payload != null && payload.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[scan] pdf417 payload captured (${payload.length} chars, '
            'rawValue=${barcode.rawValue != null ? 'text' : 'bytes'})',
          );
        }
        _pop(payload);
        return;
      }
    }
  }

  /// Extracts the raw payload from a detected PDF417 barcode.
  ///
  /// The Peruvian DNI payload embeds binary biometric data after the text
  /// header, so ML Kit often fails to decode the whole payload as text and
  /// reports `rawValue` as null. In that case the raw bytes are decoded
  /// with Latin-1, which maps every byte 1:1 and preserves the character
  /// positions the fixed-offset parser relies on. Never trim the result:
  /// leading or trailing edits would shift the fixed offsets.
  String? _extractPayload(Barcode barcode) {
    final String? text = barcode.rawValue;
    if (text != null && text.isNotEmpty) {
      return text;
    }
    final Uint8List? bytes = switch (barcode.rawDecodedBytes) {
      final DecodedBarcodeBytes decoded => decoded.bytes,
      // Legacy fallback for plugin paths that never populate rawDecodedBytes.
      // ignore: deprecated_member_use
      _ => barcode.rawBytes,
    };
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return latin1.decode(bytes);
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) {
        setState(() => _torchOn = !_torchOn);
      }
    } catch (e) {
      debugPrint('[scan] torch toggle failed: $e');
    }
  }

  void _pop(String? value) {
    if (_didPop || !mounted) return;
    _didPop = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Camera unavailable: ${error.errorCode.name}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Transparent to hit testing, so the Cancel button keeps working.
          const ScanGuideOverlay(
            key: Key('barcode-scan-guide'),
            aspectRatio: _pdf417GuideAspectRatio,
            hint: 'Align the barcode on the back of the DNI inside the frame',
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: _toggleTorch,
                        icon: Icon(
                          _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                        ),
                        tooltip: 'Toggle torch',
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: () => _pop(null),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
