# Scale Buddy

Scale Buddy is a Flutter app for practicing musical scales on Android.

## MVP

- Choose a root key.
- Choose Major, Minor, or Pentatonic scale.
- Adjust BPM from 40 to 220.
- Play the selected scale with native generated tones.

## Development

Flutter SDK is installed separately at `C:\flutter`; this repository can stay on `D:\Project\ScaleBuddy`.

Useful commands:

```powershell
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat test
C:\flutter\bin\flutter.bat run
```

## Android Release

Google Play requires new apps to be uploaded as an Android App Bundle (`.aab`). Release builds must be signed with an upload key.

Create an upload keystore locally:

```powershell
keytool -genkey -v -keystore android\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy the example signing config:

```powershell
Copy-Item android\key.properties.example android\key.properties
```

Then edit `android\key.properties` with the keystore passwords. Do not commit `android\key.properties` or `android\upload-keystore.jks`; both are ignored by Git.

Build the Play Store bundle:

```powershell
C:\flutter\bin\flutter.bat build appbundle --release
```

Upload this file in Play Console:

```text
build\app\outputs\bundle\release\app-release.aab
```
