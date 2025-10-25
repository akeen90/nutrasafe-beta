#!/usr/bin/env bash
set -euo pipefail

# NutraSafe build helper – standardizes xcodebuild invocation
# Usage: ./scripts/build_nutrasafe.sh [Debug|Release]

CONFIGURATION=${1:-Debug}
SCHEME="NutraSafe Beta"
PROJECT_PATH="NutraSafeBeta.xcodeproj"
WORKSPACE_PATH="NutraSafeBeta.xcodeproj/project.xcworkspace"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
LOG_FILE="build/new_cli_build_17pro.log"

mkdir -p build

# Prefer project; fall back to workspace if needed
if [[ -d "$PROJECT_PATH" ]]; then
  # Resolve Swift Package dependencies first to ensure XCFramework artifacts exist
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "$DESTINATION" \
    -resolvePackageDependencies | tee "$LOG_FILE"

  # Build
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphonesimulator \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
    build | tee -a "$LOG_FILE"
elif [[ -d "$WORKSPACE_PATH" ]]; then
  # Resolve Swift Package dependencies first
  xcodebuild \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "$DESTINATION" \
    -resolvePackageDependencies | tee "$LOG_FILE"

  # Build
  xcodebuild \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk iphonesimulator \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
    build | tee -a "$LOG_FILE"
else
  echo "Could not locate project or workspace. Checked: $PROJECT_PATH and $WORKSPACE_PATH" >&2
  exit 1
fi