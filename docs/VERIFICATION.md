# Verification record — 14 October 2026 (Asia/Jakarta)

## Support Circle — latest application verification

[Actions run 38498665800](https://github.com/scootar-dev/hopely-care/actions/runs/38498665800) completed successfully for application/test commit `da3cb0493eb11b8a80b45bc991ad78aaf6e01d4c` on `feature/support-circle`. All five jobs passed. [PR #2](https://github.com/scootar-dev/hopely-care/pull/2) includes the earlier Stitch V2, login, invitation and photo fixes as well as the new community feature; main has not been changed.

| Check | Result | Executed scope |
|---|---|---|
| Laravel + MySQL 8.4 | **31 tests, 202 assertions passed** | Existing privacy/photo/invitation tests and 12 community tests |
| Laravel + SQLite | **31 tests, 202 assertions passed** | Same API/migration/authorization suite |
| FastAPI pytest | **50 passed** | Existing 37 tests plus 13 community moderation/recommendation cases |
| Ruff | **Passed** | AI application and tests |
| Flutter analyze | **No issues found** | Native Flutter stable 3.47.7; no automatic source fixes in this final application run |
| Flutter widget tests | **37 passed** | Existing 23 tests and 14 community interaction/state/layout tests |
| Android debug APK | **Built successfully** | Existing runner and dependencies, emulator API endpoint |
| Docker HTTP smoke | **Passed** | Actual Laravel → MySQL → FastAPI endpoints, synthetic accounts only |
| Visual review | **Four community viewport captures inspected** | Home, detail, compose, safety at 390×844; all ten community routes render without exceptions |

Artifacts: [route renders](https://github.com/scootar-dev/hopely-care/actions/runs/38498665800/artifacts/11865366063) and [debug APK](https://github.com/scootar-dev/hopely-care/actions/runs/38498665800/artifacts/11865216273). The APK targets `http://10.0.2.2:8000/api` for Android Emulator. On a physical HP over USB, build locally with `API_BASE_URL=http://127.0.0.1:8000/api` and `adb reverse tcp:8000 tcp:8000`; use [SUPPORT_CIRCLE.md](SUPPORT_CIRCLE.md).

The community tests execute anonymous/non-member denial, chosen public alias and explicit sharing, ownership, stale revisions, fail-closed publication when AI is mock/unavailable/uncertain, moderator scope and independent review, report history, two-way blocking, reaction uniqueness, generic notification/deduplication/opt-out, private encrypted images, account cleanup, metadata consent and catalogue-ID validation. Catalogue seeding is tested without creating demo users.

The HTTP smoke uses real network/database calls: register/login/token revocation, core consent and mock chat persistence, community join, pending story with an actual FastAPI `manual_review` result, scoped human approval, comment approval, support reaction, generic notification, report resolution/history, notification opt-out, two-way block, and deletion/leave. Both temporary accounts and their owned records are removed. It runs only in a disposable local/testing Compose stack.

A newly created comment originally returned a null revision because its database default had not been refreshed in memory. The networked approval flow reproduced HTTP 409. The response now reloads the persisted comment, and a regression test checks revision 1, denial when the parent is pending, successful approval, revision 2 and the resulting comment notification. The Flutter comment test also scrolls to its composer before typing, matching the actual scrollable screen.

Native Dart fixes were reviewed and committed before this run. Four captures from the preceding `10175da` run were visually inspected; Flutter application/test files are identical at `da3cb04`. The final captures were regenerated successfully. The following documentation/workflow housekeeping removes the temporary base64 image logging; it does not change application or test code. Normal screenshot artifact upload remains enabled.

Limits: widget tests use fixtures confined to `mobile/test`; they are not physical-phone network tests. No live LLM inference, moderation-quality calibration, real FCM delivery, Android/iOS gallery/activity recovery, approved RAG-corpus evaluation, or signed production release is claimed verified. Recommendations deliberately use explicit-interest metadata matching, not embeddings or an LLM. Image moderation requires a human. Public deployment requires actual moderators; no diagnosis verification or clinical certification is claimed. Retention of soft-deleted/removed content is documented in SUPPORT_CIRCLE.md.

## Earlier verification history — 9 October 2026 (UTC)

This update supersedes the initial ZIP's verification record. Work continued from the actual GitHub repository at main commit `4c3a5d5fd6898bd4c93c34785e75a649ca7bd99c`, including its Flutter runners, Laravel 12 lockfile and existing FastAPI implementation.

Final code/test evidence: [GitHub Actions run 37999672063](https://github.com/scootar-dev/hopely-care/actions/runs/37999672063), commit `932f11e50c33807f6b1a5c8ffd3ef87545af04f2`. Subsequent verification-document edits do not change application or test code.

| Check | Result | Scope |
|---|---|---|
| FastAPI pytest | **37 passed** | Python 3.12, existing AI/RAG/consent/safety test suite |
| Ruff | **Passed** | AI application and tests |
| Laravel + SQLite | **11 tests, 25 assertions passed** | Migrations and privacy/feature tests, PHP 8.4 |
| Laravel + MySQL | **11 tests, 25 assertions passed** | Same suite against the CI MySQL 8.4 service |
| Flutter analyze | **Passed, no issues** | Flutter stable 3.47.7 |
| Flutter tests | **11 passed** | Existing tests plus V2 navigation, check-in, invitation, reactive consent and layout checks |
| Android debug APK | **Built successfully** | Existing native runner; emulator API endpoint, no live provider/FCM calls |
| V2 visual review | **17 route captures inspected** | 390×844 widget renders, synthetic data, shipped DejaVuSans and Material icons; natural shadows |
| Native bootstrap preservation | **Passed** | Temporary-file check: existing runners are retained, debug manifest attributes/metadata survive, cleartext enabled only in debug |
| Diff / configuration checks | **Passed** | Diff whitespace, Python syntax and Android manifest XML |

Artifacts: [stitch-v2-screens](https://github.com/scootar-dev/hopely-care/actions/runs/37999672063/artifacts/11648364165) and [hopely-care-debug-apk](https://github.com/scootar-dev/hopely-care/actions/runs/37999672063/artifacts/11648836177). The debug APK targets `http://10.0.2.2:8000/api`; it needs a running development backend accessible from an Android emulator. It is not a signed production release.

Visual inspection used [the 17 captures from the preceding run](https://github.com/scootar-dev/hopely-care/actions/runs/37999356569/artifacts/11648128506) at `552e477`. The final run retains identical application UI code and fixes test cleanup only; its images were regenerated successfully.

## Regressions resolved

- The main-branch Laravel suite initially failed because a newly created consent record lost its guarded `user_id`. The fix assigns the authenticated owner server-side. A regression test attempts to spoof another owner's ID and verifies both acceptance and revocation.
- Native Flutter tests found a Material/ListTile rendering assertion and chat overflow in a short viewport. Cards now provide a Material ancestor and chat content scrolls above its composer.
- Session changes notify consent-dependent UI without recreating the router. The test revokes AI chat consent and verifies that the composer disables immediately.
- Form interaction tests wait for keyboard dismissal and scrolling to settle before tapping. Review captures load real fonts; control styles explicitly use the bundled typeface. Temporary painting debug settings are restored before Flutter's binding invariants.

## What these tests establish

The Laravel suite executes anonymous/role/owner access checks, health consent, 1–5 validation, duplicate daily check-in rejection, both journal-analysis consent gates, linked caregiver field filtering, unlinked caregiver denial and removal of derived signals after withdrawal.

The Flutter suite executes onboarding completion/skip, caregiver route isolation and invitation acceptance, check-in saving with 1–5 values and analysis opt-out, reactive chat consent, error redaction/retry, metric selection and mock disclosure. It renders the guest, patient and caregiver V2 routes with a fixture API; those fixtures never contact Laravel, Firebase or an LLM. Captures are viewport reviews, not full-length golden comparisons or physical-device screenshots.

The 37 Python tests cover internal service authentication, typed consent boundaries, caregiver context exclusions, longitudinal trends and missing data, explicit mock labeling, provider failure behavior, support routing, catalog-bound recommendation IDs, RAG evidence/citations, patient-supplied report concerns, body limits and timezone validation. RAG tests use in-memory Qdrant and a deterministic test embedder.

## Still not executed

- Full networked Flutter on a physical device → Laravel → FastAPI demo. Docker Compose startup and separate HTTP service flows are now verified below.
- Live LLM inference, downloaded embedding/emotion weights, or retrieval against an approved populated knowledge base.
- Physical-device Android/iOS behavior, signed release builds, FCM delivery and native PDF export.
- Clinical accuracy, live-provider safety and real-world retrieval-quality evaluation.

These limits do not negate the executed component tests, but component tests and an APK build do not establish an end-to-end production deployment. Design decisions and the 15-reference mapping are recorded in [STITCH_V2_AUDIT.md](STITCH_V2_AUDIT.md).

## Navigation regression — 10 October 2026

A user-reported Navigator/GlobalKey error exposed a gap in the initial widget tests: those tests opened most routes independently with `go`, rather than following all in-app links with an existing navigation stack.

[Diagnostic run 38025341920](https://github.com/scootar-dev/hopely-care/actions/runs/38025341920) reproduced a duplicate-page-key assertion on the previous application code by tapping Home → Tools Kesehatan → Jadwal Perawatan. The original patient shell remained below Tools; pushing a destination in that same shell attempted to place its page/navigator key in the root stack a second time. Later exceptions in that failed test run are not treated as independently proven defects.

`openAppDestination` now uses `go` for the five main tabs and `push` for secondary screens. Both the Tools links and the shared `ActionLink` follow this rule, covering the same pattern at Check-in saved → Lihat pola catatanku. Main-tab paths are shared with the bottom navigation bar. Backend, database, authentication and consent rules are unchanged by this fix.

Four regression flows are added in `mobile/test/navigation_flow_test.dart`: Home → Tools → treatment → Home; Home → check-in → save → Insight; journal editor → privacy → Home; caregiver profile → privacy → dashboard. The tests check actual taps, exceptions, selected tabs and a single surviving application shell, alongside the 11 existing tests. The PR's subsequent Actions checks report the result for the revised code.

To run the update locally, stop the running Flutter process, fetch/pull `codex/stitch-v2-completion`, run `flutter pub get` in `mobile`, and start `flutter run` again with the same API endpoint used previously. A full restart reconstructs the navigation stack after this routing change.

## Profile photos and invitations — 11 October 2026 (Asia/Jakarta)

[Actions run 38072203173](https://github.com/scootar-dev/hopely-care/actions/runs/38072203173) passed for application commit `33e7f94`. All five jobs succeeded:

- Flutter analyze: no issues. **23 Flutter tests** passed. Both Home and Profile invitation entry points were tapped through to creation/display of a synthetic private invitation token. Photo tests cover explicit preview confirmation, upload, replacement, leaving/reopening Profile, removal, cancellation, and account switching without displaying another account's photo.
- Laravel: **19 tests / 79 assertions** on each of MySQL and SQLite. New tests verify authenticated photo ownership, attempted owner-ID spoofing, encrypted private storage, invalid/oversized uploads, replacement/removal, and account-deletion cleanup. Invitation tests exercise real API creation, correct patient ownership, email binding, single-use acceptance, revocation, and private defaults. Existing Patient accounts cannot be invited as caregivers; an unregistered email can be invited before registration.
- FastAPI: the existing 37 tests and Ruff check passed; no AI provider behavior changed.
- Docker HTTP smoke: startup, email registration/login, logout/token revocation, consent checks, Laravel → FastAPI mock chat, persisted messages and cleanup passed. This smoke does not exercise the OS photo picker.
- Debug APK built successfully: [APK artifact](https://github.com/scootar-dev/hopely-care/actions/runs/38072203173/artifacts/11677785024). The APK uses the **Android Emulator** URL `http://10.0.2.2:8000/api`. For a physical phone over USB, build locally with `API_BASE_URL=http://127.0.0.1:8000/api` and `adb reverse tcp:8000 tcp:8000`.
- Synthetic route render artifacts: [stitch-v2-screens](https://github.com/scootar-dev/hopely-care/actions/runs/38072203173/artifacts/11677054140). These are widget captures, not photos/screenshots from the user's phone.

The following bookkeeping commit records the exact Flutter dependency lockfile and formatter output used by the successful build, updates the API contract/status documentation, and removes the temporary CI formatting report. It does not change feature behavior.

Physical Android/iOS gallery access, Android activity recovery, and registration/login on the user's Windows/XAMPP setup remain separate device checks. Live AI, FCM, and an approved RAG corpus remain unverified. No community or admin dashboard is claimed implemented. The specific report that Home's invitation button fails has not reproduced in these tests; form validation and error messages have been made actionable without claiming a confirmed device-specific root cause.
