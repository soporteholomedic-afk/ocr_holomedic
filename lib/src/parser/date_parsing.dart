/// Defensive date parsing for raw DNI payload fragments.
///
/// Unparsable or out-of-range raw values return null so the field is flagged
/// missing instead of guessed.
library;

/// Parses a `yyyyMMdd` fragment (e.g. the PDF417 bytes at 448-455).
DateTime? parseYmd(String raw) {
  if (!RegExp(r'^\d{8}$').hasMatch(raw)) return null;
  return _buildValidDate(
    int.parse(raw.substring(0, 4)),
    int.parse(raw.substring(4, 6)),
    int.parse(raw.substring(6, 8)),
  );
}

/// Parses a `yyMMdd` birth date using the sliding-century rule: a 2000-based
/// date that lies in the future of [referenceYear] belongs to the 1900s.
DateTime? parseBirthYymmdd(String raw, {required int referenceYear}) {
  if (!RegExp(r'^\d{6}$').hasMatch(raw)) return null;
  final yy = int.parse(raw.substring(0, 2));
  final century = 2000 + yy > referenceYear ? 1900 : 2000;
  return _buildValidDate(
    century + yy,
    int.parse(raw.substring(2, 4)),
    int.parse(raw.substring(4, 6)),
  );
}

/// Parses a `yyMMdd` expiry date. Expiry is always 2000-based: no valid DNI
/// card expires before 2000 in this prototype.
DateTime? parseExpiryYymmdd(String raw) {
  if (!RegExp(r'^\d{6}$').hasMatch(raw)) return null;
  return _buildValidDate(
    2000 + int.parse(raw.substring(0, 2)),
    int.parse(raw.substring(2, 4)),
    int.parse(raw.substring(4, 6)),
  );
}

/// Builds a date, rejecting values the [DateTime] constructor would silently
/// roll over (e.g. February 30).
DateTime? _buildValidDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
