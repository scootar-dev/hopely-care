# Verification record — 9 October 2026 (UTC)

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

- Full networked Flutter → Laravel → FastAPI demo and complete Docker Compose startup.
- Live LLM inference, downloaded embedding/emotion weights, or retrieval against an approved populated knowledge base.
- Physical-device Android/iOS behavior, signed release builds, FCM delivery and native PDF export.
- Clinical accuracy, live-provider safety and real-world retrieval-quality evaluation.

These limits do not negate the executed component tests, but component tests and an APK build do not establish an end-to-end production deployment. Design decisions and the 15-reference mapping are recorded in [STITCH_V2_AUDIT.md](STITCH_V2_AUDIT.md).
