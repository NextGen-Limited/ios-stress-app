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
#   4. RED    — a planted app Info.plist with an empty CFBundleURLSchemes array
#               makes the merged-plists URL-schemes check report FAIL, and the
#               PASS line must NOT appear (guards against the check passing on
#               the key line's own quotes).
#   5. GREEN  — the same planted plist with one scheme entry reports PASS.
#               Tests 4-5 run on a planted temp archive and need no golden.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERIFY="$SCRIPT_DIR/verify-archive.sh"
GOLDEN_APP="$REPO_ROOT/.asc/artifacts/StressMonitor.xcarchive/Products/Applications/StressMonitor.app"
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
# NOTE: macOS strings parses Mach-O and stops at the object's last section, so bytes appended
# past EOF are invisible to it. The secret is planted by overwriting bytes at the file
# midpoint: the copy remains a Mach-O and the unmodified `strings -a` pipeline detects it —
# the same visibility a credential embedded in a shipped binary would have.
TMPD=$(mktemp -d)
cp "$GOLDEN_APP/StressMonitor" "$TMPD/tampered"
TSIZE=$(stat -f%z "$TMPD/tampered")
printf '%s' "$PLANTED" | dd of="$TMPD/tampered" bs=1 seek=$((TSIZE / 2)) conv=notrunc status=none
planted_count=$(strings -a "$TMPD/tampered" | grep -c "PLANTEDSECRETVALUE" || true)
bash "$VERIFY" --scan-binary "$TMPD/tampered" > /dev/null 2>&1
rc=$?
[ "$rc" -ne 0 ] && [ "$planted_count" -ge 1 ]
expect_pass $? "test_red_on_planted_secret (scan exit=$rc, planted string visible via strings: $planted_count hit(s))"
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

# Tests 4 & 5 (URL-schemes direction): the CFBundleURLSchemes check must FAIL on
# an empty array and PASS on a populated one. These run against a planted minimal
# archive, so they exercise the check without needing the golden.
TMPD2=$(mktemp -d)
PLANTED_APP="$TMPD2/planted/Products/Applications/StressMonitor.app"
mkdir -p "$PLANTED_APP"
PPLIST="$PLANTED_APP/Info.plist"
plutil -create xml1 "$PPLIST" >/dev/null
/usr/libexec/PlistBuddy \
    -c 'Add :STOREKIT_CREDITS_LARGE_PRODUCT_ID string credits.large' \
    -c 'Add :STOREKIT_CREDITS_SMALL_PRODUCT_ID string credits.small' \
    -c 'Add :STOREKIT_PREMIUM_ANNUAL_PRODUCT_ID string premium.annual' \
    -c 'Add :STOREKIT_PREMIUM_MONTHLY_PRODUCT_ID string premium.monthly' \
    -c 'Add :STOREKIT_PREMIUM_WEEKLY_PRODUCT_ID string premium.weekly' \
    -c 'Add :STOREKIT_PREMIUM_SUBSCRIPTION_GROUP_ID string group.premium' \
    -c 'Add :CFBundleURLTypes array' \
    -c 'Add :CFBundleURLTypes:0 dict' \
    -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes array' \
    "$PPLIST" >/dev/null 2>&1

# Test 4 (red direction): empty CFBundleURLSchemes must FAIL — and must not emit
# the PASS line (the vacuous form that matched the key line's own quotes).
bash "$VERIFY" --skip-entitlements "$TMPD2/planted" > "$TMPD2/red-urlschemes.log" 2>&1
grep -q "CFBundleURLSchemes missing or empty" "$TMPD2/red-urlschemes.log"
a=$?
grep -q "CFBundleURLSchemes has at least one entry" "$TMPD2/red-urlschemes.log"
b=$?
[ "$a" -eq 0 ] && [ "$b" -ne 0 ]
expect_pass $? "test_red_on_empty_cfbundleurlschemes (fail line present=$a, vacuous pass absent=$b)"

# Test 5 (green direction): one scheme entry must PASS — and must not emit the
# FAIL line.
/usr/libexec/PlistBuddy \
    -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string com.googleusercontent.apps.planted' \
    "$PPLIST" >/dev/null 2>&1
bash "$VERIFY" --skip-entitlements "$TMPD2/planted" > "$TMPD2/green-urlschemes.log" 2>&1
grep -q "CFBundleURLSchemes has at least one entry" "$TMPD2/green-urlschemes.log"
a=$?
grep -q "CFBundleURLSchemes missing or empty" "$TMPD2/green-urlschemes.log"
b=$?
[ "$a" -eq 0 ] && [ "$b" -ne 0 ]
expect_pass $? "test_green_on_populated_cfbundleurlschemes (pass line present=$a, fail line absent=$b)"
rm -rf "$TMPD2"

echo "verify-archive tests: $failures failure(s)"
exit "$failures"
