#!/bin/sh
set -eu

BASEDIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
SIMULATOR_ARCH=$(uname -m)
PACKAGE_RESOLVED="$BASEDIR/WeatherDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

echo "Linting Swift sources"
swift format lint --strict --recursive "$BASEDIR/WeatherDemo" "$BASEDIR/WeatherDemoTests"

echo "Selecting an iPhone Simulator"
SIMULATOR_ID=$(
  xcrun simctl list devices available --json |
    jq -r '[.devices[] | .[] | select(.name | startswith("iPhone"))] | first | .udid'
)
if [ -z "$SIMULATOR_ID" ] || [ "$SIMULATOR_ID" = "null" ]; then
  echo "No available iPhone Simulator found" >&2
  exit 1
fi

echo "Running unit tests (Debug)"
xcodebuild \
  -quiet \
  -project "$BASEDIR/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath "$BASEDIR/.derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  test

if ! git -C "$BASEDIR" diff --quiet -- "$PACKAGE_RESOLVED"; then
  echo "Package.resolved changed while resolving dependencies." >&2
  echo "Resolve packages locally, stage the updated lockfile, and run checks again:" >&2
  echo "  xcodebuild -resolvePackageDependencies -project WeatherDemo.xcodeproj -scheme WeatherDemo" >&2
  echo "  git add WeatherDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" >&2
  git -C "$BASEDIR" --no-pager diff -- "$PACKAGE_RESOLVED" >&2
  exit 1
fi

echo "Building the app (Release)"
xcodebuild \
  -quiet \
  -project "$BASEDIR/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo \
  -configuration Release \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath "$BASEDIR/.derived-data" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS="$SIMULATOR_ARCH" \
  build
