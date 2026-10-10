/// Home screen of the DNI scanner: entry point of the scan flow.
///
/// Shows the primary "Scan DNI" action and, once a run completed, a summary
/// of the last result. The scanner plugins are never touched directly —
/// everything goes through the injected ports.
library;

import 'package:flutter/material.dart';

import '../src/model/dni_data.dart';
import '../src/scan/barcode_scanner_port.dart';
import '../src/scan/mrz_scanner_port.dart';
import '../src/scan/scan_outcome.dart';
import 'dni_card_screen.dart';
import 'scan_flow.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.barcodeScanner,
    required this.mrzScanner,
    this.mrzClock,
  });

  final BarcodeScannerPort barcodeScanner;
  final MrzScannerPort mrzScanner;

  /// Injectable clock for the MRZ birth-date century resolution
  /// (deterministic in tests).
  final DateTime Function()? mrzClock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScanFlowCoordinator _coordinator = ScanFlowCoordinator(
    barcodeScanner: widget.barcodeScanner,
    mrzScanner: widget.mrzScanner,
    mrzClock: widget.mrzClock,
  );

  ScanOutcome? _lastOutcome;
  bool _isScanning = false;

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    final outcome = await _coordinator.run(context);
    if (!mounted || outcome == null) {
      if (mounted) setState(() => _isScanning = false);
      return;
    }
    setState(() => _lastOutcome = outcome);

    // Present the result; "Scan again" pops with true and restarts the
    // flow from scratch (reset).
    final scanAgain = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => DniCardScreen(outcome: outcome)),
    );
    setState(() => _isScanning = false);
    if (scanAgain == true) {
      _startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastOutcome = _lastOutcome;
    return Scaffold(
      appBar: AppBar(title: const Text('DNI Scanner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Scan a Peruvian DNI: first the PDF417 barcode on the back, then '
            'the MRZ lines for the birth date.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton(
              key: const Key('scan-dni-button'),
              onPressed: _isScanning ? null : _startScan,
              child: const Text('Scan DNI'),
            ),
          ),
          if (lastOutcome != null) ...[
            const SizedBox(height: 24),
            _LastResultSummary(outcome: lastOutcome),
          ],
        ],
      ),
    );
  }
}

/// Compact summary of the last completed run.
class _LastResultSummary extends StatelessWidget {
  const _LastResultSummary({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = outcome.data;
    final title = data?.docNumber != null
        ? 'DNI ${data!.docNumber}'
        : 'Last scan could not be read';
    final subtitle = data == null
        ? 'Check the result screen for the raw payloads.'
        : _fullName(data);
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(
          data == null ? Icons.warning_amber_rounded : Icons.badge_outlined,
          color: data == null ? theme.colorScheme.error : null,
        ),
      ),
    );
  }

  String _fullName(DniData data) {
    final names = [
      data.firstSurname,
      data.secondSurname,
      data.givenNames,
    ].whereType<String>().where((part) => part.isNotEmpty);
    return names.isEmpty ? 'Names not captured' : names.join(', ');
  }
}
