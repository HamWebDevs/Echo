# Release gates — HamWebDev / Project ECHO

## Current product scope

The core game, local progression, daily mode, menus, visual effects, audio, accessibility settings, replay and sharing are implemented. Native service integrations must be exercised with the owner's real test configuration. Do not describe the game as validated, commercially successful, trademark-cleared, or approved by Google Play.

## Owner configuration

- Developer: **HamWebDev**.
- Support email: **pending**. Set `config/app_metadata.json` and replace the marked contact field in the privacy document.
- Final app name and icon lock: **pending name/trademark and closest-competitor review**. Project ECHO is a codename. Afterloop was rejected because an existing game uses that name.
- Package: `com.hamwebdev.echo`. Verify availability and keep it stable after creating the store app.
- Privacy policy URL: **pending hosting**. Publish the completed policy on a publicly accessible HTTPS page and add the URL to the app metadata and Play listing.
- Play developer account, RevenueCat app/product mapping, and Firebase configuration: **owner setup required**.
- Production upload key: **owner setup required**. Keep the keystore and passwords outside the repository. Enable Play App Signing, configure the release preset locally, set `package/signed=true`, and export a signed release AAB. The provided unsigned AAB and debug key are not production signing credentials.

## Billing test matrix

Use a Play internal test release, the final package ID, and licence testers. Capture outcomes; compilation is not a substitute for these tests.

| Scenario | Expected behaviour |
|---|---|
| Store disconnected/unconfigured | Core game remains available; no fabricated price or entitlement |
| Successful purchase | Confirmed `supporter` entitlement enables four skins, two themes and the sound palette |
| User cancellation | No entitlement; clear cancellation feedback |
| Pending payment | No entitlement until confirmation; retry/restore remain possible |
| App closed during payment | Refresh on resume/start reconciles the store result |
| Reinstall on same Play account | Explicit Restore reestablishes the permanent purchase |
| Device offline after verification | SDK-cached ownership remains usable; gameplay never blocks |
| Refund/revocation | A successful entitlement refresh removes supporter access and resets unsupported selections |
| Duplicate taps or callbacks | One transaction at a time; entitlement application is idempotent |
| Analytics disabled | No game usage events sent through the analytics bridge |

Confirm the store transaction is acknowledged through RevenueCat and that the Play console shows the expected purchase state. Confirm the resolved Billing Library version satisfies the policy in effect at submission.

## Device and lifecycle checks

Test at least one older 4 GB Android phone, one current midrange phone, and one recent Android device. Cover Android 9 and the current Android release, small and tall screens, screen cutouts and gesture navigation. Also run a 16 KB memory-page emulator/device test and validate native library alignment.

- Cold start under three seconds and retry under one second on the reference midrange phone.
- Sustained 60 fps during a 30-minute session, with acceptable heat and battery use. Record the device, OS, frame-time distribution and test conditions.
- Controls work with either thumb; a second touch does not steal the joystick. Release preserves heading, and focus loss clears held input.
- Calls, app switching, screen lock and audio focus changes pause safely. Countdown protects resumed play. Process termination preserves completed progress.
- Airplane-mode launch and both modes work offline. Changing date mid-run does not reassign the run to another day.
- Reduced motion removes decorative movement, not essential obstacle motion. Shape and contrast identify hazards without colour alone. Sound-off play remains understandable.
- Share a real score card to at least two Android share targets. Only the generated PNG is exposed through the content provider.
- Low storage, corrupted saves and interrupted writes do not overwrite valid backup progress.

## Independent playtest protocol

Recruit 20 people who have not seen the game. Do not coach them during the first run. Record device, time to understand controls, explanation of death, unprompted retries and specific confusion. Ask: “What were you trying to do?”, “What ended that run?”, and “Would you choose another run now?” Do not count prompted retries as voluntary.

Initial acceptance targets:

- 80% understand the objective and control within 30 seconds.
- 60% voluntarily play five runs.
- 80% accurately explain their death.
- No recurring untelegraphed or unreadable collision problem.

These targets are **not measured results**. If they fail, iterate on control feel and readability before spending on additional content. Allow up to two focused weeks; reconsider the mechanic if the second independent test still fails.

## Analytics and soft launch

Events implemented: `tutorial_start`, `tutorial_complete`, `run_start`, `run_end`, `retry`, `share`. Properties sent to Firebase are restricted to mode, rules version, score, sparks, duration, death cause and echo count. Movement histories, seeds, dates and raw purchase tokens are not sent through this bridge. Firebase may process its standard app/device information; review the actual SDK data inventory for the Play declaration.

Use the dashboard's store events for purchase conversion and revenue. Use Android Vitals for crash and ANR trends. Keep developer/tester traffic out of the acquisition cohort.

Release targets, not promises: at least 99.5% crash-free sessions; D1 retention 30%; D7 retention 10%. Evaluate retention only after at least 300 new users have completed the relevant observation windows. Report cohort size and uncertainty; opt-in analytics can introduce selection bias. Do not treat recruited closed testers as an unbiased acquisition cohort.

Start English-first in the US, UK, Canada, Australia and New Zealand. Monitor stability, tutorial exits, death causes, returns and purchase failures daily for the first week. Halt expansion for progress-loss or payment defects. On a first production release, limit countries before expanding; use staged rollout controls for subsequent updates where Play supports them. Keep the previous signed artifact and configuration for hotfixes; Android version codes must increase, so rollback normally requires a new higher-version build.

Do not buy traffic until measured retention and revenue support the acquisition cost.

## Store submission

- Confirm current target SDK, Billing Library, 16 KB support and signing requirements directly in Play Console.
- Complete the content rating questionnaire, target-audience declaration, app access instructions, Data Safety form, pricing and countries.
- Reconcile Data Safety with enabled Firebase/RevenueCat versions and consent settings; do not claim “no data collected” simply because gameplay works offline.
- If the developer account is subject to Google's newer personal-account testing rules, complete the required closed test (currently at least 12 continuously opted-in testers for 14 days) and apply for production access.
- Upload cleared branding, five real screenshots, feature graphic, final privacy URL and support contact.
- Run the release preflight, core/UI tests, native build and Play pre-launch report against the exact release candidate.

Reference policies: [target API](https://support.google.com/googleplay/android-developer/answer/11926878), [personal-account testing](https://support.google.com/googleplay/android-developer/answer/14151465), [16 KB support](https://developer.android.com/guide/practices/page-sizes), [billing security](https://developer.android.com/google/play/billing/security).
