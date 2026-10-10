# Project Skills — ocr_dni

## Objective
Define and create the skills this project needs before implementation starts: a reusable Flutter/Dart testing skill (user level) and a project-domain PDF417 parsing skill (project level), then register both in the skill registry.

## Problem / Why
The registry has 14 user-level skills but none Flutter-specific. Tasks T2/T3 of the DNI scanner prototype are TDD-heavy; every delegated writer would otherwise reinvent Flutter test patterns (widget tests, platform-channel fakes for the camera/scanner). The PDF417 domain knowledge (pipe-delimited layout, calibration protocol, ubigeo caveats) must live in the repo so subagents load exact domain rules instead of improvising web searches.

## Scope (authorized)
- Create `flutter-testing` skill at user level (`C:\Users\soporte\.agents\skills\flutter-testing\`)
- Create `dni-pdf417-parsing` skill at project level (`.agents/skills/dni-pdf417-parsing/`) with a payload-layout reference
- Refresh `.atl/skill-registry.md` and its Engram mirror (`topic_key: skill-registry`)
- Work-unit commits on feature branch; remote `origin` already configured (push is user's decision)

## Tasks
- [ ] T1: feature doc + visible tracking (this document)
- [ ] T2: `flutter-testing` SKILL.md following skill-creator style guide (frontmatter, section order, body budget)
- [ ] T3: `dni-pdf417-parsing` SKILL.md + `references/payload-layout-notes.md`
- [ ] T4: registry refresh: `.atl/skill-registry.md` + Engram `skill-registry`
- [ ] T5: work-unit commits on `feature/project-skills`

## Acceptance criteria
- Both SKILL.md files pass the LLM-first checklist: complete single-line quoted description with trigger words, required section order, body <= 1000 tokens, local references only
- Registry lists both skills with correct scope (user / project) and exact paths
- Commits are Conventional Commits without AI attribution

## Progress / evidence
- 2026-10-10: remote `origin` added (git@github.com:soporteholomedic-afk/ocr_holomedic.git); feature doc created

## Route record
- T2–T3: parent inline (single-file writes with full context already loaded; skill-creator guide read in-session)
- T4–T5: parent inline
