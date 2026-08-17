---
status: testing
phase: 02-credits-system-iap-transition
source: [02-VERIFICATION.md]
started: 2026-08-17T16:20:00+07:00
updated: 2026-08-17T16:20:00+07:00
---

## Progress Log

- 2026-08-17: Deploy complete (session iap-env-config-cleanup, user-approved). Service stressbe-be-isdzmz rebuilt from origin/main a9e9862, rolled zero-downtime; migrations 20260816120000_redeem, 20260816120100_premium_until, 20260817120000_purchased_credits applied on boot. Env: APP_BUNDLE_ID=stress.ai.com, IAP_ENVIRONMENT=Sandbox, APPLE_APPLE_ID unset (valid — appAppleId check skipped per iap.ts:57). Corroborated from ios-stress-app session: GET /health 200, GET /credits 401 unauthenticated (auth wall intact). Env documentation lives in stress-app-be docs/deployment-guide.md. Remaining for Test 1: ASC consumable filing + the 5-step Release-config smoke.

## Current Test

number: 1
name: ASC consumable filing + Release-config 5-step smoke (deploy half complete)
expected: |
  DEPLOYED (done): stress-api.dropitx.site live with all phase-2 migrations and
  Sandbox IAP env — see Progress Log.
  STILL NEEDED: Two ASC consumables filed: com.stressmonitor.app.credits.small
  (10 credits $1.99) and .large (150 credits $19.99). Then on a Release-configuration
  simulator install (DEBUG builds use MockStoreKitService and bypass StoreKit):
  1) balance visible in chat pill / paywall header / Settings row;
  2) sandbox purchase of a pack grants credits server-side exactly once (idempotent re-run safe);
  3) balance increases live; 4) chat consumes credits per message; 5) depletion → 402 → paywall
  leads with subscription. Optional: sandbox refund to observe CR-05 demotion + WR-10 loop-break
  end-to-end.
awaiting: user response

## Tests

### 1. Live money-path smoke (deploy + ASC filing + Release-config 5-step smoke)
expected: deploy stress-app-be (migrations + APPLE_APP_LE_ID), file 2 ASC consumables, run the 5-step Release-config smoke; optionally sandbox refund for CR-05/WR-10
result: [pending]

### 2. Paywall visual / design-system conformance
expected: dual coding for stress levels, Dynamic Type scaling, >=44pt touch targets, haptics via HapticManager on PackCard / paywall / ChatBottomSheetView surfaces (static scan found zero accessibleDynamicType usages — verify visually)
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
