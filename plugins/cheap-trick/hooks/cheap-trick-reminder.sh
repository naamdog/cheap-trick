#!/bin/sh

msg='Cheap Trick for Codex runs on every turn. Before the first task tool call, read the cheap-trick skill and make a routing scan. For multi-step work, split KEEP / DELEGATE / INLINE; check whether a fresh child would miss session context; keep judgement and irreversible actions; use the cheapest capable model for bounded work. Every spawn must set an exact model and reasoning_effort from the live spawn allowlist, plus an estimated token range, tight return, and stop condition. Treat gpt-5.3-codex-spark as a fast focused option only where it is actually available: a main-model option is not a spawn option, and Spark is not a proven cost tier. End every turn with a MODEL PLAN row listing each model, effort, token estimate, delegate count, and "estimated, not actual" inside the final fenced run box, never as loose rows. Add a CHEAP TRICK row when a real multi-step split ran. Do not spawn for conversation or tiny work.'

escaped=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$escaped"
