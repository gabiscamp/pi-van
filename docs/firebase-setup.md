# Firebase Setup (Flutter)

## 1. Create Firebase project

- Go to https://console.firebase.google.com
- Create a project (PI Van)
- Add Android and iOS apps

## 2. Android setup

- Register the Android app
- Package name: `com.example.pi_van` (or update to your org name)
- Download `google-services.json`
- Place it at:

```
pi_van/android/app/google-services.json
```

## 3. iOS setup

- Register the iOS app
- Bundle ID: `com.example.piVan` (or update to your org name)
- Download `GoogleService-Info.plist`
- Place it at:

```
pi_van/ios/Runner/GoogleService-Info.plist
```

## 4. Install FlutterFire CLI (optional)

```
dart pub global activate flutterfire_cli
```

## 5. Add Firebase packages

Suggested packages:

- firebase_core
- firebase_auth
- cloud_firestore

## 6. Initialize Firebase

In `main.dart`:

```dart
await Firebase.initializeApp();
```

## 7. Firestore rules

- Start with basic rules, then harden based on roles
- See [docs/firestore.md](firestore.md)

## 8. Notes for iOS

- Open `ios/Runner.xcworkspace` in Xcode
- Set signing and capabilities
- Run on a real device for Auth testing
