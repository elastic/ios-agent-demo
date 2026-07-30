#!/bin/sh
set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)

"$BASEDIR/gradlew" -p "$BASEDIR" :backend:check :backend:bootJar

xcodebuild \
  -project "$BASEDIR/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$BASEDIR/.derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  build
