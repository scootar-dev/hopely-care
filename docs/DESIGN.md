# Stitch V2 visual contract

Primary visual reference: all 15 PNGs in `stitch v2/`. The five images in `docs/reference/` record an earlier version and no longer define the UI. Master requirements take precedence over illustrative data or unsupported actions in the designs. See [STITCH_V2_AUDIT.md](STITCH_V2_AUDIT.md) for the screen-by-screen mapping and conflict decisions.

- Primary blue `#004BD6`, dark blue `#0647C7`, lavender `#E8E3FF`, pale sky `#EFF3FF`, canvas `#F9F8FF`, ink `#12172B`.
- Rounded cards (20–26px), restrained shadows, pill labels, readable type, and generously spaced controls. The bundled DejaVuSans font is retained from the existing app.
- Calm, conversational Bahasa Indonesia. Patient navigation: Beranda, Perjalanan, Hopely AI, Insight, Profil. Journal and Tools remain accessible from Home and Profile.
- Splash/welcome/onboarding: heart-and-hands icon illustration, brief explanations of recording, private writing, and patient-controlled sharing; start, skip, role, and login actions work.
- Home: real user greeting, prominent check-in action, AI prompt chips, upcoming treatment, recorded mood and recommended activities. Empty states replace sample numbers.
- Check-in: five 1–5 selectors, mood icons, optional note and opt-in analysis, followed by a save confirmation.
- Companion: blue user and lavender assistant bubbles, existing private history and send flow, consent-aware composer, scrollable content with keyboard space.
- Insights: 7/14-day switch, recorded metric lines, descriptive findings, summary cards and doctor-summary CTA. Missing data stays missing.
- Journal: private entry cards, date and total count, pagination, editor, delete and consent-gated analysis; letter prompt opens the existing editor.
- Profile: actual identity, counts, accepted care-circle links, settings, privacy and logout/delete actions.
- Tools: real activity, knowledge, treatment, summary and symptom routes. No unimplemented breathing player or audio control is presented as working.
- Care circle: email-bound secure invitation, copy token, expiry, link states and granular permissions. Caregiver dashboard uses only permitted summaries; alerts use owned generic notifications.

Hero artwork is composed from Flutter icons because separate illustration assets were not supplied. Screenshot text is never clinical evidence. Unsupported Google login, calls, voice recording, public journal sharing, fabricated patient data and diagnostic/emergency claims are excluded. Existing backend authorization and consent rules remain authoritative for what appears on each screen.
