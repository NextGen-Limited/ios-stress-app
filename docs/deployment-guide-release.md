# Deployment Guide: TestFlight & App Store Release

**Platform:** iOS 17+ / watchOS 10+
**Section:** Distribution, Review, Post-Release Monitoring
**Last Updated:** February 2026

---

## App Store Configuration

### 1. Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Apps → My Apps → + New App
3. Fill in:
   - Platform: iOS, watchOS
   - App Name: "StressMonitor"
   - Bundle ID: `com.stressmonitor.app`
   - SKU: `stressmonitor-001`
   - User Access: Limit Access (your team only for now)

### 2. App Information

#### General Information
- **Category:** Health & Fitness
- **Content Rating:** No explicit content
- **Age Rating:** 4+

#### App Privacy
Complete privacy policy:

```
StressMonitor is privacy-first. We collect ONLY:
- Heart Rate Variability (from HealthKit on your device)
- Heart Rate (from HealthKit on your device)

We DO NOT:
- Share data with third parties
- Collect personal data
- Track user behavior
- Use analytics or advertising

All health data is stored locally on your device.
Optional iCloud sync is end-to-end encrypted.
```

### 3. HealthKit Privacy Questions

In App Store Connect → Health & Fitness:

- [ ] Do you use HealthKit API? **Yes**
- [ ] Health records category (optional)
- [ ] Health data types:
  - Read: HRV (Heart Rate Variability)
  - Read: Heart Rate
  - Do NOT write

**Explanation:**
```
"StressMonitor calculates your stress level based on
Heart Rate Variability from your Apple Watch. We only
read this data and never write to Apple Health."
```

### 4. Screenshots

Prepare screenshots for each device:

**iPhone 15 (6.1-inch)** - At least 2 screenshots
1. Dashboard with stress ring
2. Trends chart
3. Watch app screen (marked as watch screenshot)

**Apple Watch** - At least 1 screenshot
1. Watch app with complications

**iPad (if supporting)** - Screenshots at iPad resolution

### 5. Description

```
StressMonitor - Understand Your Stress

Real-time stress monitoring using Heart Rate Variability
from your Apple Watch. Our science-based algorithm adapts
to your unique physiology over time.

Features:
• Real-time stress measurement (HRV + Heart Rate)
• Personal baseline adaptation (learns over 30 days)
• Historical tracking with filtering
• Trend analysis with charts
• Apple Watch standalone app
• CloudKit sync across devices
• Data export (CSV/JSON)
• Complete data control (export/delete anytime)

Privacy-First:
• All data stored locally on your device
• Optional iCloud sync is end-to-end encrypted
• No third-party services
• No tracking or analytics
• Open data access (export anytime)

Zero External Dependencies
Built entirely with Apple frameworks.
```

### 6. Keywords

```
stress, heart rate, HRV, health, wellness, monitoring,
apple watch, mindfulness, anxiety, relaxation
```

---

## TestFlight Distribution

### 1. Build & Archive

In Xcode:
```
Product → Archive
→ Distribute App
→ TestFlight & App Store
→ Upload
```

Or via command line:
```bash
xcodebuild -scheme StressMonitor \
    -configuration Release \
    -archivePath ./build/StressMonitor.xcarchive \
    archive

# Validate archive
xcodebuild -validateArchive \
    -archivePath ./build/StressMonitor.xcarchive

# Export for upload
xcodebuild -exportArchive \
    -archivePath ./build/StressMonitor.xcarchive \
    -exportPath ./build/Export \
    -exportOptionsPlist ExportOptions.plist
```

### 2. Upload to TestFlight

