#!/usr/bin/env bash
#Place this script in project/android/app/
cd ..
# fail if any command fails
set -e
# debug log
set -x

cd ..
git clone -b 3.7.7 --depth 1 https://github.com/flutter/flutter.git
export PATH=$(pwd)/flutter/bin:$PATH

flutter doctor

echo "Installed flutter to $(pwd)/flutter"

# build APK
# if you get "Execution failed for task ':app:lintVitalRelease'." error, uncomment next two lines
# flutter build apk --debug
# flutter build apk --profile
flutter build apk --release

# if you need build bundle (AAB) in addition to your APK, uncomment line below and last line of this script.
flutter build appbundle --release -t lib/main-google.dart

# copy the APK where AppCenter will find it
mkdir -p android/app/build/outputs/apk/; mv build/app/outputs/apk/release/app-release.apk $_

# copy the AAB where AppCenter will find it
mkdir -p android/app/build/outputs/bundle/; mv build/app/outputs/bundle/release/app-release.aab $_