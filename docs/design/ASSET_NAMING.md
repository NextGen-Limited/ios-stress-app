# Character Asset Naming Convention

## Pattern
`{characterId}_{evolution}_{mood}`

## Examples
- `ripple_droplet_sleeping` — Baby Ripple sleeping
- `ripple_ripple_calm` — Teen Ripple calm
- `ripple_tidal_overwhelmed` — Adult Ripple overwhelmed

## Total Assets
75 production assets minimum: 5 characters × 3 evolutions × 5 moods.

## Asset Catalog Groups
- `Characters/Ripple/` — 15 images
- `Characters/Blossom/` — 15 images
- `Characters/Ember/` — 15 images
- `Characters/Zephyr/` — 15 images
- `Characters/Lumi/` — 15 images

## Current Placeholder Contract
Until the full 75-asset set exists, each character ships one placeholder:
- `ripple_droplet_calm`
- `blossom_droplet_calm`
- `ember_droplet_calm`
- `zephyr_droplet_calm`
- `lumi_droplet_calm`

## Fallback Chain
1. Exact asset: `{characterId}_{evolution}_{mood}`
2. Character calm starter: `{characterId}_droplet_calm`
3. Legacy generic mood asset: `Character{Mood}`
4. Legacy generic calm asset: `CharacterCalm`