1. App Store Connect → TestFlight tab
2. Click Build section
3. Select archive to test
4. Add build information
5. Submit for review (Apple's internal review)

**Review Time:** Usually 10-30 minutes

### 3. Add Testers

Internal Testing:
```
TestFlight → Internal Testing
→ Add your team members
→ They receive TestFlight invite
```

External Testing:
```
TestFlight → External Testing
→ Create test group
→ Add up to 10,000 testers
→ Requires Apple review (similar to App Store)
→ Review time: 24-48 hours
```

### 4. Monitor TestFlight Sessions

```
TestFlight → Testers → Session & Feedback
→ View crash logs, performance metrics
→ Review tester feedback
```

---

## App Store Submission

### 1. Prepare Release Version

Update version numbers:
```swift
// In Xcode or Info.plist
Marketing Version: 1.0
Build Version: 1

// Next release
Marketing Version: 1.0.1
Build Version: 2
```

### 2. Create Release Notes

```
StressMonitor 1.0

Initial Release:
• Real-time stress measurement with HRV algorithm
• Personal baseline adaptation
• Apple Watch standalone app with complications
• CloudKit sync across devices
• Historical tracking with trends analysis
• Data export and management
• Comprehensive accessibility features

Thank you for using StressMonitor!
```

### 3. Submit for Review

1. App Store Connect → My Apps → StressMonitor
2. Version → Prepare for Submission
3. Fill all required fields:
   - [ ] Screenshots uploaded
   - [ ] Description complete
   - [ ] Keywords set
   - [ ] Rating provided
   - [ ] HealthKit privacy explained
   - [ ] Contact info provided

4. Click "Save"
5. Review section:
   - [ ] App Version: Select 1.0
   - [ ] Rating: 4+
   - [ ] Alcohol/Tobacco: No
   - [ ] Gambling: No
   - [ ] Unmoderated UGC: No
   - [ ] Medical: No (it's health, not medical)

6. Submit for Review

### 4. Monitor Review Status

```
App Store Connect → Overview
→ Status shows: "Waiting for Review"
→ Review typically takes 24-48 hours
→ Apple may request changes
→ Once approved: "Pending Release"
```

### 5. Release to App Store

Once approved:
```
Pending Release → Automatic Release
→ Choose date/time or release immediately
```

---

## Version Management

### Semantic Versioning

```
1.0.0
├─ Major (1)  : Breaking changes
├─ Minor (0)  : New features
└─ Patch (0)  : Bug fixes
```

### Release Process

1. **Development** → Feature branch
2. **Testing** → Merge to `main`, TestFlight
3. **Review** → App Store review queue
4. **Release** → Public App Store

### Update Cadence

- **Critical Bugs:** Same day
- **Features:** Monthly
- **Polish:** Quarterly

---

## Troubleshooting

### Build Failures

**Error:** "Code signing required"
```
Solution: Check Signing & Capabilities
→ Ensure valid team selected
→ Renew certificates if expired
```

**Error:** "HealthKit entitlements missing"
```
Solution: In Signing & Capabilities
→ Ensure HealthKit capability enabled
→ Entitlements file auto-generated
```

**Error:** "Bundle ID mismatch"
```
Solution: In Xcode
→ Build Settings → Product Bundle Identifier
→ Match configured App ID in Apple Developer
```

### TestFlight Issues

**Issue:** "Build Processing Failed"
```
Solution:
→ Wait 5-10 minutes (processing delay)
→ Check build archive integrity
→ Try uploading again
```

**Issue:** "Tester not receiving invite"
```
Solution:
→ Check email address in TestFlight
→ Resend invite
→ Tester check spam folder
```

### App Store Review Rejection

**Common Reasons:**
1. HealthKit privacy vague → Clarify in app
2. Crash on startup → Fix and retest
3. Missing privacy policy → Add link in Settings
4. Unclear functionality → Improve description

**Response Process:**
1. Read rejection reason carefully
2. Fix issue
3. Create new build
4. Submit "Resolution"
5. Resubmit for review

---

## Performance Optimization

### Code Size

Measure app size:
```bash
# Archived app
ls -lh ./build/StressMonitor.xcarchive

# Estimated App Store size (after thinning)
# Typically: 15-25 MB
```

### App Launch Time

Target: <2 seconds from tap to dashboard visible

Optimize:
- Defer network requests
- Lazy-load heavy views
- Cache baseline data
- Profile with Instruments

### Memory Usage

Target: <100 MB with 100+ measurements

Monitor in Xcode:
```
Debug → Memory Graph
→ Check for retain cycles
→ Verify SwiftData cleanup
```

---

## Monitoring After Release

### Crash Reports

App Store Connect → Crashes & Hangs
```
→ Monitor for exceptions
→ Fix top crashes in next version
→ Target: <0.1% crash rate
```

### Performance Metrics

App Store Connect → Performance
```
→ Hang ratio <0.1%
→ Memory growth acceptable
→ Battery impact minimal
```

### User Ratings

App Store Connect → Ratings & Reviews
```
→ Monitor feedback
→ Respond to key issues
→ Aim for 4.5+ stars
```

---

## Rollback Procedure

If critical issue released:

1. **Remove from Sale** (immediate)
   ```
   App Store Connect → Version Release
   → Remove from Sale
   ```

2. **Create Hotfix**
   ```
   Fix issue → Build → TestFlight
   → Verify on device → TestFlight testers
   ```

3. **Resubmit**
   ```
   New version → App Store review
   → Once approved → Release
   ```

Typical timeline: 4-6 hours

---

**Previous:** See `deployment-guide-environment.md` for setup instructions.
**Managed By:** Phuong Doan
**Last Updated:** February 2026
