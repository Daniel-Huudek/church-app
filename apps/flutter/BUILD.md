# IPI Avaré — Build do APK

```bash
cd apps/mobile2
```

---

## Build Release

```bash
flutter build apk --release ^
  --dart-define=API_URL=https://api.ipiavare.com.br ^
  --dart-define=GOOGLE_WEB_CLIENT_ID=520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## Build Debug

```bash
flutter build apk --debug ^
  --dart-define=API_URL=http://192.168.2.110:3030 ^
  --dart-define=GOOGLE_WEB_CLIENT_ID=520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`

---

## Google Sign-In

**SHA-1 Debug:**
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore ^
  -alias androiddebugkey -storepass android -keypass android
```

**SHA-1 Release:**
```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

Adicionar no Google Cloud Console → APIs & Services → Credentials → OAuth 2.0 Client IDs → Android

- **Package name:** `com.igreja.church_app_mobile`
- **SHA-1:** colar o fingerprint acima

---

## Pré-requisitos

- Flutter SDK >= 3.22.0
- `flutter pub get`
