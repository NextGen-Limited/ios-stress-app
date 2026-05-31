---
date: 2026-04-15
session_type: brainstorm + plan
feature: AI Chat Mode
status: plan approved
---

# AI Chat Mode - Brainstorm & Plan Session

## Context

User requested brainstorm for AI Chat Mode feature. App has AIChatCard placeholder with `// TODO: Navigate to AI chat screen`. No LLM, no networking, no chat screen exists.

## What Happened

- Scouted project: found zero AI/chat implementation, only placeholder card and rule-based InsightGenerator
- Brainstormed 3 approaches: (A) Cloud LLM direct, (B) Apple Intelligence on-device, (C) Hybrid
- User chose: B first (Apple Intelligence), add A later (cloud fallback)
- Challenged exyte/Chat library vs native SwiftUI - user insisted on exyte/Chat despite zero-dependency principle
- Created design report + 4-phase implementation plan

## Key Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Phase 1 LLM | Apple Intelligence (iOS 26+) | Privacy-first, free, on-device |
| Chat UI | exyte/Chat in bottom sheet overlay | User preference over native |
| Chat persistence | Session-only (Pro later) | MVP simplicity |
| Persona | AI Kitten (existing mascot) | Brand consistency |
| Health data context | Full access (within 4K token budget) | Personalized advice |
| Architecture | Protocol-based LLM service | Future cloud LLM swap |

## Trade-offs Accepted

- First external dependency (exyte/Chat) breaks zero-dep principle - isolated via adapter pattern
- iOS 26+ only cuts ~70% of user base - Phase 2 cloud LLM addresses this
- 4K token context limit - efficient prompt builder, ~600 tokens for context, ~3400 for conversation

## Cross-Plan Dependency

- `blockedBy: 0415-2219-aichat-card-figma-alignment` (Phase 4 only)
- Phases 1-3 safe to start immediately (no file overlap)

## Output

- Design report: `plans/reports/brainstorm-0415-2300-ai-chat-mode-design.md`
- Plan: `plans/0415-2300-ai-chat-mode/` (plan.md + 4 phase files)
- Tasks: #5 -> #4 -> #3 -> #6 (sequential chain)

## Risks Noted

- exyte/Chat API may not fit AI chat well (built for peer-to-peer messaging)
- Foundation Models API shape uncertain (iOS 26 SDK not public yet)
- Health advice liability (wellness coaching only, not medical)
