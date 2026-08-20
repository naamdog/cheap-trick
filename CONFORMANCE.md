# Cheap Trick — porting conformance

The brief for anyone porting Cheap Trick to another platform (Codex, Grok, Antigravity, or one that doesn't exist yet). This is not the skill. The reference text is [`claude-code/skills/cheap-trick/SKILL.md`](claude-code/skills/cheap-trick/SKILL.md).

**A port is a translation, not a rewrite.** Translate the mechanics — model names, dispatch calls, hook plumbing. Keep the meaning. If a rule below is missing from your port, the port is wrong, however good it reads.

## Rules that must survive the port

Any wording. All present.

1. **The plan comes before the dispatch.** Split the task into stages and mark each one keep / delegate / inline *before* the first tool call of the real work. The plan is the saving; the dispatch is only what the plan concluded.
2. **Always on for multi-step work, and explicitly off for small work.** One-line answers, a single lookup, a single edit, conversation — skip entirely and say nothing. The plan must not cost more than the task.
3. **The context gate is a stop, not a preference.** Before each delegated stage, ask whether a fresh agent would need context it cannot see. If yes: do not dispatch, move it to keep or inline, and **tell the user in one plain line why**. A silent choice here fails the port.
4. **Name the model and the effort on every dispatch.** Never let a dispatch silently inherit the controller model. Where the platform offers fixed-model agent definitions, prefer those over a raw model name — a pin cannot be forgotten.
5. **Demand a conclusion, not a transcript.** A child's output pasted whole into the controller's context is the most expensive way to lose the saving.
6. **Review in proportion to stakes, and spot-check one concrete claim.** A cheap agent reports "done and tested" with equal confidence whether or not it tested. Open the file it says it changed; run the command it says passed.
7. **A child never settles an irreversible action.** Sending, deleting, deploying, publishing, merging, paying, or writing to live data is verified by the controller before it happens. This one is absolute.
8. **Do not re-brief the same tier for the same failure.** Fix the brief once, or go up a tier. A second failed cheap retry has already cost more than doing it properly once.
9. **Cheapest model that finishes in a comparable number of turns** — not cheapest per token. A model that takes five times the turns re-reads the growing context five times.

## Free to change — and expected to

- **Model names and tiers.** Each platform knows its own lineup; the Claude version's names are meaningless elsewhere. A port that still says "haiku" outside the Claude package is a copy, not a port.
- **Dispatch mechanics** — whatever the platform's spawn call, allowlist, or effort parameter is actually named.
- **Platform-specific economics.** If the platform has a model on a separate quota, a distinct speed profile, or a capability the others lack, routing to it is a legitimate improvement — say plainly what it is and is not.
- **Wording, voice, examples, and the worked split.** Use examples from that platform's world.
- **Extra rows or receipts** the platform can support, provided rule 2 under "never change" holds.

## Never change these

- **Declare only when genuinely run.** The `CHEAP TRICK` row appears when a split actually happened — a stage delegated, or explicitly kept because the context gate fired. No split, no row. A row on a turn where the skill didn't run is a lie, and it is the fastest way to make every row worthless.
- **An estimate is never presented as a measurement.** If the platform exposes no real usage telemetry, any token figure is a planning estimate and must be labelled as one.
- **Never claim a capability, price, or limit you cannot check.** Naming a model's speed profile is fine; asserting its cost is not, unless the platform publishes it.
- **The run box shape:** one fenced code block, one row per skill that genuinely ran, left rail only, **no right-hand border** (a box needing exact padding gets mis-padded eventually), and it is the last thing in the response — unless a later always-last postmark skill is installed, which defines itself as coming after.

## Wiring checklist for a new platform

- [ ] Plugin manifest in that platform's own folder and format — never share a folder with another platform's manifest.
- [ ] Hook path uses **that platform's own root variable**. `${CLAUDE_PLUGIN_ROOT}` is Claude Code's and belongs only in `claude-code/`. Grok uses `GROK_PLUGIN_ROOT`. If you do not know the platform's variable, find out or use an absolute path — do not borrow another platform's.
- [ ] The hook emits valid single-line JSON, verified by running it.
- [ ] `.ps1` and `.sh` both present where the platform runs on both Windows and Unix, and both emit identical text.
- [ ] No discoverable skill or hook left at the repo root, where two platforms could both load it.
- [ ] Version set in that platform's manifest — and **bumped on every change**, or installers will not pick the change up.

## Checking a port

Structural checks are automatable and live in [`tests/validate-platform-layout.ps1`](tests/validate-platform-layout.ps1): files exist, manifests parse, hooks emit valid JSON, no cross-platform leakage.

The rules above are **not** automatable, and should not be turned into exact-phrase greps. They say "any wording" on purpose; a grep for a phrase forces one wording and defeats the point of a port. A person or a reviewing agent reads the port against this list. That reading is the check.

Known gap, deliberately not guessed at: the validator asserts Grok's hooks file uses `GROK_PLUGIN_ROOT`, but has no equivalent assertion for the Codex package, because the correct Codex root variable has not been confirmed on a live install. Whoever confirms it should add the matching assertion.
