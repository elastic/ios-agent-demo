#!/bin/sh
# Resolve Swift packages and fail if Package.resolved changed.
#
# Exit 0 when the committed lockfile matches Xcode's resolution result.
# Exit 1 when resolution would change the lockfile, printing the diff and
# the local remediation commands.
#
# Derives the repository root from the script location so it works from any
# current directory.
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
PACKAGE_RESOLVED="$REPO_ROOT/WeatherDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

echo "Resolving Swift package dependencies"
xcodebuild \
  -quiet \
  -resolvePackageDependencies \
  -project "$REPO_ROOT/WeatherDemo.xcodeproj" \
  -scheme WeatherDemo

if ! git -C "$REPO_ROOT" diff --quiet -- "$PACKAGE_RESOLVED"; then
  echo "Package.resolved changed during dependency resolution." >&2
  echo "Resolve packages locally, stage the updated lockfile, and run checks again:" >&2
  echo "  xcodebuild -resolvePackageDependencies -project WeatherDemo.xcodeproj -scheme WeatherDemo" >&2
  echo "  git add WeatherDemo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" >&2
  git -C "$REPO_ROOT" --no-pager diff -- "$PACKAGE_RESOLVED" >&2
  exit 1
fi

echo "Package.resolved is up to date"
