# Plan: Add GLM Mode to Statusline

## Overview
- **Priority**: Medium
- **Status**: Planning
- Add GLM-specific mode to statusline with 200k context tracking

## Requirements
- Add new 'glm' mode to statusline.cjs
- Display "GLM" as model name instead of Claude model
- Use 200k tokens as context window size
- Calculate percentage based on GLM's 200k limit

## Implementation

### 1. Modify statusline.cjs
- Add GLM_CONTEXT_SIZE = 200000 constant
- Add 'glm' case in switch statement (line 514-528)
- Create renderGLM() function similar to renderCompact() but with GLM branding
- Override contextPercent calculation to use 200k when in glm mode

### 2. Update .ck.json
- Change statusline from "compact" to "glm"

### Files to Modify
- `/Users/ddphuong/.claude/statusline.cjs`
- `/Users/ddphuong/.claude/.ck.json`

## GLM Mode Display
```
GLM  🔋 45%  ⌛ 1h 30m left  📁 ~/Projects/ios-stress-app  🌿 main
```

## Success Criteria
- Statusline shows "GLM" as model
- Context percentage calculated from 200k tokens
- Works with all existing features (git, todos, agents)
