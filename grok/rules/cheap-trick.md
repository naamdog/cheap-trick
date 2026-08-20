# Cheap Trick — always on

Cheap Trick is ALWAYS ON for multi-step work on Grok Build. Before the first tool call of any multi-step task, split it: KEEP stages that need judgement, are irreversible, or need this session's context, on grok-4.6; DELEGATE bulky, mechanical, self-contained stages to grok-4.5 via `spawn_subagent` (always set `model: grok-4.5` explicitly on the dispatch — omitting `model` inherits grok-4.6, the expensive one); DO INLINE anything too small to justify a cold-start hand-off.

CONTEXT WARNING: for each DELEGATE stage, ask whether a fresh grok-4.5 agent would need context it cannot see. If yes, keep that stage on grok-4.6 instead and tell the user in one plain line why — delegating would redo or miss this session's context. This is a stop, not a silent choice.

Demand tight conclusions back from every `spawn_subagent` dispatch — findings, file paths, numbers — never a pasted transcript. Review delegated output in proportion to stakes; never let unreviewed grok-4.5 output settle a send, delete, deploy, publish, merge, payment, or live-data write — those stay on grok-4.6 and are verified before they happen.

Only two live slugs exist here: `grok-4.6` (controller / judgement) and `grok-4.5` (cheap grind). Never write Claude or Codex model names (haiku, sonnet, opus, gpt-5.x) in a Grok dispatch.

If a delegated stage comes back wrong: if it misunderstood the brief, fix the brief once rather than re-briefing the same tier; if it hit the ceiling of its tier, keep the work on grok-4.6 rather than retrying grok-4.5 on something grok-4.5 already failed.

SKIP entirely for one-line answers, single lookups, single edits, and conversation — the plan must not cost more than the task.

When it genuinely ran, add a CHEAP TRICK row reporting the split, e.g. "5 stages → 1 delegated (grok-4.5), 3 kept, 1 inline"; or "kept whole — needs this session's context" when the context warning fired and nothing was delegated. Render this as a row in the shared run box at the very end of the response: a fenced code block, one row per skill that genuinely ran, left rail only and no right-hand border, always the last thing in the reply so the reader can see where the answer ends and the instrumentation begins. Omit the row entirely if the skill did not run. State this only when genuinely run, never as decoration.
