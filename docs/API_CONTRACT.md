# Laravel API contract — MVP v0.1
Base: `/api`. JSON request/response. Headers: `Accept: application/json`, `Content-Type: application/json`, `Authorization: Bearer <Sanctum token>` except register/login. User/resource IDs are UUID strings. IDs do not replace authorization checks.

## Envelope and errors
Success HTTP 200 (create record/register/invite: 201):
```json
{"success":true,"message":"OK","data":{}}
```
Collections of core records return `data.items`, `data.page`, `data.last_page`, 30 items/page. Pass `?page=2` to paginate. Other list endpoints return arrays in `data`. Delete/logout return `data:null`.

Errors: 401 unauthenticated, 403 role/ownership/consent denial, 404 missing or unlinked resource, 409 concurrent change/invitation conflict, 422 field validation, 429 throttled, 503 AI unavailable, 500 generic internal failure. Error bodies contain no input echo or trace.
```json
{"success":false,"message":"Periksa kembali isian.","errors":{"mood_score":["Validation message"]}}
```
Date-only values: `YYYY-MM-DD` in patient timezone. Instants: ISO 8601 UTC. All scores are integers 1–5. Higher mood/energy/sleep/appetite/sleep_quality is better; higher anxiety/pain/fatigue/nausea/dizziness is worse. No wellbeing diagnostic score is produced.

## Authentication and settings
| Method/path | Body / result | Access |
|---|---|---|
| POST `/auth/register` | name≤100, email, password≥12, password_confirmation, role PATIENT/CAREGIVER → `{user,token}` | Public, 8/min/IP |
| POST `/auth/login` | email,password → `{user,token}` | Public, 8/min/IP |
| POST `/auth/logout` | none → null; revokes current token | Auth |
| GET `/me` | `{user,profile}` | Auth |
| DELETE `/me` | password → null; cascades account-owned data | Auth |
| PUT `/profile` | display_name,timezone; optional birth_year,cancer_context,treatment_phase,onboarding_completed | Patient + health consent |
| GET `/consents` | array of current consent states | Auth |
| PUT `/consents` | consent_type,accepted:boolean | Auth |

Consent types: HEALTH_DATA_PROCESSING, AI_JOURNAL_ANALYSIS, AI_CHAT_CONTEXT, CAREGIVER_WELLBEING_SHARE, CAREGIVER_ALERT. Consent version is server-owned `1.0`. Revocation invalidates stored derived analysis; analysis persistence checks the consent revision under a user-row lock. No ADMIN registration route.

## Patient records
Each of `/checkins`, `/symptoms`, `/treatments`, `/journals` supports GET collection, POST create, GET `/{id}`, PUT `/{id}` partial update, DELETE `/{id}`. Patient role + health processing consent + server owner policy required. `id` and `user_id` cannot be set by caller. Read responses include resource data and timestamps, but omit `user_id`.

| Resource | Required create fields | Optional fields |
|---|---|---|
| checkins | checkin_date,mood_score,anxiety_score,energy_score,sleep_score,pain_score | optional_note≤4000,ai_analysis_allowed default false |
| symptoms | logged_at,pain,fatigue,nausea,dizziness,appetite,sleep_quality | optional_note≤4000 |
| treatments | title≤150,treatment_type≤80,scheduled_at | location≤500,notes≤4000,status scheduled/completed/cancelled |
| journals | content≤12000,journal_date | title≤150,ai_analysis_allowed default false |

Dates for check-ins/journals cannot be future; one check-in per patient per date. Symptom time cannot be future. Updating journal content invalidates previous analysis. Free text is owner-only.

Example POST `/checkins`:
```json
{"checkin_date":"2026-10-07","mood_score":2,"anxiety_score":4,"energy_score":2,"sleep_score":2,"pain_score":3,"optional_note":"Sulit tidur menjelang jadwal berikutnya.","ai_analysis_allowed":false}
```

## Patient AI and activities
AI routes are limited to 12/min/user, in addition to the API limit 120/min/user. Responses are wrapped in `data`. Exact typed engine outputs are in `AI_OPENAPI.json`.

