# AutoFwd

Personal Android app for forwarding incoming SMS messages when both the sender
and message body match saved regex patterns. Matching messages are forwarded as
the original message body only.

## Development

This project uses Flutter through FVM:

```sh
fvm flutter analyze
fvm flutter test
cd android && ./gradlew :app:testDebugUnitTest
```

## Manual Device Verification

1. Install the debug APK on an Android device.
2. Open the app and grant both SMS permissions.
3. Enable forwarding and save a sender regex, body regex, and destination phone
   number.
4. Send a matching SMS to the device and confirm the destination receives the
   original SMS body only.
5. Send SMS messages with a non-matching sender and a non-matching body and
   confirm they are not forwarded.

Android does not deliver SMS broadcasts to apps that the user has force-stopped.
