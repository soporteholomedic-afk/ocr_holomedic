/// Raw PDF417 payload fixtures for the DNI parser tests.
///
/// Layouts follow the hypotheses documented in
/// `.agents/skills/dni-pdf417-parsing/references/payload-layout-notes.md`
/// and are pending real-card calibration.
library;

/// Builds a 1997 fixed-offset payload strictly per the documented byte table:
///
/// - 0-1 NI, 2-9 document number (8 digits), 10-49 first surname,
///   50-89 second surname, 90-124 given names, 125 sex (1=M / 2=F),
///   448-455 date yyyyMMdd (hypothesized expiration), 456-463 and 464-471
///   ficha codes, opaque fingerprint data beyond 471.
///
/// Name fields are right-padded with spaces to their exact widths.
String buildFixedOffset1997Payload({
  String ni = '01',
  String docNumber = '45595338',
  String firstSurname = 'Castillo',
  String secondSurname = 'Ceferino',
  String givenNames = 'Norman Valery',
  String sex = '1',
  String dateAtOffset448 = '20270425',
  int fingerprintFillerLength = 30,
}) {
  assert(docNumber.length == 8, 'doc number must be exactly 8 digits');
  final buffer = StringBuffer()
    ..write(ni.padRight(2, ' ')) // 0-1: NI.
    ..write(docNumber) // 2-9: document number.
    ..write(firstSurname.padRight(40, ' ')) // 10-49: first surname.
    ..write(secondSurname.padRight(40, ' ')) // 50-89: second surname.
    ..write(givenNames.padRight(35, ' ')) // 90-124: given names.
    ..write(sex) // 125: sex.
    ..write(' ' * (448 - 126)) // 126-447: undocumented spacer.
    ..write(dateAtOffset448) // 448-455: date (hypothesized expiration).
    ..write('87260138') // 456-463: ficha code.
    ..write('87260138'); // 464-471: ficha code repeat.
  if (fingerprintFillerLength > 0) {
    buffer.write('F' * fingerprintFillerLength); // Opaque beyond offset 471.
  }
  return buffer.toString();
}

/// Canonical 1997 fixed-offset payload (502 chars: 472 layout + 30 filler).
final String canonicalFixedOffset1997Payload = buildFixedOffset1997Payload();

/// Delimited hypothesis (unverified early-planning format).
/// Token order: header `DNI`, doc number, first surname, second surname,
/// given names, sex (1/2, same encoding as the 1997 layout), date yyyyMMdd
/// (mapped to expiry under the same pending-calibration assumption).
const String delimitedPipePayload =
    'DNI|45595338|Castillo|Ceferino|Norman Valery|1|20270425';

/// Same delimited hypothesis with `@` as separator.
const String delimitedAtPayload =
    'DNI@45595338@Castillo@Ceferino@Norman Valery@1@20270425';

/// Delimited payload with fewer tokens than the hypothesis defines.
const String delimitedWrongTokenCountPayload = 'DNI|45595338|Castillo';

/// Delimited payload whose document number is not exactly 8 digits.
const String delimitedInvalidDocNumberPayload =
    'DNI|1234567|Castillo|Ceferino|Norman Valery|1|20270425';

/// 480 characters, no separators, non-digit bytes at 2-9: matches no layout.
final String unknownLayoutPayload = 'Z' * 480;

/// Truncated prefix of a fixed-offset payload (18 chars, no separators).
const String shortTruncatedPayload = '0145595338Castillo';
