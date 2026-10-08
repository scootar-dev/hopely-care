# Demo competition — synthetic only

Prerequisite: run the Docker/Flutter instructions; seed once; use your local DEMO_PASSWORD. Keep MOCK_AI_MODE=true for an offline walkthrough and retain the visible demo label. Use a real provider only after configuration and evaluation; never call fixtures real AI.

1. Sign in as patient.demo@hopely.invalid. The name says Demo. Home shows the next treatment from stored data.
2. Open Check-In. Change today's values to mood 2, anxiety 4, energy 2, sleep 2, pain 3. Save; it updates today's seeded record rather than duplicating it.
3. Open private journal. Write the example concern from the master prompt. Global analysis consent is active only on the synthetic seeded account; turn on that journal's own analysis switch. Save and inspect mock/live metadata.
4. Open Wawasan → 14 Hari. Inspect recorded days, increasing anxiety and lower sleep, with missing-day handling and no diagnostic label.
5. Open Hopely AI, send “Aku takut banget untuk besok.” Context contains the upcoming treatment and only recent consented data. Mock mode demonstrates wiring; live mode is required to judge semantic quality.
6. Open Activities. Choose from the curated database and mark one complete; no invented activity ID is accepted.
7. Log out and sign in as caregiver.demo@hopely.invalid. Wellbeing/symptoms are allowed. Treatment schedule is intentionally disabled. Journal/chat remain absent.
8. Ask the caregiver coach how to offer support. It receives only permitted aggregate fields.
9. Patient generates a 14-day doctor summary. Optionally type up to five concerns specifically for the report. Preview/export PDF yourself; no automatic hospital send occurs.
10. Revoke caregiver sharing or a per-link permission. Re-open caregiver summary and confirm access changes. Revoke AI journal consent; stored derived insights disappear.

Optional RAG scene requires a truly reviewed knowledge document and local embedding dependencies. An empty/low-confidence retrieval abstains. Optional push scene requires real Firebase configuration and an authorized test device.

Acceptance remains pending until the actual Laravel + MySQL + Flutter device flow passes. The Python suite alone does not establish end-to-end success or clinical efficacy.
