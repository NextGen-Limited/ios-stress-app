# Google Fonts Integration

This directory contains Google Fonts used in the StressMonitor app for the wellness-themed typography system.

## Required Fonts

### 1. Lora (Serif - Headings)
- **Use**: Hero numbers, card titles, section headers
- **Style**: Organic curves, wellness vibe
- **Weights needed**: Regular (400), SemiBold (600), Bold (700)
- **Download**: https://fonts.google.com/specimen/Lora
- **Vietnamese support**: ✓ Yes

### 2. Raleway (Sans - Body)
- **Use**: Primary content, captions, labels
- **Style**: Elegant simplicity, accessible
- **Weights needed**: Regular (400), SemiBold (600)
- **Download**: https://fonts.google.com/specimen/Raleway
- **Vietnamese support**: ✓ Yes

## Installation Steps

### Option 1: Manual Installation (Recommended for license tracking)

1. **Download fonts from Google Fonts**:
   - Visit https://fonts.google.com/specimen/Lora
   - Click "Download family"
   - Visit https://fonts.google.com/specimen/Raleway
   - Click "Download family"

2. **Extract TTF files**:
   - Extract downloaded ZIP files
   - Locate `.ttf` files for required weights:
     - `Lora-Regular.ttf`
     - `Lora-SemiBold.ttf`
     - `Lora-Bold.ttf`
     - `Raleway-Regular.ttf`
     - `Raleway-SemiBold.ttf`

3. **Add to Xcode project**:
   - Drag TTF files into this directory (`StressMonitor/Fonts/`)
   - Check "Copy items if needed"
   - Ensure "StressMonitor" target is selected

4. **Update Info.plist**:
   Add the following to `Info.plist`:
   ```xml
   <key>UIAppFonts</key>
   <array>
       <string>Lora-Regular.ttf</string>
       <string>Lora-SemiBold.ttf</string>
       <string>Lora-Bold.ttf</string>
       <string>Raleway-Regular.ttf</string>
       <string>Raleway-SemiBold.ttf</string>
   </array>
   ```

5. **Verify installation**:
   Run the app and check console for font status:
   ```swift
   WellnessFontLoader.printFontStatus()
   ```

### Option 2: Swift Package Manager (Future)

Google Fonts can be integrated via SPM package when available. For now, use manual installation.

## License Information

Both fonts are licensed under the **SIL Open Font License (OFL)**:

### Lora
- **License**: SIL Open Font License 1.1
- **Designer**: Cyreal
- **License URL**: https://scripts.sil.org/OFL
- **Permits**: Commercial use, modification, distribution

### Raleway
- **License**: SIL Open Font License 1.1
- **Designer**: Matt McInerney, Pablo Impallari, Rodrigo Fuenzalida
- **License URL**: https://scripts.sil.org/OFL
- **Permits**: Commercial use, modification, distribution

**License files**: Copy `OFL.txt` from downloaded font packages to this directory.

## Fallback Strategy

If custom fonts fail to load, the app automatically falls back to **SF Pro** system fonts with matching weights and sizes. See `Font+WellnessType.swift` for implementation.

## Vietnamese Language Support

Both fonts include full Vietnamese character set with diacritical marks:
- ă, â, đ, ê, ô, ơ, ư
- All tone marks (acute, grave, hook, tilde, dot below)

## Testing Checklist

- [ ] TTF files added to Xcode project
- [ ] Files appear in "Copy Bundle Resources" build phase
- [ ] Info.plist updated with UIAppFonts array
- [ ] App builds successfully
- [ ] Console shows "All wellness fonts loaded successfully"
- [ ] Text renders with custom fonts (not SF Pro)
- [ ] Vietnamese text displays correctly
- [ ] Dynamic Type scaling works correctly
- [ ] Fonts load in both light and dark mode

## Troubleshooting

**Fonts not loading?**
1. Check Info.plist has correct UIAppFonts entries
2. Verify TTF files are in "Copy Bundle Resources"
3. Check file names match exactly (case-sensitive)
4. Clean build folder (Cmd+Shift+K) and rebuild
5. Run `WellnessFontLoader.printFontStatus()` to debug

**Wrong font appearing?**
- Check UIFont.familyNames in debugger
- Font family name might differ from file name
- Use exact family name in Font.custom()

## File Structure

```
Fonts/
├── README.md (this file)
├── OFL-Lora.txt (SIL license for Lora)
├── OFL-Raleway.txt (SIL license for Raleway)
├── Lora-Regular.ttf
├── Lora-SemiBold.ttf
├── Lora-Bold.ttf
├── Raleway-Regular.ttf
└── Raleway-SemiBold.ttf
```

## References

- Apple HIG Typography: https://developer.apple.com/design/human-interface-guidelines/typography
- Custom Fonts in iOS: https://developer.apple.com/documentation/uikit/text_display_and_fonts/adding_a_custom_font_to_your_app
- Google Fonts: https://fonts.google.com/
- SIL Open Font License: https://scripts.sil.org/OFL
