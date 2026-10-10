/// Data model for a parsed Peruvian DNI.
///
/// Every field is nullable: a parser only fills the fields its layout
/// documents and never guesses values. [DniData.sources] records where each
/// filled field came from, and [DniData.missingFields] lists the fields no
/// source provided.
library;

/// Identifiable DNI fields tracked for source and missing bookkeeping.
enum DniField {
  docNumber,
  firstSurname,
  secondSurname,
  givenNames,
  birthDate,
  expiryDate,
  sex,
}

/// Origin of a parsed field value.
enum FieldSource { pdf417, mrz }

/// Parsed DNI fields.
///
/// Address and ubigeo fields exist for UI completeness but stay null in this
/// prototype: no community-documented PDF417 or MRZ layout carries them
/// (see [addressFieldsPendingCalibration]); the UI must render them as
/// empty/flagged until real-card calibration proves otherwise.
final class DniData {
  const DniData({
    this.docNumber,
    this.firstSurname,
    this.secondSurname,
    this.givenNames,
    this.birthDate,
    this.expiryDate,
    this.sex,
    this.sources = const {},
    this.address,
    this.department,
    this.province,
    this.district,
  });

  /// Builds the partial data produced by the PDF417 parser.
  ///
  /// The PDF417 layout documents no birth date (its date bytes are
  /// hypothesized to be the expiration, see payload-layout-notes.md), so
  /// [DniField.birthDate] can never be sourced from PDF417 here.
  factory DniData.fromPdf417({
    String? docNumber,
    String? firstSurname,
    String? secondSurname,
    String? givenNames,
    DateTime? expiryDate,
    String? sex,
  }) {
    final values = <DniField, Object?>{
      DniField.docNumber: docNumber,
      DniField.firstSurname: firstSurname,
      DniField.secondSurname: secondSurname,
      DniField.givenNames: givenNames,
      DniField.birthDate: null, // never provided by PDF417 in this prototype.
      DniField.expiryDate: expiryDate,
      DniField.sex: sex,
    };
    return DniData(
      docNumber: docNumber,
      firstSurname: firstSurname,
      secondSurname: secondSurname,
      givenNames: givenNames,
      expiryDate: expiryDate,
      sex: sex,
      sources: _sourcesFor(values, FieldSource.pdf417),
    );
  }

  /// Builds the partial data produced by the MRZ TD1 parser.
  factory DniData.fromMrz({
    String? docNumber,
    String? firstSurname,
    String? secondSurname,
    String? givenNames,
    DateTime? birthDate,
    DateTime? expiryDate,
    String? sex,
  }) {
    final values = <DniField, Object?>{
      DniField.docNumber: docNumber,
      DniField.firstSurname: firstSurname,
      DniField.secondSurname: secondSurname,
      DniField.givenNames: givenNames,
      DniField.birthDate: birthDate,
      DniField.expiryDate: expiryDate,
      DniField.sex: sex,
    };
    return DniData(
      docNumber: docNumber,
      firstSurname: firstSurname,
      secondSurname: secondSurname,
      givenNames: givenNames,
      birthDate: birthDate,
      expiryDate: expiryDate,
      sex: sex,
      sources: _sourcesFor(values, FieldSource.mrz),
    );
  }

  /// Document number, exactly 8 digits when present.
  final String? docNumber;

  final String? firstSurname;
  final String? secondSurname;
  final String? givenNames;

  /// Birth date. Never taken from the PDF417 payload: its date bytes are
  /// hypothesized to be the expiration. Birth comes from the MRZ (or from
  /// future real-card calibration).
  final DateTime? birthDate;

  final DateTime? expiryDate;

  /// Normalized sex: 'M' or 'F' (PDF417 '1'/'2' and MRZ 'M'/'F' both map here).
  final String? sex;

  /// Source of each filled field.
  final Map<DniField, FieldSource> sources;

  /// Marker documenting that address/ubigeo extraction is pending real-card
  /// calibration: community sources document no barcode/MRZ layout carrying
  /// those fields (they may only exist in DNIe chip data).
  static const bool addressFieldsPendingCalibration = true;

  /// Address and ubigeo. Parsers never fill them in this prototype.
  final String? address;
  final String? department;
  final String? province;
  final String? district;

  /// Source of [field], or null when no source provided it.
  FieldSource? sourceOf(DniField field) => sources[field];

  /// Raw value of [field] regardless of source.
  Object? valueOf(DniField field) => switch (field) {
        DniField.docNumber => docNumber,
        DniField.firstSurname => firstSurname,
        DniField.secondSurname => secondSurname,
        DniField.givenNames => givenNames,
        DniField.birthDate => birthDate,
        DniField.expiryDate => expiryDate,
        DniField.sex => sex,
      };

  /// Fields that no source provided.
  Set<DniField> get missingFields => {
        for (final field in DniField.values)
          if (valueOf(field) == null) field,
      };

  static Map<DniField, FieldSource> _sourcesFor(
    Map<DniField, Object?> values,
    FieldSource source,
  ) =>
      {
        for (final entry in values.entries)
          if (entry.value != null) entry.key: source,
      };
}
