# ECHO 0.5.0 — touch, pop and play

Pip has a copycat problem. Collect stars, dodge copies of your earlier route, and pop your way out of a tight spot.

- **Touch anywhere to steer.** The floating joystick appears under your thumb, across the game screen. The separate control box is gone. Settings offers a large fixed joystick over the arena and a switch to swap control sides.
- **Bigger cartoon characters and a garden arena.** Chunky borders, grass, flowers, score floaters and animated POP clouds give the playfield more life. Reduced motion and high contrast remain available.
- **POP!** Three stars charge one use. Tap POP near copycats to clear every copycat within range for eight seconds. They return with a 0.75-second collision-free warning. An empty shot preserves your charge. Walls and the star timer still matter.
- **Music you can hear.** An original bouncy toy-band loop, a new POP sound, an in-game music toggle and background audio suspension.
- **Invite a friend.** The home screen opens Android sharing with a public download link. Result cards include a download link in the Android share caption.

The 12-sticker journal, earned pals, daily medals and recent-run history remain. Existing progress and settings load; new settings default to floating controls. Gameplay rules are now **v2** because character hitboxes and POP affect difficulty. Daily seeds and records are versioned separately; older saved records are retained.

Verification: **68 core checks and 44 UI checks pass (112 total)**, including real screen-touch dispatch, two fingers, release over a button, fixed controls, music toggles, POP cost/range/respawn, replay boundaries and save migration. Browser screenshots show the actual game. Showcase clips use scripted steering, not human playtests.

Install `project-echo-preview.apk` on Android 9+. Public download, no GitHub login required:
https://github.com/HamWebDevs/Echo/releases/download/v0.5.0-preview/project-echo-preview.apk

This is a development-signed preview. A stable preview-signing secret has not been configured; successive CI previews may have different keys. Android cannot install an update signed with a different key. Uninstalling the old preview erases local progress, so do not uninstall without understanding that loss.

The AAB is unsigned. Physical-phone controls, audio levels, performance, native sharing and Play billing still need device testing. Purchases require owner configuration. Support email, privacy hosting, branding and production signing remain launch gates. Human retention has not been measured. Source, store-kit and checksum downloads accompany the APK.
