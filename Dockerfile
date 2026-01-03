# Multi-architecture Dockerfile for building APK
# This image will be used as a base; builds are run via docker run (not during docker build)
FROM --platform=linux/amd64 cirrusci/flutter:stable

ENV ANDROID_SDK_ROOT=/opt/android-sdk
WORKDIR /app

# Copy project files
COPY . /app

# Pre-pull dependencies (optional; speeds up docker run builds)
# Comment out if you prefer to keep image small
RUN flutter pub get || true

# Note: APK build happens via docker run, not during docker build
# Output will be at build/app/outputs/flutter-apk/app-release.apk
