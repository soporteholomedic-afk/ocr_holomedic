/// Production MRZ adapter: `camera` preview frames fed into the ML Kit
/// latin [TextRecognizer].
///
/// The adapter pushes a full-screen route, recognizes text live, extracts a
/// candidate TD1 block (three consecutive 30-character MRZ lines) and
/// resolves the port call with those lines joined by newlines — the raw-text
/// contract the existing `MrzTd1Parser` consumes. All plugin interaction
/// stays inside this file; screens depend only on [MrzScannerPort].
library;

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'mrz_scanner_port.dart';
import '../../ui/widgets/scan_guide_overlay.dart';

/// Guide window for the MRZ step: a wide strip placed in the lower third
/// of the preview, where the TD1 MRZ sits on the card. Visual assumption
/// pending on-device calibration.
const double _mrzGuideAspectRatio = 3.4;
const Alignment _mrzGuideAlignment = Alignment(0, 0.6);

/// Recognizes the MRZ lines of a document with live text recognition.
final class MlkitMrzAdapter implements MrzScannerPort {
  @override
  Future<String?> scanRawText(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const MrzScanScreen(),
      ),
    );
  }
}

/// Full-screen MRZ recognition page.
///
/// Pops with the recognized TD1 block when three consecutive 30-character
/// MRZ lines are found, or with null when the user skips the step.
///
/// Prototype limitation: frames are analyzed in the device's current
/// orientation only; sensor-orientation compensation below follows the
/// standard ML Kit recipe for the `camera` plugin.
class MrzScanScreen extends StatefulWidget {
  const MrzScanScreen({super.key});

  @override
  State<MrzScanScreen> createState() => _MrzScanScreenState();
}

class _MrzScanScreenState extends State<MrzScanScreen> {
  static final RegExp _mrzLinePattern = RegExp(r'^[A-Z0-9<]{30}$');

  CameraController? _controller;
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Frames are dropped while a recognition pass is in flight.
  bool _isProcessing = false;
  bool _didPop = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _didPop = true;
    _recognizer.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
      });
      await controller.startImageStream(_onFrame);
    } catch (error) {
      if (mounted) {
        setState(() => _statusText = 'Camera unavailable: $error');
      }
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_isProcessing || _didPop) return;
    _isProcessing = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;
      final recognized = await _recognizer.processImage(inputImage);
      final mrzBlock = _extractTd1Block(recognized);
      if (mrzBlock != null) {
        _pop(mrzBlock);
      }
    } catch (_) {
      // Recognition passes are opportunistic in a prototype: a failed frame
      // is simply dropped and the next one is analyzed.
    } finally {
      _isProcessing = false;
    }
  }

  /// Converts a camera frame to an ML Kit [InputImage].
  ///
  /// Android streams YUV_420_888, converted here to NV21 (Y plane followed
  /// by interleaved V/U planes, honoring row strides). iOS streams BGRA,
  /// which ML Kit accepts directly.
  InputImage? _toInputImage(CameraImage image) {
    if (_controller == null) return null;
    final rotation = _rotationFor(_controller!.description);

    if (image.format.group == ImageFormatGroup.bgra8888) {
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    if (image.format.group == ImageFormatGroup.yuv420) {
      return InputImage.fromBytes(
        bytes: _yuv420ToNv21(image),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    }
    return null;
  }

  /// Standard ML Kit sensor-orientation compensation for the `camera`
  /// plugin: back sensors rotate by the sensor angle minus the device
  /// rotation; front sensors add it.
  InputImageRotation _rotationFor(CameraDescription camera) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return InputImageRotation.rotation0deg;
    }
    const orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    var compensation = orientations[_controller!.value.deviceOrientation] ?? 0;
    compensation = camera.lensDirection == CameraLensDirection.front
        ? (camera.sensorOrientation + compensation) % 360
        : (camera.sensorOrientation - compensation + 360) % 360;
    return InputImageRotationValue.fromRawValue(compensation) ??
        InputImageRotation.rotation0deg;
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height + (width * height) ~/ 2);
    var index = 0;
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        nv21[index++] = yPlane.bytes[row * yPlane.bytesPerRow + col];
      }
    }
    final chromaWidth = width ~/ 2;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    for (var row = 0; row < height ~/ 2; row++) {
      for (var col = 0; col < chromaWidth; col++) {
        nv21[index++] =
            vPlane.bytes[row * vPlane.bytesPerRow + col * vPixelStride];
        nv21[index++] =
            uPlane.bytes[row * uPlane.bytesPerRow + col * uPixelStride];
      }
    }
    return nv21;
  }

  /// Finds the first run of three consecutive recognized lines that have the
  /// TD1 MRZ shape (exactly 30 characters of the MRZ charset). Recognition
  /// noise elsewhere on the card is ignored; the parser remains the sole
  /// authority on whether the block is valid.
  String? _extractTd1Block(RecognizedText recognized) {
    final lines = [
      for (final block in recognized.blocks)
        for (final line in block.lines) line.text.trim(),
    ];
    for (var i = 0; i + 2 < lines.length; i++) {
      if (_mrzLinePattern.hasMatch(lines[i]) &&
          _mrzLinePattern.hasMatch(lines[i + 1]) &&
          _mrzLinePattern.hasMatch(lines[i + 2])) {
        return lines.sublist(i, i + 3).join('\n');
      }
    }
    return null;
  }

  void _pop(String? value) {
    if (_didPop || !mounted) return;
    _didPop = true;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan MRZ')),
      body: Stack(
        children: [
          if (controller != null && controller.value.isInitialized)
            CameraPreview(controller)
          else
            Center(child: Text(_statusText ?? 'Starting camera…')),
          // Transparent to hit testing, so the Skip button keeps working.
          const ScanGuideOverlay(
            key: Key('mrz-scan-guide'),
            aspectRatio: _mrzGuideAspectRatio,
            alignment: _mrzGuideAlignment,
            hint: 'Align the 3 text lines at the bottom of the card',
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.tonal(
                    onPressed: () => _pop(null),
                    child: const Text('Skip'),
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
