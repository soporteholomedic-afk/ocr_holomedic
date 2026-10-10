/// Merges the PDF417 and MRZ parse results into a single [DniData].
library;

import '../model/dni_data.dart';

/// Merge policy (prototype, pending real-card calibration):
///
/// - birthDate: MRZ only. The PDF417 payload documents no birth date (its
///   date bytes are mapped to expiry), so the MRZ is the only birth source.
/// - expiryDate: MRZ preferred. ICAO TD1 semantics are confirmed, while the
///   PDF417 date mapping is a hypothesis.
/// - docNumber, surnames, given names, sex: PDF417 preferred when present
///   (fuller casing and an explicit 8-digit field), MRZ as fallback.
///
/// Sources are recorded per field on the merged result.
final class DniMerger {
  const DniMerger();

  /// Merges [pdf417] and [mrz] partial results. Returns null only when both
  /// sides are null (nothing merged at all).
  DniData? merge(DniData? pdf417, DniData? mrz) {
    if (pdf417 == null && mrz == null) return null;

    final docNumber = pdf417?.docNumber ?? mrz?.docNumber;
    final firstSurname = pdf417?.firstSurname ?? mrz?.firstSurname;
    final secondSurname = pdf417?.secondSurname ?? mrz?.secondSurname;
    final givenNames = pdf417?.givenNames ?? mrz?.givenNames;
    final birthDate = mrz?.birthDate ?? pdf417?.birthDate;
    final expiryDate = mrz?.expiryDate ?? pdf417?.expiryDate;
    final sex = pdf417?.sex ?? mrz?.sex;

    final sources = <DniField, FieldSource>{};
    void record(
      DniField field,
      Object? preferred,
      Object? fallback,
      FieldSource preferredSource,
      FieldSource fallbackSource,
    ) {
      if (preferred != null) {
        sources[field] = preferredSource;
      } else if (fallback != null) {
        sources[field] = fallbackSource;
      }
    }

    record(DniField.docNumber, pdf417?.docNumber, mrz?.docNumber,
        FieldSource.pdf417, FieldSource.mrz);
    record(DniField.firstSurname, pdf417?.firstSurname, mrz?.firstSurname,
        FieldSource.pdf417, FieldSource.mrz);
    record(DniField.secondSurname, pdf417?.secondSurname, mrz?.secondSurname,
        FieldSource.pdf417, FieldSource.mrz);
    record(DniField.givenNames, pdf417?.givenNames, mrz?.givenNames,
        FieldSource.pdf417, FieldSource.mrz);
    // MRZ preferred for birth (PDF417 never provides it) and for expiry
    // (confirmed ICAO semantics vs. the PDF417 hypothesis).
    record(DniField.birthDate, mrz?.birthDate, pdf417?.birthDate,
        FieldSource.mrz, FieldSource.pdf417);
    record(DniField.expiryDate, mrz?.expiryDate, pdf417?.expiryDate,
        FieldSource.mrz, FieldSource.pdf417);
    record(DniField.sex, pdf417?.sex, mrz?.sex, FieldSource.pdf417,
        FieldSource.mrz);

    return DniData(
      docNumber: docNumber,
      firstSurname: firstSurname,
      secondSurname: secondSurname,
      givenNames: givenNames,
      birthDate: birthDate,
      expiryDate: expiryDate,
      sex: sex,
      sources: sources,
    );
  }
}
