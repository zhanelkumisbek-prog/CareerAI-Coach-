# CareerAI Coach

CareerAI Coach is a real Flutter MVP for Android that runs fully offline with local storage only. It helps students, job seekers, HR teams, and university career centers assess skills, upload resumes, generate roadmaps, track weekly progress, and save feedback without Firebase.

## Stack

- Flutter + Dart
- Riverpod for state management
- SQLite (`sqflite`) for persistent local data
- `file_picker` + local file copy for resume uploads
- `flutter_local_notifications` for reminders
- Material 3 UI

## Main user flow

1. Splash screen checks session
2. Role selection
3. Sign up / login / forgot password
4. Profile setup
5. Resume upload
6. Career analysis
7. Skill gap result
8. Roadmap generation
9. Weekly task tracking
10. Local reminders
11. Feedback submission

## Run locally

```bash
flutter pub get
flutter run
```

## Build APK

```bash
flutter build apk
```

## Project structure

- `lib/main.dart` app bootstrap
- `lib/app/app.dart` app shell, theme, routing
- `lib/core/` database, services, analysis engine
- `lib/data/` models, repositories, providers
- `lib/features/` feature screens

## Notes

- No Firebase is used anywhere in this project.
- All data is stored locally in SQLite on the device.
- Resume files are copied into the app documents directory and linked by metadata in SQLite.
- Notifications are local-only reminders.
