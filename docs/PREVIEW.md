# ECHO 0.3.0 — cartoon preview

Pip has a copycat problem. Collect little stars, dodge the mischievous copies of your earlier route, and see how long you last.

This preview adds animated pal portraits, individual character stories, distinctive hats and accessories, named unlock progress, and an equip-and-play reward when a new pal arrives. Results react to your run, and replay and share cards now use your selected character. High-contrast mode strengthens character outlines and separates player/copycat colours. Reduced motion keeps the new portraits still. Core rules and existing progress remain compatible.

Verification: 44 core checks and 28 UI checks pass, including multiple unlocks in one run, no repeated unlock announcements, persistent equipment choices, and ownership changing while a preview is open.

Install `project-echo-preview.apk` on Android 9+. This is a development-signed build, not a Play release. CI builds generate a temporary development key, so installing a CI build over a differently signed local preview requires uninstalling the old preview first; uninstalling removes local progress. Keep using the same build source for testing.

The AAB is unsigned. Purchases require owner configuration. Physical-phone testing, native sharing and Play billing tests, support email, privacy hosting, branding and production signing are still launch gates. See RELEASE.md and VALIDATION.md. This preview does not establish player retention.

Source, store-kit and checksum downloads accompany the build. Store clips use scripted steering through the real gameplay rules.
