# Privacy and safety requirements
| Boundary | Server enforcement |
|---|---|
| Patient data ownership | Sanctum + role + owner policy; no raw ID-based cross-user queries |
| Caregiver link | Single-use hashed invitation, intended email, expiry, accepted status |
| Sharing | Current consent AND link permission on every read and coach request |
| Journals | Encrypted, owner-only; no caregiver endpoint ever returns text |
| AI journal processing | Current AI_JOURNAL_ANALYSIS and record ai_analysis_allowed |
| Chat | Current AI_CHAT_CONTEXT; bounded history and context; never caregiver-visible |
| Consent withdrawal | Invalidate derived data, stop future processing; audit metadata only |
| Account deletion | Cascade records/links/devices; delete tokens; no source text in logs |
| Internal AI | Constant-time internal key check, private Compose network, bounded payloads |
| RAG | Only reviewed non-patient knowledge with traceable metadata |
| Alerts | Current CAREGIVER_ALERT plus can_receive_support_alert; generic message |

Do not log request bodies, provider payloads, journal/chat or validation input values. API debug is false by default. Infrastructure logging must follow the same rule. No app-level analytics SDK is included.

Data is self-reported and may be incomplete. AI support is not clinical assessment. Support activities are marked medically_reviewed=false until a real reviewer approves them. Real-patient deployment remains blocked on safety evaluation (including Indonesian crisis paraphrases and prompt injection), review of model/provider retention, encryption-key backup/rotation, healthcare content review, and operational incident procedures.

Pseudonymization is not anonymization: user UUIDs and longitudinal records can remain identifying. Never upload genuine patient records to demo environments. Synthetic demo accounts are generated only in non-production with an operator-supplied demo password.
