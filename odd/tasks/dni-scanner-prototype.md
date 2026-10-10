# DNI Scanner Prototype — ocr_dni

## Objective
Flutter prototype that scans a Peruvian DNI and fills a card with: DNI number, full names, birth date, department/province/district, and address. Two extraction paths: PDF417 barcode (primary) and MRZ TD1 text recognition (birth date + redundancy).

## Problem / Why
Manual entry of DNI data is slow and error-prone. Desk research (2026-10-10, source: Eitol/peru-dni-reader, recorded in `.agents/skills/dni-pdf417-parsing/references/payload-layout-notes.md`) established:
- The 1997 DNI PDF417 payload uses fixed byte offsets (not pipe-delimited); the date at offsets 448-455 is likely expiration, not birth.
- MRZ TD1 (present on all DNI versions) reliably carries document number, birth date, sex, and names.
- Address and department/province/district (ubigeo) are NOT present in documented barcode/MRZ fields; they may only exist in the DNIe chip.

## Scope (authorized)
- Scan screen using `mobile_scanner` restricted to PDF417
- MRZ TD1 reading via `google_mlkit_text_recognition` (OCR limited to the MRZ zone; general OCR stays out of scope)
- Format-tolerant payload parser: detect fixed-offset 1997 layout / delimited hypothesis / unknown before mapping fields
- Field merge: PDF417 + MRZ results unified into `DniData`, tracking per-field source; birth date taken from MRZ when available
- Card UI: parsed fields; address and ubigeo rendered empty with a "pending calibration" flag; collapsible raw payload AND raw MRZ text (debug/calibration aid); rescan action
- Unit tests: parser layout cases (fixed-offset canonical, delimited hypothesis, unknown, short payload) + MRZ parse; widget tests for card/home
- NOT in scope: backend, persistence, general OCR, NFC/chip reading, ubigeo mapping table (follow-up: real-card calibration incl. DNIe NFC research)

## Constraints
- Flutter 3.41.2 / Dart 3.11.0, Windows dev host (targets: Android/iOS)
- Packages: `mobile_scanner` (PDF417), `google_mlkit_text_recognition` (MRZ)
- Artifacts in English (code, comments, UI copy)
- Commits: Conventional Commits, no Co-Authored-By / AI attribution
- Branch: `feature/dni-scanner-prototype` off `feature/project-skills`

## Deployment decision (2026-10-10)
- Prototype: 100% on-device (no server, validates capture fastest).
- Production context: organization internal network with an available server. Evolution path is hybrid: capture stays on-device (barcode + MRZ), parsing/calibration migrates server-side so recalibration does not require app releases.
- Architectural consequence (binding for T2): the parser must be a pure Dart module — no Flutter imports, no plugin dependencies — so it runs unchanged on a Dart server later.

## Tasks
- [x] T1: Bootstrap Flutter app at repo root (`flutter create .`, deps, camera permissions Android + iOS)
- [x] T2: `DniData` model + PDF417 multi-format parser + MRZ TD1 parser + merge logic + unit tests (RED -> GREEN)
- [x] T3: Home screen + scanner flow (barcode then MRZ capture) + card fill with per-field source/flags (+ widget tests)
- [x] T4: Parent verification (`flutter analyze`, `flutter test`) + native review assessment

## Acceptance criteria
- `flutter analyze` reports no issues
- `flutter test` all green
- After scanning, the card shows DNI number, names, and birth date (from MRZ when readable); address/ubigeo show empty + pending-calibration flag
- Parser handles all four layout cases without crashing; unknown layout surfaces raw payload + error state
- Raw PDF417 payload and raw MRZ text are visible in collapsible sections
- Parser module imports no Flutter libraries (pure Dart, server-migrable)

