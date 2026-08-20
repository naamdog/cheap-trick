<!-- Activation: Always On -->

# Cheap Trick — always on

Cheap Trick is ALWAYS ON for multi-step work. Before the first tool call of any multi-step task, split it: KEEP stages that need judgement, are irreversible, or need this session's context, on the top tier model; DELEGATE bulky, mechanical, self-contained stages to a cheaper subagent (name the tier explicitly on every dispatch — cheapest tier for bulk read-only or mechanical work, mid tier for normal implementation from a clear spec — never let a dispatch silently inherit the top tier); DO INLINE anything too small to justify a cold-start hand-off.

CONTEXT WARNING: for each DELEGATE stage, ask whether a fresh subagent would need context it cannot see. If yes, keep that stage on the top tier instead and tell the user in one plain line why — delegating would redo or miss this session's context. This is a stop, not a silent choice.

Demand tight conclusions back from every dispatch — findings, file paths, numbers — never a pasted transcript. Review delegated output in proportion to stakes; never let unreviewed cheap-tier output settle a send, delete, deploy, publish, merge, payment, or live-data write — those stay on the top tier and are verified before they happen.

Use platform-neutral tier language only: **cheapest tier**, **mid tier**, **top tier**. Do not name a specific Claude, Grok, or other vendor's model — Antigravity's own model lineup is not fixed here, so name tiers, not brands.

If a delegated stage comes back wrong: if it misunderstood the brief, fix the brief once rather than re-briefing the same tier; if it hit the ceiling of its tier, move that stage up a tier rather than retrying the same tier on something it already failed.

SKIP entirely for one-line answers, single lookups, single edits, and conversation — the plan must not cost more than the task.

When it genuinely ran, add a CHEAP TRICK row reporting the split, e.g. "5 stages → 1 delegated (cheapest tier), 3 kept, 1 inline"; or "kept whole — needs this session's context" when the context warning fired and nothing was delegated. Render this as a row in the shared run box at the very end of the response: a fenced code block, one row per skill that genuinely ran, left rail only and no right-hand border, always the last thing in the reply so the reader can see where the answer ends and the instrumentation begins. Omit the row entirely if the skill did not run. State this only when genuinely run, never as decoration.
