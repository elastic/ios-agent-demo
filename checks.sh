#!/bin/sh
set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
SIMULATOR_ARCH=$(uname -m)

"$BASEDIR/gradlew" -p "$BASEDIR" :backend:check :backend:bootJar

xcodebuild \
  -quiet \
  -project "$BASEDIR/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$BASEDIR/.derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS="$SIMULATOR_ARCH" \
  build
