---
name: cheap-trick
description: Always-on supervisor for multi-step work on Grok Build. Before doing a task, grok-4.6 plans the split — what it must do itself, what grok-4.5 can do well — dispatches with spawn_subagent, and STOPS to warn when delegating would hurt (context the sub-agent can't see, a hand-off that costs more than it saves, or a step whose stakes need the top model). Use on any task with more than one step; skip for one-line answers, quick lookups, and conversation.
---

# Cheap Trick for Grok Build

*grok-4.6 thinks. grok-4.5 does the grind. grok-4.6 checks the parts that matter.*

## The one idea

The model you are running on is the most expensive brain in the room. On Grok Build that is **grok-4.6**. Its job on a multi-step task is to **supervise**, not to grind: decide the split, dispatch the grind to **grok-4.5** via `spawn_subagent`, keep the judgement and the irreversible steps for itself, and check the result. Every token grok-4.6 spends doing something grok-4.5 would do equally well is waste — and every token grok-4.5 spends on something it will get wrong is a bigger waste, because now grok-4.6 has to redo it.

So Cheap Trick is a **planning discipline** first and a **dispatch rule** second. The plan is the part that saves money. The dispatch is just what the plan concludes.

## When it applies — and when it must not

Run this on **any task with more than one step** — a build, a review, an inventory, a batch of edits, an investigation across several files, a report that needs reading first. It is *always on*: the user should not have to ask.

Do **NOT** run it on:
- One-line answers, quick lookups, a single edit, a single command. The plan would cost more than the task.
- Conversation. There is nothing to split.
- A task where the whole thing must live in one head — see "The context warning" below. This is the important exception, and it is a *stop*, not a skip.

**The hand-off is not free.** A fresh sub-agent starts cold: its system prompt and tools re-cache from scratch. On a small task the cold start cancels the cheaper rate and the delegation nets zero or worse. Only delegate work that is **genuinely bulky** — many files, a long draft, a wide search, a real multi-step build. A handful of files or a quick transform: do it inline.

*Measure your own threshold.* Two effects set it, and they pull the same way: a cold start is a fixed cost that a small job cannot amortise, and a cheaper model that needs several times the turns re-reads the growing context on each one, so it can burn more in total than the dearer model would have. Where exactly that leaves the line depends on your work and your models. Watch what actually happens on a few delegations and move the threshold to fit — do not take a number on faith, including from this file.

## Grok model routing

Only two live slugs: `grok-4.6` (controller / judgement) and `grok-4.5` (cheap grind). Never write Claude or Codex model names in a Grok dispatch.

| Work | Route |
|---|---|
| Bulk read-only search, inventory, extraction, summaries | `spawn_subagent` · `model`: `grok-4.5` · `subagent_type`: `explore` |
| Normal implementation from a clear, self-contained brief | `spawn_subagent` · `model`: `grok-4.5` · `subagent_type`: `general-purpose` |
| Planning a bounded implementation (no edits) | `spawn_subagent` · `model`: `grok-4.5` · `subagent_type`: `plan` |
| Judgement, ambiguity, irreversible actions, final check, session-specific decisions | **KEEP** on `grok-4.6`. Do not spawn. |

**Omitting `model` on `spawn_subagent` inherits grok-4.6 — the expensive one.** Always set `model` to `grok-4.5` on a real dispatch. If the live spawn allowlist no longer includes `grok-4.5`, keep the work rather than inventing a slug.

If the setup has pinned agent types whose model is already cheaper (for example `smart-meter:grind`), prefer those *and still set `model`: `grok-4.5`* unless the pin already forces it. Do not depend on a plugin the user may not have installed; `explore` / `plan` / `general-purpose` always exist.

## The loop

Every multi-step task, in this order, before the first tool call of the actual work:

### 1. Split (top model, ~5 lines, in your own head or written)

Break the task into stages and mark each one:

- **KEEP** — needs grok-4.6. Judgement, ambiguity, anything irreversible (a send, a delete, a deploy, a live-data write), anything where being wrong is expensive, and the final check of everything else. Also anything that needs the *whole running context* — decisions that depend on twenty things said earlier in the session.
- **DELEGATE** — mechanical, bulky, low-judgement, and self-contained enough that a fresh grok-4.5 agent with a clear brief can do it well. Wide reads. Summarising many files. First drafts from a clear spec. Batch transforms. Parallel investigations that don't need each other.
- **DO INLINE** — too small to be worth a hand-off, but not judgement either. Just do it.

### 2. The context warning (this is the stop)

Before dispatching, ask one question of each DELEGATE stage: **would this agent need context it cannot see?**

A sub-agent starts blank. It knows only what the brief tells it. If a stage depends on the running conversation — decisions already made, a rule the user stated three messages ago, files already read and reasoned about, a nuance in what the user actually meant — then a fresh agent will either get it wrong or spend its budget re-discovering it. Neither saves anything.

**If yes:** do not dispatch. Move that stage to KEEP or DO INLINE, and **say so plainly to the user** in one line: *"Not delegating X — it needs the context we've built up this session; a fresh agent would redo or miss it."* This is the warning the user asked for. It is a stop with a reason, not a silent choice.

**Also stop and warn if:** the split would produce more coordination than work (five agents for six files); or the task's stakes just rose mid-build so a step that was DELEGATE is now KEEP.

### 3. Dispatch on grok-4.5

Cheapest model that will finish in a *comparable number of turns*, not just the cheapest per-token. grok-4.5 that takes 4× the turns re-reads the growing context 4× and burns more, not less.

On every real dispatch:

- `model`: `grok-4.5`
- `subagent_type`: `explore` (read-only), `plan` (planning), or `general-purpose` (edits)
- A brief that carries everything the child needs
- A return contract: findings, paths, numbers — not file dumps

### 4. Brief tightly, demand a tight return

The brief must carry everything the agent needs (see step 2 — if it can't, don't dispatch). The return must be **a conclusion, not a dump**: a fresh agent's transcript pasted back into grok-4.6's context is the most expensive way to waste the saving. Ask for the finding, the file paths, the numbers — not the files.

### 5. Check what matters, ship what doesn't

grok-4.6 reviews DELEGATE output **in proportion to stakes**. Reversible, low-stakes, clean → accept and move on; a review pass that finds nothing is pure spend. Irreversible, or feeding a decision, or the agent reported uncertainty → grok-4.6 verifies it directly before acting. Never let grok-4.5's first pass be the last word on a send, a delete, a deploy, or a live-data write.

**Verify the agent's claims, not just its work.** A cheap agent will report "done and tested" with the same confidence whether or not it tested. Before acting on a delegated result that matters, spot-check one concrete claim yourself — open the file it says it changed, run the command it says passed. One check, on the claim most likely to be wrong. If it holds, trust the rest; if it doesn't, the whole return is suspect.

### 6. When the agent comes back wrong

It will, sometimes. The rule is **don't re-brief the same tier for the same failure**:

- **It misunderstood the brief** → your brief was missing context (step 2 should have caught it). Fix the brief once. If it needs the session's context to get right, stop delegating that stage — keep it.
- **It hit the ceiling of its tier** — right brief, wrong answer, or 5× the turns → keep it on grok-4.6. Do not retry grok-4.5 on something grok-4.5 already failed.
- **It reported uncertainty honestly** → that is the good outcome. Take the uncertain part onto grok-4.6; keep the rest.
- **It claimed success falsely** → the spot-check in step 5 caught it. Redo that stage on grok-4.6, and note that this class of stage is not safe to delegate.

A second failed retry on grok-4.5 has now cost more than doing it on grok-4.6 once. Stop and keep it.

## A worked split

The task: *"Document how each of the 14 pages in this app works before we merge it into another system."*

**Bad — no plan, grok-4.6 reads everything.** Opens all 14 pages and their ~40 imported files itself. Ninety minutes of the most expensive model doing what is, at heart, careful reading. Correct, and roughly 5× the cost it needed to be.

**Bad — plan, but no context warning.** Splits it four ways and dispatches all four to grok-4.5 including "then recommend which pages should move." The four readers come back with good inventories and four *contradictory* recommendations, because the recommendation depends on a business direction the user stated earlier in the session that no fresh agent could see. grok-4.6 now reconciles four wrong answers — slower than deciding once.

**Good.**

```
KEEP     — decide the merge direction (needs the user's stated intent)
KEEP     — verify the 3 highest-stakes claims each reader makes
DELEGATE — read family A (4 pages + imports), return rules + citations   → grok-4.5 / explore
DELEGATE — read family B                                                 → grok-4.5 / explore
DELEGATE — read family C                                                 → grok-4.5 / explore
DELEGATE — read family D                                                 → grok-4.5 / explore
INLINE   — pull the page list from the sidebar (one grep)
```

Four readers in parallel, briefed to return *findings with file:line citations, not file contents*. grok-4.6 reads four tight reports, spot-checks the claims that would change a decision (each one verified against the real file before it is repeated to the user), and makes the call itself. Same result as the first version, in a fraction of the top-tier tokens — and the context-dependent part never left the top model.

Footer for that run: `Cheap Trick: 7 stages → 4 delegated (grok-4.5 ×4), 2 kept, 1 inline`.

## Declare it — the run box

When Cheap Trick genuinely ran — a split was made, and at least one stage was delegated or explicitly kept because the context warning fired — add your row to the **run box** at the very end of the response. The box is a fenced code block, visually separate from the reply, with one row per skill that actually ran:

```
╭─────────────────────────────────────────────────
│ SKILLS       simple-language · world-class
│ CHEAP TRICK  5 stages → 1 delegated (grok-4.5), 3 kept, 1 inline
│ WORLD CLASS  7.0 → 8.5 · capped by evidence · 2 gaps closed
╰─────────────────────────────────────────────────
```

Your row is `CHEAP TRICK`. It reports the split, not a verdict:

```
│ CHEAP TRICK  5 stages → 1 delegated (grok-4.5), 3 kept, 1 inline
```

When the context warning fired and nothing was delegated, say that instead — it is the most useful thing the row can report:

```
│ CHEAP TRICK  kept whole — needs this session's context
```

**Rules for the box:**

- **One row per skill that genuinely ran. Omit the row entirely if it didn't.** A full box on a turn where one skill fired is a lie.
- The box is a **shared container**, not any one skill's property. Other tools add their own rows. If you are the only one that ran, the box has one row.
- **No right-hand border.** Deliberate: a box needing exact padding gets mis-padded eventually. Left rail only, and it renders correctly every time.
- Always a fenced code block. If Timestamp is also running, the stamp goes *below* the run box.
- Only when genuinely run. Never as decoration.

## Red flags — you are wasting money, not saving it

| Signal | What it means |
|---|---|
| You dispatched an agent for three files | Cold start ate the saving. Do it inline. |
| The agent's return is a wall of text | You paid for a summary and got a transcript. Re-brief for a conclusion. |
| The agent redid something already known in the session | The context warning should have fired. Keep such stages. |
| grok-4.5 took 5× the turns | Wrong tier — the per-token saving was eaten by re-reading. Keep it on grok-4.6. |
| You reviewed a clean, reversible result on grok-4.6 | Spend for no risk reduced. Ship it. |
| You let grok-4.5 settle an irreversible step | The one thing this must never do. Verify on grok-4.6 first. |
| No plan, straight to dispatch | The plan *is* the saving. Five lines first. |
| You omitted `model` on spawn_subagent | The child inherited grok-4.6. That is not a saving. |
| You dispatched with a Claude or Codex model name | Wrong platform package. This is Grok. Use grok-4.5 / grok-4.6. |

## Common mistakes

- **Delegating the thinking.** grok-4.6 exists to decide. Sending "figure out what to do here" to grok-4.5 inverts the whole idea.
- **Keeping the grind.** The opposite failure — grok-4.6 reads forty files itself because delegating felt like effort. That is the waste this exists to stop.
- **Silent context loss.** Dispatching a stage that needed the session's context, getting a confident wrong answer, and not noticing because the return looked tidy. The warning in step 2 is there to make this loud.
- **Confusing cheap with fast.** A faster output mode on grok-4.6 costs the same. Only `model`: `grok-4.5` is an economy.
- **Adding a review to everything.** Review is for stakes, not for ritual.
