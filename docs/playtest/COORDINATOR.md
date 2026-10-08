# Study protocol

Target: ten players over seven days. Recruitment, participation and retention are not established yet. The main question is whether anticipation, a reveal, a useful gain and visible ownership create a next reward the player wants.

## Before invitations

- Export the Android Debug preset in Godot. Record the APK SHA-256, source commit and version in EVIDENCE.md. Owner handles APK export; no desktop SDK installation is required from this agent.
- Supply a reachable HTTPS service using docs/ONLINE_SERVICE.md. Verify access from the actual phones, not just the host computer. Preserve its database throughout the study.
- Complete the device checklist. Verify update compatibility with the existing package/signing key and save. Never resolve a signature error by silently uninstalling.
- Assign P01–P10, the guild invite, APK location, feedback file location and a private feedback-sharing channel. Do not collect recovery keys or bearer tokens. Obtain participants' agreement to the study and explain what feedback is collected.
- Keep the build stable during the study. Record any unavoidable update and which participants received it.

## Seven days

Day one: observe one natural session and ask what reward they want next. Check installation and account recovery privately. Let players choose their pursuits.

Days two–six: leave play voluntary. Around day three ask for a short entry; ask about a satisfying or disappointing moment rather than assigning grinding tasks. Arrange one shared raid with at least three independently owned accounts, with different roles. Record actual preparation and settlement, including participants who miss it. Do not promise a win.

Day seven: collect an ending entry and ask which reward they still want, if any. Ask whether they would return without a reminder and why. Do not infer retention from that answer: it measures intent. Actual return observations must record their source and whether prompted.

## Interpret honestly

Use counts with denominators and missing responses: for example, 4 of 7 respondents wanted a specific next item, with 3 missing. Keep individual reasons and negative feedback. Distinguish an observed return, a stated intention and a scheduled study check-in. Do not present automated tests as evidence of enjoyment.

Look for identifiable desired rewards, remembered satisfying moments, gains that alter a pursuit or appearance, and self-directed next goals. Repeated “nothing to do,” unreadable screens, unrewarding duplicates or compulsory attendance are actionable failures.

## Feedback handling

The HTML stores answers locally and exports JSON only on request. It does not transmit analytics. Participant IDs are pseudonyms, not anonymity guarantees; free text can identify someone. Store shared exports privately, keep the identity mapping separate, and agree a retention/deletion date before collection. No payment details, credentials or real names are needed.
