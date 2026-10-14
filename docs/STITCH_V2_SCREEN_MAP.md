# Complete Stitch V2 visual mapping

14 October 2026. Source: codex/stitch-v2-completion at cb4345f. Existing Support Circle is preserved by merge 39defb9. Main is unchanged. This replaces the old 15-screen inventory, not the engineering audit.

All 57 PNGs and 12 HTML exports were inspected. Status records the baseline, not completion. Flutter paths are relative to mobile/lib/features; missing routes are implementation targets.

| Stitch screen | Flutter file | Route | Baseline status | API dependency |
|---|---|---|---|---|
| `1. Splash Screen.png` | `auth/onboarding_screen.dart` | `/splash` | perlu diperbaiki | Session; local navigation |
| `10. Daily Check-In.png` | `checkin/checkin_screen.dart` | `/checkin` | perlu diperbaiki | checkins/symptoms CRUD; history missing |
| `11. Check-In Success.png` | `checkin/checkin_screen.dart` | `/checkin/saved` | perlu diperbaiki | checkins/symptoms CRUD; history missing |
| `11. Perjalanan Perawatan.png` | `treatment/treatment_screen.dart` | `/treatment` | perlu diperbaiki | treatments CRUD; detail route missing |
| `12. Insight - Tren Emosi & Gejala.png` | `insights/insights_screen.dart` | `/insights` | perlu diperbaiki | insights?days=7/14/30 |
| `12. Symptom Tracker.png` | `checkin/checkin_screen.dart` | `/symptoms` | perlu diperbaiki | checkins/symptoms CRUD; history missing |
| `13. Profil Pasien & Pengaturan.png` | `settings/settings_screen.dart` | `/profile` | perlu diperbaiki | me, profile, avatar, consents |
| `13. Tracking History.png` | `checkin/checkin_screen.dart` | `/history` | belum ada | checkins/symptoms CRUD; history missing |
| `14. Treatment Journey.png` | `treatment/treatment_screen.dart` | `/treatment` | perlu diperbaiki | treatments CRUD; detail route missing |
| `15. Treatment Detail.png` | `treatment/treatment_screen.dart` | `/treatment/:id` | belum ada | treatments CRUD; detail route missing |
| `16. Add Treatment.png` | `treatment/treatment_screen.dart` | `/treatment/new` | perlu diperbaiki | treatments CRUD; detail route missing |
| `17. Hopely AI.png` | `ai_companion/chat_screen.dart` | `/chat` | perlu diperbaiki | ai/chat, chat/sessions; voice absent |
| `18. Chat Conversation.png` | `ai_companion/chat_screen.dart` | `/chat` | perlu diperbaiki | ai/chat, chat/sessions; voice absent |
| `19. Journal Home.png` | `journal/journal_screen.dart` | `/journal` | perlu diperbaiki | journals CRUD/analyze; stored reflection read missing |
| `2. Welcome Screen.png` | `auth/onboarding_screen.dart` | `/welcome` | perlu diperbaiki | Session; local navigation |
| `20. Write Journal.png` | `journal/journal_screen.dart` | `/journal/new` | perlu diperbaiki | journals CRUD/analyze; stored reflection read missing |
| `21. Journal Reflection.png` | `journal/journal_screen.dart` | `/journal/:id/reflection` | belum ada | journals CRUD/analyze; stored reflection read missing |
| `22. Emotional Insights.png` | `insights/insights_screen.dart` | `/insights` | perlu diperbaiki | insights?days=7/14/30 |
| `23. Insight Detail.png` | `insights/insights_screen.dart` | `/insights/detail` | belum ada | insights?days=7/14/30 |
| `24. Support Activities.png` | `activities/activities_screen.dart` | `/activities` | perlu diperbaiki | activities/recommended, catalog, completion |
| `25. Activity Detail.png` | `activities/activities_screen.dart` | `/activities/:id` | perlu diperbaiki | activities/recommended, catalog, completion |
| `26. Community Home.png` | `community/presentation/community_home.dart` | `/community` | perlu diperbaiki | CommunityRepository: memberships, feed, post, comment, reaction, report, block, moderation |
| `27. Community Discovery.png` | `community/presentation/community_home.dart` | `/community/discover` | perlu diperbaiki | CommunityRepository: memberships, feed, post, comment, reaction, report, block, moderation |
| `28. Community Detail.png` | `community/presentation/community_detail.dart` | `/community/groups/:id` | perlu diperbaiki | CommunityRepository: memberships, feed, post, comment, reaction, report, block, moderation |
| `29. Community Feed.png` | `community/presentation/community_home.dart` | `/community/feed` | perlu diperbaiki | CommunityRepository: memberships, feed, post, comment, reaction, report, block, moderation |
| `3. Onboarding - Slide 1.png` | `auth/onboarding_screen.dart` | `/onboarding` | perlu diperbaiki | Session; local navigation |
| `3. Onboarding - Slide 2.png` | `auth/onboarding_screen.dart` | `/onboarding` | perlu diperbaiki | Session; local navigation |
| `3. Onboarding - Slide 3.png` | `auth/onboarding_screen.dart` | `/onboarding` | perlu diperbaiki | Session; local navigation |
| `30. Create Post.png` | `community/presentation/community_compose.dart` | `/community/compose` | perlu diperbaiki | CommunityRepository: memberships, feed, post, comment, reaction, report, block, moderation |
| `31. Post Detail.png` | `community/presentation/community_post_detail.dart` | `/community/posts/:id` | perlu diperbaiki | CommunityRepository: memberships, feed, post, comment, reaction, report, block, moderation |
| `39._doctor_summary_home/screen.png` | `doctor_summary/summary_screen.dart` | `/doctor-summary` | perlu diperbaiki | POST doctor-summary; PDF; stored report reads missing |
| `4. Role Selection.png` | `auth/auth_screen.dart` | `/role` | perlu diperbaiki | auth/register, auth/login; password reset missing |
| `40._report_period/screen.png` | `doctor_summary/summary_screen.dart` | `/doctor-summary/new` | perlu diperbaiki | POST doctor-summary; PDF; stored report reads missing |
| `41._report_preview/screen.png` | `doctor_summary/summary_screen.dart` | `/doctor-summary/:id` | perlu diperbaiki | POST doctor-summary; PDF; stored report reads missing |
| `42._trusted_knowledge/screen.png` | `knowledge/knowledge_screen.dart` | `/knowledge` | perlu diperbaiki | knowledge/query; no reviewed article catalog |
| `43._article_detail/screen.png` | `knowledge/knowledge_screen.dart` | `/knowledge/articles/:id` | belum ada | knowledge/query; no reviewed article catalog |
| `44._notifications/screen.png` | `settings/settings_screen.dart` | `/notifications` | perlu diperbaiki | me, profile, avatar, consents |
| `45._profile_main/screen.png` | `settings/settings_screen.dart` | `/profile` | perlu diperbaiki | me, profile, avatar, consents |
| `46._edit_profile/screen.png` | `settings/settings_screen.dart` | `/edit-profile` | perlu diperbaiki | me, profile, avatar, consents |
| `47._treatment_profile/screen.png` | `settings/settings_screen.dart` | `/treatment-profile` | belum ada | treatments CRUD; detail route missing |
| `48._privacy_ai_settings/screen.png` | `settings/settings_screen.dart` | `/privacy` | perlu diperbaiki | me, profile, avatar, consents |
| `49._notification_settings/screen.png` | `settings/settings_screen.dart` | `/notification-settings` | belum ada | me, profile, avatar, consents |
| `5. Login.png` | `auth/auth_screen.dart` | `/login` | perlu diperbaiki | auth/register, auth/login; password reset missing |
| `50._data_account/screen.png` | `settings/settings_screen.dart` | `/data-account` | belum ada | me, profile, avatar, consents |
| `6. Register.png` | `auth/auth_screen.dart` | `/register` | perlu diperbaiki | auth/register, auth/login; password reset missing |
| `7. Forgot Password.png` | `auth/auth_screen.dart` | `/forgot-password` | belum ada | auth/register, auth/login; password reset missing |
| `8. Privacy & Consent.png` | `settings/settings_screen.dart` | `/privacy` | perlu diperbaiki | me, profile, avatar, consents |
| `9. Patient Home.png` | `home/home_screen.dart` | `/home` | perlu diperbaiki | checkins, treatments, activities |
| `Beranda Mode Pendamping (Caregiver Dashboard).png` | `care_circle/care_circle_screen.dart` | `/caregiver` | perlu diperbaiki | caregivers invite/accept/permissions; scoped caregiver summary/coach |
| `Detail Profil Pendamping (Caregiver View).png` | `care_circle/care_circle_screen.dart` | `/care-circle` | perlu diperbaiki | caregivers invite/accept/permissions; scoped caregiver summary/coach |
| `Hopely AI - Mode Suara Penuh (Voice Modal).png` | `ai_companion/chat_screen.dart` | `/chat` | belum ada | ai/chat, chat/sessions; voice absent |
| `Hopely AI Chat - Conversational Haven (Audio Enhanced).png` | `ai_companion/chat_screen.dart` | `/chat` | perlu diperbaiki | ai/chat, chat/sessions; voice absent |
| `Hopely AI Chat - Conversational Haven.png` | `ai_companion/chat_screen.dart` | `/chat` | perlu diperbaiki | ai/chat, chat/sessions; voice absent |
| `Hopely AI Chat - Guided Coping & Tools.png` | `ai_companion/chat_screen.dart` | `/chat` | perlu diperbaiki | ai/chat, chat/sessions; voice absent |
| `Notifikasi WhatsApp - Verifikasi Undangan Pendamping.png` | `care_circle/care_circle_screen.dart` | `/caregiver/connect` | perlu diperbaiki | caregivers invite/accept/permissions; scoped caregiver summary/coach |
| `Tambah Pendamping - Kode & Barcode QR.png` | `care_circle/care_circle_screen.dart` | `/care-circle` | perlu diperbaiki | caregivers invite/accept/permissions; scoped caregiver summary/coach |
| `Tambah Pendamping Baru.png` | `care_circle/care_circle_screen.dart` | `/care-circle` | perlu diperbaiki | caregivers invite/accept/permissions; scoped caregiver summary/coach |

