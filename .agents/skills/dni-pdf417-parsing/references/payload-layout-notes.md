# Peruvian DNI payload layouts — notes & calibration log

Status: **hypotheses pending real-card calibration.** RENIEC publishes no official payload specification.

Primary community source: [Eitol/peru-dni-reader](https://github.com/Eitol/peru-dni-reader) (fetched 2026-10-10).
Earlier planning sessions assumed a pipe-delimited layout: **unverified, likely wrong** for the 1997 card.

## 1997 adult DNI — PDF417, fixed byte offsets (hypothesis)

| Bytes | Field | Example |
| --- | --- | --- |
| 0–1 | NI | `01` |
| 2–9 | Document number (8 digits) | `45595338` |
| 10–49 | First surname | `Castillo` |
| 50–89 | Second surname | `Ceferino` |
| 90–124 | Given names (space separated) | `Norman Valery` |
| 125 | Sex (`1`=M, `2`=F) | `1` |
| 448–455 | Date, `yyyyMMdd` | `20270425` |
| 456–463 | Ficha code | `87260138` |
| 464–471 | Ficha code (repeat) | `87260138` |

Payload also carries fingerprint data beyond offset 471.

**Ambiguity:** the reference labels bytes 448–455 only as "Fecha". The example `20270425` is a future date → likely **expiration**, not birth. Birth date must come from MRZ or be calibrated against a real card.

## MRZ TD1 (present on all DNI versions)

Three lines of 30 characters: document number + check digit, birth date `YYMMDD` + check, sex `M`/`F`, expiry `YYMMDD` + check, nationality `PER`; third line carries paternal surname and given names separated by `<`.

Covers: document number, birth date, sex, expiry, surnames, given names.

## DNIe 2013 / 2020 (electronic)

Carries a chip (back in 2013, front in 2020). Its PDF417 payload layout is **not documented** in the community sources reviewed; requires real-card calibration.

## Required fields vs available sources

| Required field | 1997 PDF417 | MRZ TD1 |
| --- | --- | --- |
| DNI number | ✅ | ✅ |
| Full names | ✅ | ✅ |
| Birth date | ⚠️ ambiguous | ✅ |
| Department / province / district | ❌ | ❌ |
| Address | ❌ | ❌ |

**Top project risk:** address and ubigeo are not documented in any community source for barcode or MRZ. They may only exist in DNIe chip data or newer PDF417 versions. Obtain real cards (ideally a DNIe) before trusting any address extraction; until then the UI must render those fields as empty/flagged.

## Calibration log

| Date | Card version | Finding | Action |
| --- | --- | --- | --- |
| 2026-10-10 | — | Desk research only; no real card scanned yet | Parser detects layout before mapping; address/ubigeo rendered empty |
| 2026-10-10 | — | Pipe-delimited layout from early planning marked unverified | Kept as delimited-format hypothesis branch in parser tests |
