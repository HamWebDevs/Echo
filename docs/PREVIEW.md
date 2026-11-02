# ECHO 0.4.0 — cartoon preview

Pip has a copycat problem. Collect little stars, dodge the mischievous copies of your earlier route, and see how long you last.

This preview adds a **12-sticker journal**, permanent skill goals, a live next-goal prompt, daily Bronze/Silver/Gold score targets, and a five-run history. Stickers reward completed runs and do not expire. Tutorial practice does not count. Daily and Endless scores remain separate. Existing character progression and the save schema remain compatible.

Daily targets are Bronze at 75 points, Silver at 200, and Gold at 450. New days offer a new shared route; your permanent journal progress stays saved. No daily streak is required.

Verification: **57 core checks and 30 UI checks pass (87 total)**, including save migration, repeat rewards, multiple completed goals, daily thresholds, tutorial exclusion and bounded run history. Human retention has not been measured.

Install `project-echo-preview.apk` on Android 9+. This is a development-signed build, not a Play release. CI builds generate a temporary development key, so installing a CI build over a differently signed local preview requires uninstalling the old preview first; uninstalling removes local progress. A stable preview-signing secret has not been configured, so even successive CI previews may use different keys. Do not uninstall an existing preview without understanding that its local progress will be lost.

The AAB is unsigned. Purchases require owner configuration. Physical-phone testing, native sharing and Play billing tests, support email, privacy hosting, branding and production signing are still launch gates. See RELEASE.md and VALIDATION.md. This preview does not establish player retention.

The public APK link works without GitHub login: https://github.com/HamWebDevs/Echo/releases/download/v0.4.0-preview/project-echo-preview.apk

Source, store-kit and checksum downloads accompany the build. Store clips use scripted steering through the real gameplay rules.
