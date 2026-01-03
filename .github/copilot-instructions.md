# Money Tracer - AI Coding Agent Instructions

## Purpose (Singkat)
Panduan ini menjelaskan aturan operasional dan workflow yang wajib dipatuhi oleh agen AI dan kontributor:
- Aplikasi hanya untuk Android.
- Pengembangan lokal TIDAK BOLEH dijalankan langsung di host; gunakan Docker untuk semua eksekusi lokal.
- Jika tidak menjalankan app, cukup hasilkan file APK untuk distribusi/testing.
- Pemasangan atau penggunaan Android Studio dilarang keras.

## Allowed Tech
- **UI / App**: Flutter (Dart) — gunakan Flutter untuk implementasi Android.

## Hard Constraints (Wajib)
- **No host runs**: Jangan menjalankan Gradle, Flutter toolchain, emulator, atau Android tooling secara langsung pada host OS.
- **Local runs → Docker only**: Semua perintah `flutter`, `gradle`, dan SDK Android yang diperlukan harus dijalankan di dalam container Docker yang terisolasi.
- **APK output**: Jika developer tidak ingin menjalankan container, agen harus menyediakan reproducible Docker build that outputs an APK artifact (`app-release.apk`).
- **No Android Studio**: Do not install, recommend, or script the installation of Android Studio in CI, Dockerfiles, or docs. Mentioning Android Studio as a required dependency is forbidden.

## Local Developer Workflow (Docker)
Use Docker to run builds and any local tasks. Example minimal Docker workflow (example only — adapt SDK versions as needed):

Dockerfile (example):
```dockerfile
FROM cirrusci/flutter:stable
ENV ANDROID_SDK_ROOT=/opt/android-sdk
WORKDIR /app
COPY . /app
RUN flutter pub get
# Build release APK
RUN flutter build apk --release -v
```

Build and run (example):
```bash
docker build -t money-tracer-android:local .
docker run --rm -v "$PWD":/app -w /app money-tracer-android:local flutter build apk --release
```

Notes:
- Ensure the Docker image includes required Android SDK components (`platform-tools`, relevant `platforms;android-<API>`, and `build-tools`).
- Accepting Android SDK licenses must be part of the image build (non-interactive).
- Keep the container unprivileged; do not require `--privileged` or host-level modifications.

## Producing APKs for testing/distribution
- Preferred: Build APK inside Docker and export `build/app/outputs/flutter-apk/app-release.apk` from the container to host CI artifacts.
- For device testing, produce the APK and use host `adb` (if present) to install; the agent must not recommend installing Android Studio to get `adb` — use platform SDK tools or CI runners that already provide `adb`.

## CI Recommendations
- CI jobs should use Docker images that reproduce local build environment and produce APK artifacts.
- Example CI steps:
	- Checkout repo
	- Build Docker image (as above)
	- Run `flutter pub get` and `flutter build apk --release` inside container
	- Upload the produced APK as a job artifact

## Security & Environment
- Do not store or print Android keystore passwords in plaintext in logs. Use CI secret storage to pass signing keys/credentials.
- Do not run SDK/Gradle daemons on the host. Keep everything isolated in ephemeral containers.

## What Not To Do (explicit)
- Do not install Android Studio or instruct contributors to install it.
- Do not instruct running emulators or Android tooling directly on host OS.
- Do not create scripts that assume host has Android SDK/Gradle preinstalled.

## Where to update this file
- When new automation or images are added, update this file and include example Dockerfile and `docker run` commands.

---
*Last updated: January 3, 2026*
*If anything above is unclear or you want extra examples (CI YAML, signing with keystore, or USB device passthrough patterns), tell me and I will add them.*
