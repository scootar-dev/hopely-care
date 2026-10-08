# Database ERD
Public resource IDs use UUID primary keys. Every ownership/link foreign key cascades on account deletion. Timestamps and indexes are defined exactly in the migration. There is no redundant numeric ID + UUID pair. Diagrams are split by domain for readability.

## Identity and patient records
```mermaid
erDiagram
    direction TB
    users ||--o| patient_profiles : owns
    users ||--o{ daily_checkins : records
    users ||--o{ symptom_logs : records
    users ||--o{ treatments : schedules
    users {
        uuid id PK
        string email UK
        string password
        enum role
        bigint consent_revision
    }
    patient_profiles {
        uuid id PK
        uuid user_id FK,UK
        string display_name
        text cancer_context
        string timezone
        boolean onboarding_completed
    }
    daily_checkins {
        uuid id PK
        uuid user_id FK
        date checkin_date
        int mood_score
        int anxiety_score
        int energy_score
        int sleep_score
        int pain_score
        text optional_note
        boolean ai_analysis_allowed
        json emotion_signal
    }
    symptom_logs {
        uuid id PK
        uuid user_id FK
        datetime logged_at
        int pain
        int fatigue
        int nausea
        int dizziness
        int appetite
        int sleep_quality
    }
    treatments {
        uuid id PK
        uuid user_id FK
        string treatment_type
        datetime scheduled_at
        enum status
    }
```
Unique daily check-in key: `(user_id, checkin_date)`. Date semantics use patient timezone; timestamp instants are stored UTC. Symptom appetite/sleep_quality and check-in mood/energy/sleep are positive-direction scales; pain/anxiety/fatigue/nausea/dizziness are negative-direction scales.

## Private writing and AI context
```mermaid
erDiagram
    direction TB
    users ||--o{ journals : writes
    journals ||--o| journal_ai_insights : permits
    users ||--o{ chat_sessions : owns
    chat_sessions ||--o{ chat_messages : contains
    users ||--o{ ai_insight_snapshots : owns
    journals {
        uuid id PK
        uuid user_id FK
        date journal_date
        text content
        boolean ai_analysis_allowed
    }
    journal_ai_insights {
        uuid id PK
        uuid user_id FK
        uuid journal_id FK,UK
        string primary_emotion
        json emotion_scores
        json themes
        string model_version
    }
    chat_sessions {
        uuid id PK
        uuid user_id FK
        string title
    }
    chat_messages {
        uuid id PK
        uuid user_id FK
        uuid chat_session_id FK
        enum sender
        text content
        string safety_level
    }
    ai_insight_snapshots {
        uuid id PK
        uuid user_id FK
        date snapshot_date
        json report_json
        string model_version
    }
```
`report_json` stores the typed trend contract rather than duplicating evolving AI output fields in separate columns. Journal/chat free text uses encrypted casts. Snapshot and journal insight rows are deleted when consent is withdrawn.

## Caregiver authorization
```mermaid
erDiagram
    direction TB
    users ||--o{ consents : controls
    users ||--o{ caregiver_links : patient_or_caregiver
    caregiver_links ||--|| caregiver_permissions : restricts
    users ||--o{ audit_logs : acts
    consents {
        uuid id PK
        uuid user_id FK
        string consent_type
        string consent_version
        boolean accepted
        datetime accepted_at
        datetime revoked_at
    }
    caregiver_links {
        uuid id PK
        uuid patient_user_id FK
        uuid caregiver_user_id FK
        string invited_email
        enum invitation_status
        string invitation_hash UK
        datetime expires_at
    }
    caregiver_permissions {
        uuid id PK
        uuid caregiver_link_id FK,UK
        boolean can_view_wellbeing_summary
        boolean can_view_treatment_schedule
        boolean can_receive_support_alert
        boolean can_view_symptom_summary
        boolean can_view_activity_status
    }
    audit_logs {
        uuid id PK
        uuid actor_user_id FK
        string event
        string resource_type
        uuid resource_id
        json metadata
    }
```
Consents are unique by `(user_id, consent_type)`; latest state lives here, acceptance/revocation events live in metadata-only audit records. Invitation token hashes are nullable after acceptance/revocation, unique, one-use and bound to intended email. No journal/chat sharing flag exists in the MVP.

## Activities, reports and device delivery
```mermaid
erDiagram
    direction TB
    users ||--o{ activity_recommendations : receives
    support_activities ||--o{ activity_recommendations : selected_from
    users ||--o{ doctor_visit_reports : creates
    users ||--o{ device_tokens : registers
    users ||--o{ notifications : receives
    support_activities {
        uuid id PK
        string title
        string category
        int duration_minutes
        json steps
        json suitability_tags
        boolean medically_reviewed
        boolean active
    }
    activity_recommendations {
        uuid id PK
        uuid user_id FK
        uuid support_activity_id FK
        text reason
        json metadata
        datetime completed_at
    }
    doctor_visit_reports {
        uuid id PK
        uuid user_id FK
        date period_start
        date period_end
        text report_json
    }
    device_tokens {
        uuid id PK
        uuid user_id FK
        text token
        string token_hash UK
    }
    notifications {
        uuid id PK
        uuid user_id FK
        string notification_type
        string dedupe_key UK
        datetime read_at
    }
```
Sanctum additionally owns `personal_access_tokens` with UUID polymorphic tokenable keys and expiry. Qdrant is a separate non-patient knowledge store; its chunk payload schema is documented in `AI_ENGINE.md`.
