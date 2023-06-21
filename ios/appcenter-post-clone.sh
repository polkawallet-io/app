#!/usr/bin/env bash
#Place this script in project/ios/

# fail if any command fails
set -e
# debug log
set -x

cd ..
git clone -b 3.7.7 --depth 1 https://github.com/flutter/flutter.git
export PATH=$(pwd)/flutter/bin:$PATH

flutter doctor

echo "Installed flutter to $(pwd)/flutter"

flutter build ios --release --no-codesign