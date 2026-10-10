---
name: dni-pdf417-parsing
description: "Trigger: DNI peruano, PDF417, RENIEC payload, dni parser, ubigeo, MRZ TD1. Domain rules for parsing Peruvian DNI barcode/MRZ payloads in ocr_dni."
license: MIT
metadata:
  author: gentleman-programming
  version: "1.0"
---

## Activation Contract

Use when implementing, testing, or calibrating any code in this repo that decodes or parses the Peruvian DNI PDF417 barcode or TD1 MRZ payload.

## Hard Rules

- RENIEC publishes no official payload specification; every layout in the reference is a hypothesis pending real-card calibration.
- Parse tolerantly: detect the layout (fixed-offset 1997 / delimited / unknown) before mapping any field.
- Never invent values for missing or unreadable fields; return a typed parse error carrying the raw payload.
- DNI number must be exactly 8 digits; parse dates defensively (raw format yyyyMMdd, semantics unconfirmed).
- Record every real-card calibration difference in `references/payload-layout-notes.md`; never silently patch the parser.

## Decision Gates

| Situation | Action |
| --- | --- |
| Payload matches 1997 fixed-offset layout | Map documented offsets per reference; trim padding |
| Payload is delimited (pipe/`@`) | Map by token index per reference; treat as hypothesis |
| Layout unknown or field count mismatch | Surface raw payload + error state; request calibration capture |
| Address / ubigeo absent from payload | Render empty + flag; do not fabricate |
| Barcode unreadable | Rescan fallback; OCR is out of prototype scope |

## Execution Steps

1. Feed the decoded raw string to the parser untouched (no preprocessing).
2. Detect the layout; map fields per `references/payload-layout-notes.md`.
3. Validate DNI (8 digits) and birth date; build `DniData` or a typed error.
4. Add or update tests covering: canonical 1997 layout, delimited hypothesis, unknown layout, short payload.

## Output Contract

Return parser changes with tests for all four layout cases; name every calibration assumption explicitly in the test names.

## References

- `references/payload-layout-notes.md` — documented layouts, field coverage vs requirements, calibration log.
