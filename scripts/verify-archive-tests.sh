#!/bin/bash
# Bidirectional tests for verify-archive.sh. Works locally and in CI.
#
# Proves the artifact gate detects what it claims to detect:
#   1. GREEN  — verify-archive.sh exits 0 on the build-13 golden archive
#               (.asc/artifacts/StressMonitor.xcarchive — preserve, never delete).
#   2. RED    — a copy of the golden app binary with a planted JWT-shaped string
#               appended makes the credential scan (scan mode) exit non-zero.
#   3. ENTITLEMENTS — the per-bundle entitlements check reports PASS for all three
#               bundles (app, widget appex, watch app) of the golden archive.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERIFY="$SCRIPT_DIR/verify-archive.sh"
GOLDEN_APP=".asc/artifacts/StressMonitor.xcarchive/Products/Applications/StressMonitor.app"
GOLDEN="$REPO_ROOT/.asc/artifacts/StressMonitor.xcarchive"
PLANTED="eyJhbGciOiJIUzI1NiJ9.PLANTEDSECRETVALUE.forTestingPurposes"

failures=0

expect_pass() { # name, condition already evaluated by caller via $?
    if [ "$1" -eq 0 ]; then
        echo "PASS $2"
    else
        echo "FAIL $2"
        failures=$((failures + 1))
    fi
}

# Test 1 (green direction): the gate passes on the known-good build-13 archive.
bash "$VERIFY" "$GOLDEN" > /tmp/verify-archive-tests-green.$$ 2>&1
rc=$?
[ "$rc" -eq 0 ] && grep -q "PASS ENTITLEMENTS" /tmp/verify-archive-tests-green.$$
expect_pass $? "test_green_on_golden_archive (exit=$rc)"
rm -f /tmp/verify-archive-tests-green.$$

# Test 2 (red direction): planted JWT-shaped string in a binary copy must trip the scan.
TMPD=$(mktemp -d)
cp "$GOLDEN_APP/StressMonitor" "$TMPD/tampered"
printf '%s' "$PLANTED" >> "$TMPD/tampered"
strings -a "$TMPD/tampered" | grep -q "PLANTEDSECRETVALUE"
planted_visible=$?
bash "$VERIFY" --scan-binary "$TMPD/tampered" > /dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && [ "$planted_visible" -eq 0 ]
expect_pass $? "test_red_on_planted_secret (scan exit=$rc, planted string visible=$planted_visible)"
rm -rf "$TMPD"

# Test 3 (entitlements direction): all three bundles report the app group.
bash "$VERIFY" "$GOLDEN" > /tmp/verify-archive-tests-ent.$$ 2>&1
rc=$?
grep -q "PASS ENTITLEMENTS StressMonitor.app:" /tmp/verify-archive-tests-ent.$$
a=$?
grep -q "PASS ENTITLEMENTS PlugIns/StressMonitorWidgetExtension.appex:" /tmp/verify-archive-tests-ent.$$
b=$?
grep -q "PASS ENTITLEMENTS Watch/StressMonitorWatch Watch App.app:" /tmp/verify-archive-tests-ent.$$
c=$?
[ "$rc" -eq 0 ] && [ "$a" -eq 0 ] && [ "$b" -eq 0 ] && [ "$c" -eq 0 ]
expect_pass $? "test_entitlements_all_three_bundles (app=$a widget=$b watch=$c)"
rm -f /tmp/verify-archive-tests-ent.$$

echo "verify-archive tests: $failures failure(s)"
exit "$failures"
