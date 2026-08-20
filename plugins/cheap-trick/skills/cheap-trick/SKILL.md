---
name: cheap-trick
description: Use on every Codex turn to choose the cheapest safe controller and subagent split, consider Spark for fast focused coding when available, and report a model-by-model token estimate. Skip dispatch for tiny or conversational work, but still emit the routing receipt.
---

# Cheap Trick for Codex

Run a routing scan on every turn. The controller decides; cheaper models do bounded work; the controller verifies anything that changes a decision or cannot be undone.

## Per-turn contract

Before the first task tool call:

1. Identify the controller model and effort from the live session when visible. Never infer a model name from an old skill or config file.
2. Make an **estimate range** for incremental working tokens per model. Count the new brief, file and tool text, reasoning, retries, and return. Exclude fixed cached system and tool instructions that cannot be measured.
3. For multi-step work, mark stages `KEEP`, `DELEGATE`, or `INLINE`. For tiny work, conversation, one lookup, or one edit, do not spawn.
4. Before each delegate, ask whether a fresh agent lacks session context. If yes, keep it and tell the user why. Do not copy a long transcript merely to force delegation.
5. On every dispatch, set an exact model and `reasoning_effort` from the **live spawn allowlist**. Give the child a token range, tight return shape, and stop condition. Never silently inherit the controller model.
6. Verify delegated claims in proportion to stakes. A child cannot settle a send, delete, deploy, publish, merge, payment, or live-data write.

## Codex model routing

| Work | Default route |
|---|---|
| Bulk read-only search, inventory, extraction, formatting | `gpt-5.6-luna`, `low` |
| Normal implementation from a clear, self-contained brief | `gpt-5.6-terra`, `medium` |
| Ambiguous architecture, high-stakes judgement, final irreversible check | keep on `gpt-5.6-sol`; choose effort to match difficulty |
| Fast, focused coding or UI iteration | `gpt-5.3-codex-spark` only if that exact model appears in the live spawn allowlist |

Spark is a speed option, not a proven cost tier. It is text-only, has a smaller context window than GPT-5.6, and does not automatically run tests. Never alias Spark to another model, claim final pricing, or request it when the harness does not allow it. A skill cannot switch the current controller: if Spark appears in the main model catalog but not the spawn allowlist, it is only an option for a future focused turn. Mention that option only when switching would save meaningful time; do not pause the current job. If Spark is the current controller, keep its work focused and explicitly run the checks it may skip by default.

Use the cheapest model likely to finish in a comparable number of turns. If a tier fails once from capability, move up; do not repeat the same cheap failure. Reuse an existing child for corrections when possible.

## Token estimate

Use ranges, not false precision:

- tiny response: `<1k`
- focused lookup or edit: `1–3k`
- normal multi-file stage: `3–8k`
- wide or uncertain stage: `8–20k`

These are planning estimates, not measurements. The collaboration tools do not expose actual usage telemetry. Re-estimate if scope changes materially. Never label an estimate as actual usage.

## Return contract

End every turn with one `MODEL PLAN` row in the shared fenced run box. List every model and effort used, its estimate, delegate count, and `estimated, not actual`. If a real split ran, also add the `CHEAP TRICK` row.

```text
╭─────────────────────────────────────────────────
│ CHEAP TRICK  5 stages → 1 delegated (Luna/low), 3 kept, 1 inline
│ MODEL PLAN   Sol/max est 6–12k · Luna/low est 2–4k ×1 · estimated, not actual
╰─────────────────────────────────────────────────
```

For a tiny turn:

```text
╭─────────────────────────────────────────────────
│ MODEL PLAN   Sol/max est <1k · no subagents · estimated, not actual
╰─────────────────────────────────────────────────
```

The rails and rows must be inside one fenced code block, with a left rail and no right-hand border. Do not print loose receipt rows. If the controller name is unavailable, write `controller unknown`; do not guess. The run box stays the last item unless another always-last skill explicitly defines a later postmark.
