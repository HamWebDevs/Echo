# Project ECHO — HamWebDev

A portrait Android arcade game: collect sparks and dodge delayed echoes of your own movement. Built with **Godot 4.6.3**, GDScript, and a Kotlin Android plugin.

Project ECHO is a development name, not a cleared commercial brand. The package ID is `com.hamwebdev.echo`.

## What is implemented

- Fixed-step gameplay, six delayed echoes, advance warnings, spawn grace, swept collisions, timed collection, and increasing score multipliers.
- Endless mode and reproducible daily challenges keyed by UTC date and rules version.
- Floating touch joystick; keyboard support; tutorial; pause and countdown; death replay; instant retry; shareable score cards.
- Local personal records, nine base/earned signals, four supporter signals, two supporter arena themes, and an alternate sound palette.
- Original geometric visuals and synthesized audio, responsive portrait screens, high contrast, reduced motion, and sound/vibration settings.
- Atomic saves with backup recovery, no required account, and offline core gameplay.
- A compiled Android bridge for RevenueCat purchase validation/restoration, optional Firebase Analytics, and native image sharing.
- Automated gameplay and UI integration tests, Android build tooling, release preflight, privacy draft, and store copy.

**This is a playable development build, not a claim of production readiness.** Real billing tests, physical-device performance checks, independent playtests, retention measurement, final branding, and store approval remain release gates. Service credentials are not present; purchases are visibly unavailable until configured.

## Run

Open `project.godot` in Godot **4.6.3 stable**, import the assets, and press F6 on the main scene or F5 to run the project. No external packages are needed for the game itself.

On Android, install `build/android/project-echo-preview.apk`. It is an optimized release build signed with a development key. Core gameplay works without an internet connection.

See [the installation guide](docs/TESTING-THE-PREVIEW.md) for phone setup and [the validation record](docs/VALIDATION.md) for completed checks and remaining limitations.

Drag in the lower pad to steer. Movement begins only after a deliberate drag. Release to maintain heading. On a computer, use WASD or arrow keys; Esc pauses. Keyboard/mouse and native touch are supported.

## Verify

```sh
bash tools/test.sh
```

The runner fails on test failures **and** GDScript/runtime errors, because Godot can sometimes return a zero exit code after a script error. Tests use isolated save files and remove them afterward.

The core suite checks deterministic daily seeds and 10,000 target placements, collection deadlines, collision grace boundaries, fast crossing collisions, bounded replay history, unlocks, separate records, atomic writes, and corrupted-save recovery. The UI suite exercises navigation, real input consumption, pause/resume, results, and retries.

## Browser preview

Install matching Godot export templates, then:

```sh
mkdir -p build/web
godot --headless --path . --export-debug "Web Preview" build/web/index.html
python -m http.server 8765 --directory build/web
```

Open `http://localhost:8765`. The browser preview uses the same Godot game code. It is a testing convenience; purchases are Android-only. Browser score sharing downloads a PNG.

To reproduce screenshots and silent gameplay draft clips:

```sh
npm install --prefix tools
npx --prefix tools playwright install chromium ffmpeg
node tools/capture_web.cjs --video
```

Keep the preview server running on port 8765. The capture tool uses `/usr/bin/chromium` when present, otherwise Playwright's installed Chromium; set `CHROMIUM_PATH` to select another executable. It uses real simulation with scripted steering for showcase footage. This is demonstration footage, not human playtest evidence.

## Android build

The supplied command-line build helpers target **Linux** (SDK archive names, executable names and default settings paths). Requirements: JDK **17** (including `javac`), Godot 4.6.3 with export templates, Android platform 36, build-tools 36.0.0 and 36.1.0, and platform-tools. Gradle 8.11.1 is pinned through the included wrapper. The Godot project can also be opened on other supported desktop platforms, with their Android tooling configured in the editor.

Install the SDK packages through Android Studio, or use the checksum-verifying helper with Google's official archives:

```sh
python tools/setup_android.py /absolute/path/to/android-sdk
python tools/build_android.py --sdk /absolute/path/to/android-sdk --java /absolute/path/to/jdk17 --aab
```

The helper compiles the Kotlin bridge, installs the generated Godot Android template, and exports:

- `build/android/project-echo.apk`: signed **debug** APK for direct testing.
- `build/android/project-echo-preview.apk`: smaller, optimized APK signed with the same **development key**, suitable for hands-on testing.
- `build/android/project-echo-unsigned.aab`: **unsigned** release bundle for review; requires your upload key before Play submission.

The build helper preserves unrelated Godot editor settings while setting the SDK/JDK and development signing paths. SDK downloads remain subject to Google's SDK licence. On a proxy-managed machine it uses the configured HTTP proxy and the machine CA trust; it does not disable TLS verification.

Do not change the package ID after establishing the Play application. The current bundle is Android 9+ (minimum API 28), targets API 36, and contains arm64-v8a and x86_64 native binaries.

## Connect purchases and analytics

Copy `config/services.example.json` to ignored `config/services.json`. Supply only the client configuration values shown in that file. Never put a Google service-account key, RevenueCat secret API key, or signing password in the app.

1. In Google Play, create a **non-consumable one-time product** with ID `echo_supporter`. Initial proposed US price: $3.99; configure localized prices in Play.
2. Connect the Android app to RevenueCat. Create entitlement `supporter`, attach `echo_supporter`, and place the product in a package in the **current offering**. Use the Android public SDK key in the client configuration.
3. Configure the Play credentials and purchase notifications in the RevenueCat dashboard, not in the source tree. Set restore behaviour to allow a purchaser to restore onto a new anonymous installation.
4. For opt-in analytics, create the Firebase Android app for the same package ID and fill in its public app ID, API key, and project ID.
5. Rebuild and test through a Play internal test track with licence testers. Sideloading alone does not verify Play purchase behaviour.

No entitlement is granted from a button click, pending transaction, cancelled payment, or unverified local test flag. RevenueCat's confirmed customer entitlement determines access. Cached verified access can work offline; restoration and new purchases require a connection. Analytics is off by default, has a settings opt-out, and is independent of purchases.

## Structure

| Area | Responsibility |
|---|---|
| `scripts/core` | Rules, seed/date configuration, bounded history, persistence and progression |
| `scripts/ui` | Arena rendering, touch input, styling, cosmetics, score cards |
| `scripts/services` | Audio and the platform boundary; safe behaviour without native services |
| `scripts/app.gd` | Screen flow, lifecycle handling, tutorial and session orchestration |
| `android/plugin` | Native purchases, optional analytics and Android sharing |
| `tests` | Core behaviour and UI integration verification |
| `docs` | Release gates, store copy, privacy policy and playtest instructions |

All gameplay coordinates are logical arena units. Rendering scales the same simulation to the device. The fixed 60 Hz simulation records positions and visual state in a bounded circular buffer. Daily target RNG depends only on the seed and previous target, not on player position, play timing or device frame rate. Rules changes require incrementing `RunConfig.RULES_VERSION`.

Earned progress is local and is not cloud-synchronized. Active runs are not restored after process termination. Android backups are disabled so that this behaviour is explicit. Purchases can be restored from the same store account.

See [release gates](docs/RELEASE.md), [store materials](docs/STORE.md), and [third-party notices](THIRD_PARTY_NOTICES.md). Run `python tools/release_check.py` before preparing a production submission; missing owner configuration intentionally causes it to fail.

After building and capturing, `python tools/package_handoff.py` creates source and store-kit ZIP files plus SHA-256 checksums in `dist/`. The source archive excludes credentials, signing keys, caches and generated application builds; it intentionally includes the small native plugin AAR and Gradle wrapper JAR.