## Progress / evidence
- 2026-10-10: feature doc created; environment verified (Flutter 3.41.2, RDD on-by-default)
- 2026-10-10: plan revised after desk research (P1 fixed-offset layout, P2 date ambiguity, P3 address/ubigeo absent, P4 four card versions, P5 MRZ needs OCR); product decision: barcode + MRZ OCR
- 2026-10-10: project skills created (see odd/tasks/project-skills.md); remote `origin` configured
- 2026-10-10: T1 done — `flutter create .` (org com.holomedic, android+ios), deps `mobile_scanner` + `google_mlkit_text_recognition`, CAMERA permission (AndroidManifest) + NSCameraUsageDescription (Info.plist). `flutter analyze` clean. Commit `4f51b7b`. Test device authorized: SM A256E (R5CX800GJMX, Android 16/API 36)
- 2026-10-10: T2 done (delegated writer, strict TDD) — pure-Dart model/parsers/merger under `lib/src/`, 19 new tests (RED observed via stubs, then GREEN), parent spot check 20/20 + analyze clean. Commits `1cad075`, `3d3873f` (gitignore build artifacts). Calibration assumptions logged by writer: delimited token order, MRZ surnames split, expiry 2000-based, 448-455 = expiry
- 2026-10-10: theme added (user-provided Tailwind v4/shadcn tokens, translated to Material 3 — Tailwind does not run in Flutter) — `lib/theme/app_theme.dart` with light/dark `ThemeData`, converted OKLCH->sRGB palette (primary #3B82F6), AppRadius/AppShadows/AppFonts. Commits `0d17225`, `114c6a4`
- 2026-10-10: T3 done (delegated writer, TDD) — theme wired in `main.dart` (system themeMode), scan flow Home -> PDF417 -> MRZ (skippable) -> card with per-field source badges, missing-field flags and pending-calibration chips for address/ubigeo; ports + thin plugin adapters; `camera: ^0.12.0+2` added as the only new dep. 14 new widget tests (RED observed first), suite 33/33, analyze clean. Commits `da35c2b`, `6b2b9fb`, `a3a5148`
- 2026-10-10: T4 done — parent spot check (33/33, analyze clean); native review lineage `review-8cd7364929759865` (committed range 9700d55..HEAD, 34 files/3491 lines, medium risk) APPROVED by `review-reliability` lens, acknowledgement completed (authority burned). 4 non-blocking findings recorded as follow-ups. `flutter build apk --debug` OK; app-debug.apk installed on SM A256E — on-device camera validation with a real DNI is the user acceptance step (plugin adapters are compile-verified only)
- 2026-10-10: push to `origin` pending (user decision)
- 2026-10-10: scan guide overlay added (user request "cuadro de guía") — reusable `ScanGuideOverlay` (scrim + rounded window + corner brackets, theme-driven, IgnorePointer) wired into both capture screens: centered wide strip for PDF417, lower-third strip for MRZ; 5 widget tests TDD (RED first), suite 38/38, analyze clean. Commit `08f1e23`. Visual calibration values (aspect ratios, offsets) pending on-device tuning

## Follow-ups (from approved review — non-blocking, informational)
- [ ] R3-homescreen-mounted-guard (WARNING): async-gap mounted checks in `lib/ui/home_screen.dart:58-64`
- [ ] R3-date-rejection-untested (SUGGESTION): add tests for date rejection paths in `lib/src/parser/date_parsing.dart:40-50`
- [ ] R3-expiry-century-boundary (SUGGESTION): century sliding-window boundary in `date_parsing.dart:31-38`
- [ ] R3-mixed-separator-delimited (SUGGESTION): mixed separators handling in delimited layout, `pdf417_parser.dart:96-104`
- [ ] On-device calibration with real DNI cards (all four card versions); record results in dni-pdf417-parsing reference
- [ ] `google_fonts` dependency decision (Inter / Source Serif 4 / JetBrains Mono wiring)

## Route record
- T1: parent inline (command-generated scaffolding + two one-line permission edits; no authored multi-file change)
- T2: delegated direct writer (writer trigger: 2+ non-trivial files); skills to load: `flutter-testing` (user) + `dni-pdf417-parsing` (project)
- T3: delegated direct writer (multi-file UI)
- T4: parent inline checks + native assess
