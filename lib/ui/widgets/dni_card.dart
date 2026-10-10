/// The parsed-DNI card: every field with its source badge, missing-field
/// flag, or pending-calibration chip.
///
/// Rules enforced here (see the payload-layout notes: address/ubigeo are
/// not documented in any barcode or MRZ layout):
/// - a present field renders its value plus a PDF417/MRZ source badge;
/// - an absent field renders a subtle "Not captured" flag, never a guess;
/// - address and ubigeo rows render a visible "Pending calibration" chip.
library;

import 'package:flutter/material.dart';

import '../../src/model/dni_data.dart';

/// Displays a merged [DniData] as a document card.
class DniCard extends StatelessWidget {
  const DniCard({super.key, required this.data});

  final DniData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Peruvian DNI',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _FieldRow(
              label: 'Document number',
              fieldKey: 'docNumber',
              value: data.docNumber,
              source: data.sourceOf(DniField.docNumber),
            ),
            _FieldRow(
              label: 'First surname',
              fieldKey: 'firstSurname',
              value: data.firstSurname,
              source: data.sourceOf(DniField.firstSurname),
            ),
            _FieldRow(
              label: 'Second surname',
              fieldKey: 'secondSurname',
              value: data.secondSurname,
              source: data.sourceOf(DniField.secondSurname),
            ),
            _FieldRow(
              label: 'Given names',
              fieldKey: 'givenNames',
              value: data.givenNames,
              source: data.sourceOf(DniField.givenNames),
            ),
            _FieldRow(
              label: 'Birth date',
              fieldKey: 'birthDate',
              value: _formatDate(data.birthDate),
              source: data.sourceOf(DniField.birthDate),
            ),
            _FieldRow(
              label: 'Sex',
              fieldKey: 'sex',
              value: _sexLabel(data.sex),
              source: data.sourceOf(DniField.sex),
            ),
            _FieldRow(
              label: 'Expiry date',
              fieldKey: 'expiryDate',
              value: _formatDate(data.expiryDate),
              source: data.sourceOf(DniField.expiryDate),
            ),
            // Address and ubigeo: no documented barcode/MRZ layout carries
            // them; they stay visibly pending real-card calibration.
            _FieldRow(
              label: 'Address',
              fieldKey: 'address',
              pendingCalibration: true,
            ),
            _FieldRow(
              label: 'Department',
              fieldKey: 'department',
              pendingCalibration: true,
            ),
            _FieldRow(
              label: 'Province',
              fieldKey: 'province',
              pendingCalibration: true,
            ),
            _FieldRow(
              label: 'District',
              fieldKey: 'district',
              pendingCalibration: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Dates render as dd/MM/yyyy (Peruvian convention). Null stays null so
  /// the row renders the missing flag.
  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    String pad2(int value) => value.toString().padLeft(2, '0');
    return '${pad2(date.day)}/${pad2(date.month)}/${date.year}';
  }

  /// Sex renders as a professional label; the parsers only ever produce
  /// 'M'/'F', and no other value is invented here.
  String? _sexLabel(String? sex) => switch (sex) {
        'M' => 'Male',
        'F' => 'Female',
        _ => sex,
      };
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.fieldKey,
    this.value,
    this.source,
    this.pendingCalibration = false,
  });

  final String label;
  final String fieldKey;
  final String? value;
  final FieldSource? source;
  final bool pendingCalibration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: value != null
                    ? Text(value!, style: theme.textTheme.titleMedium)
                    : pendingCalibration
                        ? _PendingCalibrationChip(fieldKey: fieldKey)
                        : _MissingFlag(fieldKey: fieldKey),
              ),
              if (source != null) ...[
                const SizedBox(width: 8),
                _SourceBadge(fieldKey: fieldKey, source: source!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Per-field origin badge shown wherever [DniData] tracks a source.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.fieldKey, required this.source});

  final String fieldKey;
  final FieldSource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('source-badge-$fieldKey'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        source == FieldSource.pdf417 ? 'PDF417' : 'MRZ',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// Subtle flag for a field no source provided.
class _MissingFlag extends StatelessWidget {
  const _MissingFlag({required this.fieldKey});

  final String fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('missing-flag-$fieldKey'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        'Not captured',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Visible marker that a field awaits real-card calibration (its layout is
/// simply not documented yet; no value may be guessed or typed manually).
class _PendingCalibrationChip extends StatelessWidget {
  const _PendingCalibrationChip({required this.fieldKey});

  final String fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: Key('pending-calibration-$fieldKey'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outline),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Text(
        'Pending calibration',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
