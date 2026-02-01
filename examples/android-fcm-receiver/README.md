# Android FCM receive-only sample (Kotlin)

Tiny app that only **requests notification permission, fetches the FCM registration token, and shows incoming pushes** with a foreground service (`FirebaseMessagingService`). No server code required—use Firebase Console "Test message" to try it.

## Project layout
- `app/src/main/java/com/example/fcmreceiver/MainActivity.kt` — UI for permission + token display.
- `app/src/main/java/com/example/fcmreceiver/FcmReceiverService.kt` — handles `onMessageReceived` and posts a notification.
- `app/src/main/res/layout/activity_main.xml` — minimal UI with two buttons and token text.
- `app/src/main/AndroidManifest.xml` — declares permissions + messaging service.

## One-time setup
1) Create a Firebase project, add an Android app with package `com.example.fcmreceiver`.
2) Download `google-services.json` and place it at `app/google-services.json`.
3) (Optional) If you prefer Gradle CLI, install Gradle 8.7+ then run `gradle wrapper` in this directory to generate `./gradlew`. Android Studio can also sync/build without a pre-existing wrapper.

## Run
- Android Studio: Open `examples/android-fcm-receiver`, let it sync, then Run on a device/emulator (API 24+; for permission prompt, use Android 13+).
- CLI (after creating wrapper): `./gradlew assembleDebug` then install the APK from `app/build/outputs/apk/debug/`.

## Test receiving
1) Install the app on a device with Google Play Services.
2) Tap "Request notification permission" on Android 13+.
3) Tap "Fetch FCM token" and copy the token.
4) In Firebase Console → Cloud Messaging → Send message (or "Test"), paste the token and send. The app logs payload and shows a notification via `FcmReceiverService`.

## Notes
- Uses Firebase BoM 34.8.0 and `firebase-messaging` only.
- Notification channel is created lazily; foreground / data-only payloads are also surfaced.
- `POST_NOTIFICATIONS` is requested only on API 33+; on lower versions, the button is disabled.