## Shared decisions

- HTML specifies Plus Jakarta Sans; primary #004AC6/#2563EB, background #F8F9FF, ink #0B1C30, panels #EFF4FF. Use native widgets, 16/24px spacing, wrapping and 48px touch targets. Correct export overflow and repeated incorrect headers.
- Keep five tabs Beranda / Perjalanan / Hopely AI / Insight / Profil. Community, journal, tools, My Communities, safety and moderation remain accessible.
- Master scores stay 1–5. Sleep quality is not hours. Never fabricate identities, counts, treatment progress, prescriptions, clinical verification, medical articles, HIPAA/E2E or 24-hour guarantees from sample designs.
- Journal/chat stay private; caregiver reads remain consent/permission filtered. Invitations remain secure 48-character email-bound single-use tokens, not short sample codes.
- No simulated success for voice, WhatsApp business, clinical chat or emergency integration. Unsupported integrations must be reported honestly.
- Forgot password needs a real broker/email transport; history needs filtered records; journal reflection/report archive need owner-scoped reads of stored results. Preferences must be persisted and enforced.
- Native artwork cropping may show decorative illustration only. All forms/buttons/text are native accessible widgets.

## Verification

Record checks after execution on changed code. Baseline green CI does not validate new work. Physical-device networking, live AI, email delivery and push need their configured services and separate evidence.
