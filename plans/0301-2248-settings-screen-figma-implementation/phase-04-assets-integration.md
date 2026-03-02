# Phase 4: Assets Integration

<!-- Updated: Validation Session 1 - SVG assets mandatory, SF Symbols alternative removed -->

## Overview
Download and integrate SVG assets from Figma MCP server. **Figma SVG assets are mandatory** for exact design match.

## Required Assets

| Asset | Figma Source | Target Size | Usage |
|-------|--------------|-------------|-------|
| `premium-star` | imgGroup | 48×48pt | Premium card icon |
| `watch-icon` | imgLayer23 | 24×24pt | Section header |
| `menu-icon` | imgMenu1 | 24×24pt | Section header |
| `share-icon` | imgIconParkOutlineShare | 16×16pt | Share button |
| `plus-icon` | imgVectorStroke | 18×18pt | Add button |

## Asset URLs (localhost:3845)

```
http://localhost:3845/assets/63b2df454825b17b1f8c016403d3c3404640622a.svg  (premium-star)
http://localhost:3845/assets/c27d2de7002488126b9be3efe6c9db1a98ebfb28.svg  (watch-icon)
http://localhost:3845/assets/d41e4f4a8e695e70c17e403cc45885952eb4318e.svg  (menu-icon)
http://localhost:3845/assets/e82c01f7f9b61dd2cfbaecfe9a70e10d93ab0e7d.svg  (share-icon)
http://localhost:3845/assets/18668c415f5b52d722c826fa7416d6fbb783daf2.svg  (plus-icon)
```

## Asset Catalog Structure

```
Assets.xcassets/
└── Settings/
    ├── premium-star.imageset/
    │   ├── premium-star.svg
    │   └── Contents.json
    ├── watch-icon.imageset/
    │   ├── watch-icon.svg
    │   └── Contents.json
    ├── menu-icon.imageset/
    │   ├── menu-icon.svg
    │   └── Contents.json
    ├── share-icon.imageset/
    │   ├── share-icon.svg
    │   └── Contents.json
    └── plus-icon.imageset/
        ├── plus-icon.svg
        └── Contents.json
```

## Contents.json Template

```json
{
  "images" : [
    {
      "filename" : "icon-name.svg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true,
    "template-rendering-intent" : "template"
  }
}
```

## Implementation Steps

- [x] 1. Create `Assets.xcassets/Settings/` folder
- [x] 2. Download each SVG from localhost:3845
- [x] 3. Create .imageset directories
- [x] 4. Add SVG files
- [x] 5. Create Contents.json for each
- [x] 6. Enable "template" rendering for tintable icons
- [x] 7. Verify in Xcode asset catalog

## Status: ✅ Complete

## Validation
- [x] All assets appear in Xcode
- [x] Assets render in Preview
- [x] Template icons accept `.foregroundColor()`
- [x] No missing image warnings
