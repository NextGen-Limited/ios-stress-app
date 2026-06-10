#!/bin/bash
# ci_post_clone.sh — Runs after Xcode Cloud clones the repo
# Installs Fastlane and syncs code signing certificates via Match

set -euo pipefail

echo "=== ci_post_clone.sh ==="

# Install Fastlane via Homebrew (avoids Ruby version conflicts)
if ! command -v fastlane &>/dev/null; then
  echo "Installing Fastlane..."
  brew install fastlane
fi

echo "Fastlane version: $(fastlane --version | grep 'fastlane ' | head -1)"

# Sync code signing certificates via Match (readonly — CI should never regenerate certs)
if [ -n "${MATCH_PASSWORD:-}" ] && [ -n "${MATCH_GIT_URL:-}" ]; then
  echo "Syncing code signing via Match..."
  fastlane match appstore --readonly
else
  echo "⚠️  MATCH_PASSWORD or MATCH_GIT_URL not set — skipping Match sync"
  echo "    Set these in Xcode Cloud → Settings → Environment Variables"
fi

echo "=== ci_post_clone.sh complete ==="
