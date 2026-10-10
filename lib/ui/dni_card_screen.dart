/// Result screen of the scan flow: parsed DNI card or parse-error state.
///
/// Both states expose the untouched raw payloads in collapsible sections
/// (debug/calibration aid), and both offer "Scan again", which pops with
/// `true` so the flow coordinator resets and starts a fresh run.
library;

import 'package:flutter/material.dart';

import '../src/scan/scan_outcome.dart';
import 'widgets/dni_card.dart';

class DniCardScreen extends StatelessWidget {
  const DniCardScreen({super.key, required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (outcome.succeeded)
            DniCard(data: outcome.data!)
          else
            _ErrorPanel(outcome: outcome),
          const SizedBox(height: 16),
          _RawSections(outcome: outcome),
          const SizedBox(height: 16),
          OverflowBar(
            children: [
              OutlinedButton(
                key: const Key('done-button'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Done'),
              ),
              FilledButton(
                key: const Key('scan-again-button'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Scan again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Parse-error state: typed errors from [DniParseError] with no guessed
/// data anywhere.
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Could not read the document',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (outcome.pdf417Error != null)
              Text(
                'Barcode: ${outcome.pdf417Error!.message}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (outcome.mrzError != null) ...[
              const SizedBox(height: 4),
              Text(
                'MRZ: ${outcome.mrzError!.message}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Keep the raw payloads below for calibration.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Collapsible raw sections for the untouched payloads.
class _RawSections extends StatelessWidget {
  const _RawSections({required this.outcome});

  final ScanOutcome outcome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          key: const Key('raw-payload-section'),
          title: const Text('Raw payload'),
          subtitle: const Text('Untouched PDF417 barcode content'),
          children: [
            _RawText(text: outcome.rawPdf417Payload),
          ],
        ),
        if (outcome.rawMrzText != null)
          ExpansionTile(
            key: const Key('raw-mrz-section'),
            title: const Text('Raw MRZ text'),
            subtitle: const Text('Recognized MRZ lines'),
            children: [
              _RawText(text: outcome.rawMrzText!),
            ],
          ),
      ],
    );
  }
}

class _RawText extends StatelessWidget {
  const _RawText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SelectableText(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
