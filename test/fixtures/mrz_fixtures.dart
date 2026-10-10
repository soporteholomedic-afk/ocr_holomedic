/// Raw MRZ TD1 fixtures for the DNI parser tests.
///
/// All lines are exactly 30 characters per ICAO 9303 TD1. Check digits are
/// computed correctly for realism, but the prototype parser does not
/// validate them.
library;

/// Canonical TD1 MRZ for the same card as the PDF417 fixture:
/// doc number 45595338, birth 1995-03-12, sex M, expiry 2027-04-25.
/// Line 3 truncates `NORMAN VALERY` to `NORMAN` (30-char limit).
const String canonicalTd1Mrz =
    'I<PER45595338<4<<<<<<<<<<<<<<<\n'
    '9503124M2704254<<<<<<<<<<<<<<<\n'
    'CASTILLO<CEFERINO<<NORMAN<<<<<';

/// Only two of the three TD1 lines.
const String twoLinesOnlyMrz =
    'I<PER45595338<4<<<<<<<<<<<<<<<\n'
    '9503124M2704254<<<<<<<<<<<<<<<';

/// Line 2 has 29 characters instead of 30.
const String wrongLineLengthMrz =
    'I<PER45595338<4<<<<<<<<<<<<<<<\n'
    '9503124M2704254<<<<<<<<<<<<<<\n'
    'CASTILLO<CEFERINO<<NORMAN<<<<<';

/// Document number field carries 9 digits instead of 8 plus filler.
const String invalidDocNumberMrz =
    'I<PER1234567894<<<<<<<<<<<<<<<\n'
    '9503124M2704254<<<<<<<<<<<<<<<\n'
    'CASTILLO<CEFERINO<<NORMAN<<<<<';

/// Sex position holds the filler character `<`.
const String fillerSexMrz =
    'I<PER45595338<4<<<<<<<<<<<<<<<\n'
    '9503124<2704254<<<<<<<<<<<<<<<\n'
    'CASTILLO<CEFERINO<<NORMAN<<<<<';
