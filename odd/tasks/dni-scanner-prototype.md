# DNI Scanner Prototype — ocr_dni

## Objective
Flutter prototype that scans the PDF417 barcode on the back of a Peruvian DNI and fills a card with: DNI number, full names, birth date, department/province/district, and address.

## Problem / Why
Manual entry of DNI data is slow and error-prone. The Peruvian DNI carries all target fields inside the PDF417 barcode on the back of the card, so barcode scanning is the reliable extraction path (not raw OCR). OCR remains a possible future fallback for damaged barcodes.

## Scope (authorized)
- Scan screen using `mobile_scanner` restricted to PDF417
- Tolerant pipe-delimited payload parser (calibration-friendly field order)
- Card UI filled with parsed data + collapsible raw payload (debug/calibration aid) + rescan action
- Unit tests for the parser (TDD) and widget tests for the card/home
- NOT in scope: backend, persistence, OCR fallback, ubigeo code mapping table, PDF417 validation against real cards (recorded as follow-up calibration)

## Constraints
- Flutter 3.41.2 / Dart 3.11.0, Windows dev host (targets: Android/iOS)
- Artifacts in English (code, comments, UI copy)
- Commits: Conventional Commits, no Co-Authored-By / AI attribution
- Branch: `feature/dni-scanner-prototype` (repo previously had zero commits)

## Tasks
- [ ] T1: Bootstrap Flutter app at repo root (`flutter create .`, `mobile_scanner` dep, camera permissions Android + iOS)
- [ ] T2: `DniData` model + PDF417 payload parser + unit tests (observe RED, then GREEN)
- [ ] T3: Home screen + scanner screen + DNI card fill flow (+ widget tests)
- [ ] T4: Parent verification (`flutter analyze`, `flutter test`) + native review assessment

## Acceptance criteria
- `flutter analyze` reports no issues
- `flutter test` all green
- After a scan, the card shows the 5 requested data groups; raw payload visible in a collapsible section
- Parser handles the documented pipe-delimited layout; unrecognized layouts fail gracefully (error state, no crash)

## Progress / evidence
- 2026-10-10: feature doc created; environment verified (Flutter 3.41.2, RDD on-by-default)

## Route record
- T1–T3: delegated direct writer (writer trigger: 2+ non-trivial files)
- T4: parent inline checks + native assess
