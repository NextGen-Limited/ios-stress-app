# Deployment Guide: TestFlight & App Store Release

**Platform:** iOS 17+ / watchOS 10+
**Section:** Distribution, Review, Post-Release Monitoring
**Last Updated:** June 7, 2026

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
- Sleep, Activity, and Recovery data (from HealthKit, for multi-factor stress algorithm)

We DO NOT:
- Share health data with third parties
- Collect personal data for advertising
- Track user behavior

AI Chat Feature (Apr 2026):
- Chat messages are processed via streaming AI responses
- Apple Intelligence (iOS 26+) provides on-device processing
- CloudLLMService provides fallback via self-hosted gateway (SSE streaming)
- Only anonymized conversation context is transmitted (no raw health data)
- Health data remains on your device at all times
- No API key or account required for chat
- Hardcoded endpoint configuration ensures privacy

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
2. 3-Tab navigation (Home/Action/Trend)
3. ActionView with breathing exercises
4. AI chat interface
5. Trends charts

**Apple Watch** - At least 1 screenshot
1. Watch app with complications

### 5. Description

```
StressMonitor - Understand Your Stress

Real-time stress monitoring using Heart Rate Variability
from your Apple Watch. Our 5-factor algorithm adapts
to your unique physiology over time.

Features:
• 5-factor stress measurement (HRV, Heart Rate, Sleep, Activity, Recovery)
• AI-powered chat with streaming responses (Apple Intelligence + Cloud LLM)
• Personal baseline adaptation (learns over 30 days)
• 3-tab navigation (Home/Action/Trend) for quick access
• Quick action tools for immediate stress relief
• Historical tracking with filtering and analytics
• Trend analysis with interactive charts
• Box breathing exercises with Figma-aligned animations
• Apple Watch standalone app with complications
• CloudKit sync across devices
• Data export (CSV/JSON)
• Complete data control (export/delete anytime)

Privacy-First:
• All health data stored locally on your device
• Optional iCloud sync is end-to-end encrypted
• No third-party analytics or tracking
• Open data access (export anytime)
• No API keys required for AI features
```

### 6. Keywords

```
stress, heart rate, HRV, health, wellness, monitoring,
apple watch, mindfulness, anxiety, relaxation, breathing,
AI, chat, mindfulness, stress management
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
→ Specifically test streaming chat performance
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
• 5-factor stress algorithm (HRV, Heart Rate, Sleep, Activity, Recovery)
• AI Chat with streaming responses (Apple Intelligence + Cloud LLM with SSE)
• Personal baseline adaptation over 30 days
• 3-tab navigation (Home/Action/Trend) for improved user flow
• ActionView with quick stress relief tools
• Apple Watch standalone app with complications
• CloudKit sync across devices with end-to-end encryption
• Historical tracking with comprehensive trends analysis
• Box breathing exercises with Figma-aligned animations
• Data export and management capabilities
• Comprehensive accessibility features (WCAG AA)

New Features (Apr 2026):
• Real-time streaming AI chat responses
• Simplified 3-tab navigation structure
• Quick access to breathing exercises and AI support
• Enhanced breathing exercise visual design
• Improved streaming chat performance

Thank you for using StressMonitor!
```

### 3. Submit for Review

1. App Store Connect → My Apps → StressMonitor
2. Version → Prepare for Submission
3. Fill all required fields:
   - [ ] Screenshots uploaded (include new ActionView and chat screenshots)
   - [ ] Description complete (highlight new streaming features)
   - [ ] Keywords set (include AI, chat, breathing)
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
- [ ] AI features: Streaming chat with simplified endpoint configuration

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

**Error:** "CloudLLM endpoint connection failed"
```
Solution: Check internet connection
→ Verify ngrok tunnel is active
→ Test endpoint manually in browser
→ Check hardcoded endpoint configuration
```

### TestFlight Issues

**Issue:** "Build Processing Failed"
```
Solution:
→ Wait 5-10 minutes (processing delay)
→ Check build archive integrity
→ Try uploading again
→ Verify all new features (ActionView, streaming chat) work
→ Test SSEParser and LLMAPITarget integration
```

**Issue:** "Streaming chat not working"
```
Solution:
→ Test with CloudLLM hardcoded endpoint
→ Verify SSEParser token processing
→ Check network connectivity
→ Test fallback to Apple Intelligence (iOS 26+)
→ Verify LLMAPITarget configuration
```

### App Store Review Rejection

**Common Reasons:**
1. HealthKit privacy vague → Clarify in app
2. Crash on startup → Fix and retest
3. Missing privacy policy → Add link in Settings
4. Unclear functionality → Improve description
5. AI features not working → Test streaming with SSEParser thoroughly

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
# Typically: 20-35 MB (13 SPM packages)
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
→ Monitor streaming chat memory usage
```

---

## Monitoring After Release

### Crash Reports

App Store Connect → Crashes & Hangs
```
→ Monitor for exceptions
→ Fix top crashes in next version
→ Target: <0.1% crash rate
→ Pay special attention to streaming chat, SSEParser, and ActionView
```

### Performance Metrics

App Store Connect → Performance
```
→ Hang ratio <0.1%
→ Memory growth acceptable
→ Battery impact minimal
→ Monitor CloudLLM streaming performance via SSEParser
```

### User Ratings

App Store Connect → Ratings & Reviews
```
→ Monitor feedback
→ Respond to key issues
→ Aim for 4.5+ stars
→ Track feedback on new streaming AI features and ActionView
```

### Feature Usage Analytics

Monitor usage of new features:
- ActionView engagement
- AI chat frequency with streaming
- Breathing exercise completion
- Streaming response satisfaction via SSEParser

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
   → Specifically test streaming chat, SSEParser, and ActionView
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
**Last Updated:** June 7, 2026