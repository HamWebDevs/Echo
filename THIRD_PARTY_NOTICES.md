# Third-party notices

Project-specific source, geometric artwork, icon and synthesized audio were created for this HamWebDev project. No third-party sound recordings or stock artwork are included. The generated audio is reproducible with `tools/generate_audio.py`.

## Godot Engine

Godot Engine is distributed under the MIT licence. Copyright (c) 2014-present Godot Engine contributors; copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur. Full licence and bundled dependency notices are available at [godotengine.org/license](https://godotengine.org/license/) and in the engine's official distribution. Retain the engine and dependency notices when distributing a compiled game. A copy of the Godot licence is included in `docs/GODOT-LICENSE.txt`.

## Fonts

- **Nunito**, Vernon Adams and contributors — SIL Open Font License 1.1. Full licence: `assets/fonts/Nunito-OFL.txt`.
- **Inter**, Rasmus Andersson and contributors — SIL Open Font License 1.1. Full licence: `assets/fonts/Inter-OFL.txt`.
- **Space Grotesk**, Florian Karsten and contributors — SIL Open Font License 1.1. Full licence: `assets/fonts/SpaceGrotesk-OFL.txt`.

Fonts are bundled unmodified. FontVariation resources choose axis values at runtime; the font files have not been renamed or modified.

## Android libraries

The native plugin depends on Godot's Android library, RevenueCat Purchases Android, Firebase Analytics and AndroidX Core. Gradle resolves their transitive dependencies. Retain applicable notices from their distributions. The native bridge itself does not contain vendor private keys or a custom payment processor.

- [RevenueCat Purchases Android](https://github.com/RevenueCat/purchases-android)
- [Firebase Android SDK](https://github.com/firebase/firebase-android-sdk)
- [AndroidX](https://developer.android.com/jetpack/androidx)

Platform SDKs, JDK, Gradle and emulator files are build tools; they are not included in the source handoff archive.
