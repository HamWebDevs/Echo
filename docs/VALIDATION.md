# Touch and POP preview 0.5.0

**68 core checks and 44 UI checks pass (112 total).** New coverage includes full-screen floating touch, second-finger ownership, release over HUD buttons, button input priority, fixed joystick bounds, viewport fit, music toggles, POP charge/range, collision removal, historical replay visibility and exact respawn/grace boundaries. POP uses the same deterministic rules in both modes; daily records now use rules v2. Local saves retain existing progress and receive validated control defaults.

The Kotlin bridge and Android APK/AAB build successfully. Native sharing now supports text invitations and a public URL on image shares. Browser captures include actual touch gestures for both joystick layouts and an actual POP applied after a simulated run. Android phone touch feel, audio output, sharing destinations and performance remain device-test requirements; automated checks do not establish those results or human retention.

Public downloads use GitHub HTTPS releases, not workspace links. Signing limitations described below still apply. APK checksums and sizes are supplied in the release manifest. Older records below describe earlier versions only.

# Journal preview 0.4.0

**57 core checks and 30 UI checks pass (87 total).** New coverage verifies permanent milestone progress, multiple goals in one run, no repeated sticker announcements, old-save migration, malformed new fields, tutorial exclusion, five-run history, exact medal thresholds and daily rollover without losing permanent stickers. The journal and pre-run medal prompt are included in UI checks.

The earlier workspace download link failed in the user's Android chat client. The 0.3.0 preview was published as a public GitHub prerelease, and an unauthenticated ranged HTTPS request returned HTTP 206 and the APK ZIP signature. Version 0.4.0's workflow publishes all downloads after uploading them, rather than leaving an owner-only draft. Native phone performance and Play billing still require testing.

A repository-secret setup attempt for stable preview signing was denied by GitHub (HTTP 403). The workflow supports an owner-provided ECHO_PREVIEW_KEY secret; otherwise CI development signatures may differ between builds. Uninstalling to change signing keys removes local progress. This is not a production signing setup.

# Pal progression preview 0.3.0

Prepared 2 November 2026. **44 core checks and 28 UI integration checks pass (72 total)**. New coverage verifies multiple pal unlocks in one run, no repeat announcement on the next run, saved equipment selection, refusal to equip locked/invalid characters, and rechecking purchase access after a preview opens. The rules version and save schema remain unchanged.

The UI adds animated portraits with a reduced-motion alternative, character previews, named unlock progress and immediate equip-and-play for newly earned pals. High-contrast rendering now applies to the characters themselves. Replay and share cards preserve the selected look.

Current screenshots are actual browser renders. The unlock screenshot is a fresh-profile fixture whose progress comes from the simulated run shown. Showcase clips use scripted steering. The older validation records below remain historical evidence; phone performance, native sharing, purchases and player retention still require real-device/player testing.

# Cartoon preview 0.2.0

The cartoon presentation retains the same rules and save schema. All 40 core checks and 21 UI checks pass after the character, typography, interaction-animation and audio changes. Current screenshots and clips are generated from the real browser build. Physical-device validation, native sharing and billing remain outstanding. APK sizes and hashes for each delivered build are recorded in its manifest.

The record below describes the preceding 0.1.0 package; it is retained as historical evidence, not a claim that its native checks cover every later build.

# Validation record — Project ECHO 0.1.0

Prepared 1 November 2026 for HamWebDev. This records observed checks for the supplied development artifacts; it does not establish production readiness or player retention.

## Automated and browser verification

- Godot 4.6.3: **40 core checks and 21 UI integration checks passed**. Coverage includes deterministic daily targets, 10,000 target placements, collision timing and grace, replay history, persistence recovery, real screen-touch dispatch, entitlement callback ordering, pause/resume, retry and completed-run progression.
- The browser export rendered seven captured screens and three 15-second showcase clips with **zero captured browser console/page errors**.
- Screenshots are actual Godot renders. Showcase footage uses scripted steering through the real rules, so it is not evidence of human enjoyment, difficulty or retention.
- Kotlin native services compiled against Godot 4.6.3, RevenueCat 10.15.1 and Firebase Analytics 23.0.0. Resolved Play Billing Library: 8.3.0.
- The source ZIP was extracted into a fresh directory without import caches. Both suites passed there again: **61 checks**. Source and store ZIP integrity checks passed, and no signing keys, private service configuration or build caches were included.

## Android package verification

| Check | Observed result |
|---|---|
| Optimized preview APK | 67,575,659 bytes; signature verification passed; Android development certificate |
| Unsigned release AAB | 56,380,153 bytes; bundletool validation passed |
| Minimum / target Android API | 28 / 36 |
| Native architectures | arm64-v8a and x86_64 |
| APK ZIP alignment | `zipalign -c -P 16 -v 4` passed |
| Native ELF alignment | All four native libraries in both APK and AAB passed 16 KiB PT_LOAD alignment and offset/address congruence checks |

The preview compresses native libraries, so ZIP alignment does not directly test those library entries. The independent ELF checks cover their load-segment alignment. A physical device or emulator using 16 KiB memory pages is still required for runtime verification.

The optimized APK installed in the Android API 36 software emulator. Android launched its activity and registered the EchoServices plugin. The initial emulator GPU backend failed to link stock Godot shaders due to its uniform-vector limit. Switching the emulator to ANGLE/SwiftShader (`-gpu swangle`) rendered the home screen correctly. Android System UI became unresponsive under software emulation during further interaction checks, so native touch navigation and sharing are not recorded as passed. The final rebuild changes only startup styling: it removes the stock engine splash image and uses the game's dark background. Its startup appearance still needs verification on a phone.

## Checks still required before launch

- Physical-phone controls, audio focus, lifecycle, thermal/battery behavior, 60 fps and startup-time targets.
- Native sharing to real target apps and successful/cancelled/pending/restored/refunded purchases through Play's internal testing track.
- Independent playtests and measured retention. No claim that the game is commercially validated or “addictive” has been established.
- Final brand review, support email, hosted privacy policy, owner service configuration, production signing and Play Console declarations.

The release preflight correctly blocks submission for missing support email, privacy URL, cleared branding, service configuration and the unfinished privacy draft. These are explicit launch gates, not gameplay test failures. See [RELEASE.md](RELEASE.md) for the complete procedure.

The supplied APK is for installation and testing. The unsigned AAB must be signed with the owner's upload key before submission. Neither artifact has been published to Google Play.
