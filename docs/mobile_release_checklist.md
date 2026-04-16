# Mobile-Release-Checkliste (Android & iOS)

Stand: automatischer Check auf dem Entwicklungsrechner (Windows).

## Flutter-Umgebung (`flutter doctor -v`)

| Bereich | Status |
|--------|--------|
| Flutter (stable 3.41.6) | OK |
| Android SDK / Lizenzen | OK |
| Chrome / Web | OK |
| Windows-Desktop | OK |
| **Xcode / iOS** | **Nicht auf Windows verfügbar** — iOS-Builds und App Store nur auf **macOS** mit installiertem **Xcode** |

## Android — Projektzustand

- **Package / Application ID:** `com.metisia.doordesk` (`android/app/build.gradle.kts`).
- **Release-APK:** Smoke-Test erfolgreich: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.
- **App-Label:** `doordesk` (Manifest); Anzeigename für Store ggf. anpassen.
- **Berechtigung:** `INTERNET` gesetzt (für Supabase/API nötig).

### Vor Play-Store / produktivem Release

1. **Signing:** In `android/app/build.gradle.kts` ist für `release` aktuell **`signingConfig = debug`** hinterlegt — für den Play Store eine **eigene Upload-Key / Keystore**-Konfiguration einrichten (nicht mit Debug-Keys veröffentlichen).
2. **App Bundle:** Für Google Play üblich: `flutter build appbundle --release` (`.aab`).
3. **Version:** In `pubspec.yaml` Zeile `version: 1.0.0+1` bei jedem Store-Upload erhöhen (`Name+Buildnummer`).
4. **Play Console:** Developer-Konto, Datenschutzerklärung, ggf. Altersfreigabe, Screenshots.
5. **Tests:** Auf echtem Gerät / Emulator (verschiedene Bildschirmgrößen), Login, Offline-Verhalten, Deep Links falls genutzt.

## iOS — Projektzustand (nur einsehbar, Build auf Mac)

- **Bundle ID:** `com.metisia.doordesk` (`ios/Runner.xcodeproj/project.pbxproj`).
- **Minimum iOS:** 13.0 (`IPHONEOS_DEPLOYMENT_TARGET`).
- **Anzeigename:** `Doordesk` / `doordesk` (`Info.plist`).

### Vor TestFlight / App Store (auf Mac)

1. **Apple Developer Program** (kostenpflichtig) und App in **App Store Connect** anlegen.
2. Im Projekt: **Signing & Capabilities** in Xcode (Team, Provisioning).
3. `cd ios && pod install` falls CocoaPods-Plugins — bei eurem Tree ggf. erst nach `flutter pub get` / erstem iOS-Build auf dem Mac erzeugt.
4. Build: `flutter build ipa` oder Archiv in Xcode.
5. **Datenschutz / App-Privacy-Fragebogen** in App Store Connect (Supabase, Analytics, etc. korrekt angeben).

## Abhängigkeiten & Plattformen

- **`webview_windows`:** nur Desktop Windows — blockiert Android/iOS **nicht**.
- **Supabase / `url_launcher` / `shared_preferences`:** für Mobile üblich; Verhalten auf Gerät testen (Auth, Rückkehr aus Browser).

## Nächste sinnvolle Schritte (ohne Feature-Drift)

1. Android: Release-Keystore einrichten, einmal `appbundle` bauen, interne Verteilung (Internal testing).
2. iOS: Auf einem **Mac** Projekt öffnen, `flutter build ios` / Xcode-Archiv, TestFlight mit wenigen Testern.
3. Parallel: 2–3 **Testfälle** festhalten (Login → Kernscreen → Logout), damit Releases wiederholbar bleiben.
