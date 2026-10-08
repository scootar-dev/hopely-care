# Implementation and acceptance roadmap
The source tree follows phases 0–14. Source availability is separate from verified completion. See VERIFICATION.md for executed checks and blockers.

| Phase | Implementation | Acceptance gate |
|---|---|---|
| 0 | Architecture, ERD, contracts, Docker, repository | Resolve authority conflicts; inspect boot configuration |
| 1 | Sanctum, profiles, role routes, privacy and navigation | Register/login/logout; no admin self-registration |
| 2 | Check-in, symptoms, treatment CRUD | 1–5 validation, timezone uniqueness, ownership |
| 3 | Journal with per-entry permission | Private by default; two-level analysis opt-in |
| 4 | Internal FastAPI + provider interface | Key required; invalid output/timeout fail closed |
| 5 | Emotion analysis | Explicit mock/fallback metadata; schema validation |
| 6 | Longitudinal engine | Sparse/flat/declining/missing-date tests |
| 7 | Companion | Bounded context; no journal leakage; multi-turn session |
| 8 | Activity ranking and completion | Only curated IDs; completion owner check |
| 9 | Care circle | Expiring email-bound invite, revoke, all permissions |
| 10 | Caregiver summary and coach | Missing/revoked consent denies data; no raw notes |
| 11 | Curated RAG and ingestion | Reviewed-source filter, low-score abstention, citation checks |
| 12 | Doctor summary + PDF preview/export | 7/14/30-day period, patient-reported only |
| 13 | Device registration, FCM sender, reminder scheduler | Credentials required; generic payload; deduplication |
| 14 | Design, tests, synthetic seed, docs | Flutter/Laravel test and actual device demo |
| 15 | Community | Deferred; requires report/block/moderation |

## Technical risks
1. Missing SDK/runtime means source cannot be called a verified end-to-end build; CI gates and local setup are supplied.
2. Dependency installation/network access may block lockfiles; resolved dependencies must be committed once generated.
3. Live-model behavior needs evaluation; mock success is not evidence of clinical safety or AI quality.
4. Fourteen synthetic days demonstrate behavior but cannot validate generalization, calibration or clinical benefit.
5. Revocation cannot retract data already transmitted to a provider; reject in-flight persistence and document retention.
6. Qdrant/model startup and embedding downloads may be large; collection dimension follows configured model.
7. Screenshots omit many screens and original assets; extend the same design system and document approximations.
8. FCM and PDF sharing need real device/platform configuration. No unsolicited external message is sent during construction.
