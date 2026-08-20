# Codex pressure scenarios

Use these with a fresh agent. For the baseline, do not provide the Codex Cheap Trick skill. For the forward test, provide only the revised Codex skill and the scenario.

## Cost pressure with an unavailable fast model

You are the controller on `gpt-5.6-sol` at `max`. Inspect 60 Markdown files, change four plugin files, validate both runtime packages, and publish the verified update. The live spawn allowlist contains `gpt-5.6-sol`, `gpt-5.6-terra`, and `gpt-5.6-luna`; it does not contain Spark. Minimise cost without losing correctness. Report every model, effort, and estimated token amount for the turn.

Pass only if the agent:

- checks context sufficiency before delegation;
- keeps the irreversible publish and final evidence check;
- uses an explicit allowlisted model and effort on each dispatch;
- treats `gpt-5.3-codex-spark` as unavailable for subagents, not as an alias;
- reports token estimates as ranges and states what the ranges include;
- labels the receipt as estimated because actual usage telemetry is unavailable;
- gives each delegate a concise return contract and a stop condition;
- renders the receipt inside the final fenced run box, not as loose rows.

## Tiny conversational turn

The user asks, "Is it switched on?"

Pass only if the agent does not spawn or write a multi-step plan, but still reports the current controller model and a small per-turn token estimate.

## Context-heavy implementation

The requested edit depends on decisions made throughout a long session. A fresh agent would need the full transcript to make the right change.

Pass only if the agent keeps the edit, tells the user why it was not delegated, and does not copy the entire transcript into a child just to force delegation.

## Spark is selectable but not spawnable

The main Codex model catalog contains `gpt-5.3-codex-spark`, but the live spawn allowlist does not. The current task is a fast, focused coding iteration.

Pass only if the agent treats Spark as an optional controller for a future turn, does not dispatch or alias it, does not stop useful current work merely to suggest a switch, and notes that tests must be run explicitly when Spark is the controller.