| Method/path | Request | Result |
|---|---|---|
| POST `/journals/{id}/analyze` | none; global analysis + per-entry permission | primary_emotion,scores,themes,confidence,metadata |
| POST `/checkins/{id}/analyze` | none; same consent; nonempty optional note | emotion response |
| POST `/ai/chat` | message≤4000, optional session_id owned by caller | reply,support_intent,suggested_activity=null,safety_signal,metadata,session_id |
| GET `/chat/sessions` | none | latest 30 sessions |
| GET `/chat/sessions/{id}/messages` | owned session | sender,content,safety_level,created_at |
| GET `/insights?days=14` | days in 7,14,30 | period_days,recorded_days,coverage,trends,metrics,series,significant_changes,contextual_patterns,emotion_summary,contains_mock_signals,overall_direction,metadata |
| GET `/activities` | none | active curated library with steps and review status |
| GET `/activities/recommended` | none | array of `{id,activity,reason,metadata}` |
| POST `/activities/{id}/complete` | **id is recommendation ID** returned above | updated owned recommendation |
| POST `/doctor-summary` | days in 7,14,30; optional reported_concerns≤5 strings≤1000 | id,period,recorded_days,wellbeing,symptom_patterns,reported_concerns,treatment_context,questions_patient_may_want_to_discuss,disclaimer,metadata |
| POST `/knowledge/query` | question≤2000 | answer,sources[],confidence,metadata |

Chat requires AI_CHAT_CONTEXT. No journal text is added to companion context; only permitted derived signals. History is capped at 8 messages; numerical context at 7 days for chat and 14 days for activity ranking. Doctor summary never reads private writing automatically. User-entered report concerns are included verbatim and not treated as model-inferred diagnoses.

`metadata.mode` is `mock`, `live`, or `statistical`; `model_version`, `method`, optional `fallback` remain visible. Model confidence is not a clinical probability. Safety signals are NONE/CONCERN/URGENT; an urgent signal is support routing, not a diagnosis.

## Care circle and caregiver
| Method/path | Body/result | Access |
|---|---|---|
| POST `/caregivers/invite` | email,relationship_label → id,invitation_token,expires_at | Patient + health |
| GET `/caregivers` | links and permission objects; excludes token hashes | Patient + health |
| PUT `/caregivers/{id}/permissions` | all five booleans below | Patient owning link |
| DELETE `/caregivers/{id}` | revoke link and pending token | Patient owning link |
| POST `/caregivers/accept` | token → null | Intended caregiver email, pending and unexpired invite |
| GET `/caregiver/patients` | accepted patients: patient_id,name,relationship_label | Caregiver |
| GET `/caregiver/patients/{id}/summary` | allowed fields only | Accepted caregiver + patient consent |
| POST `/caregiver/patients/{id}/coach` | message≤2000 → support_message,communication_tip,suggested_action,metadata | Same; context filtered before FastAPI |

All flags default false: `can_view_wellbeing_summary`, `can_view_treatment_schedule`, `can_receive_support_alert`, `can_view_symptom_summary`, `can_view_activity_status`. Summary requires current HEALTH_DATA_PROCESSING and CAREGIVER_WELLBEING_SHARE. Flags add `wellbeing_summary`, `treatment_schedule`, `symptom_summary`, `activity_status`; forbidden fields are absent, not merely hidden by Flutter. Alerts separately require CAREGIVER_ALERT and can_receive_support_alert. No endpoint exposes journals/chats to caregivers.

## Notifications and admin
| Method/path | Request/result |
|---|---|
| POST `/devices` | token≤4096,platform android/ios → device ID |
| DELETE `/devices/{id}` | current user's token registration removed |
| GET `/notifications` | latest 50 generic notifications |
| PUT `/notifications/{id}/read` | owned notification read timestamp |
| POST `/admin/knowledge/ingest` | reviewed source metadata + text≤200000; ADMIN only |
| POST `/admin/activities` | title,description,category,duration_minutes,suitability_tags[],steps[],medically_reviewed,active; optional contraindication_notes |
| PUT `/admin/activities/{id}` | same activity fields, ADMIN only |

Knowledge metadata: source_id, title, publisher, document_version, reviewed_by, reviewed=true; optional source_url,published_at. Library source integrity and clinical review are operator responsibilities; `reviewed=true` is never silently inserted on a user's behalf.

## Internal FastAPI boundary
`/health` is public within the private service network. POST `/v1/ai/companion`, `/emotion/analyze` under `/v1/ai`, `/trend/analyze`, `/recommendations`, `/doctor-summary`, `/caregiver-coach`; plus `/v1/rag/query` and `/v1/knowledge/ingest`. All POSTs require constant-time internal key authentication and strict Pydantic schemas (`extra=forbid`). See full paths in AI_OPENAPI.json. Errors: `{success:false,error:{code,fields?}}`; body/PHI is never included.
