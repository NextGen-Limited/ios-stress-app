#!/bin/bash
# ci_post_xcodebuild.sh — Runs after Xcode Cloud completes an archive
# Executes the appropriate Fastlane lane based on the workflow name

set -euo pipefail

echo "=== ci_post_xcodebuild.sh ==="

# Determine which lane to run based on Xcode Cloud workflow name
WORKFLOW_NAME="${CI_WORKFLOW:-}"

case "$WORKFLOW_NAME" in
  "Beta"|"beta")
    echo "Running Fastlane upload_beta..."
    fastlane upload_beta
    ;;
  "Release"|"release")
    echo "Running Fastlane release..."
    fastlane release
    ;;
  *)
    echo "No matching workflow for '$WORKFLOW_NAME' — skipping post-build Fastlane lane"
    echo "Expected workflow names: Beta, Release"
    ;;
esac

echo "=== ci_post_xcodebuild.sh complete ==="
