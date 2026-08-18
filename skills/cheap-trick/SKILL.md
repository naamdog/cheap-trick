---
name: cheap-trick
description: Always-on supervisor for multi-step work. Before doing a task, the top model plans the split — what it must do itself, what a cheaper sub-agent can do well — dispatches accordingly, and STOPS to warn when delegating would hurt (context the sub-agent can't see, a hand-off that costs more than it saves, or a step whose stakes need the top model). Use on any task with more than one step; skip for one-line answers, quick lookups, and conversation.
---

# Cheap Trick

*The expensive model thinks. The cheap models do. The expensive model checks the parts that matter.*

## The one idea

The model you are running on is the most expensive brain in the room. Its job on a multi-step task is to **supervise**, not to grind: decide the split, dispatch the grind to a cheaper agent, keep the judgement and the irreversible steps for itself, and check the result. Every token the top model spends doing something a cheaper model would do equally well is waste — and every token a cheap model spends on something it will get wrong is a bigger waste, because now the top model has to redo it.

So Cheap Trick is a **planning discipline** first and a **dispatch rule** second. The plan is the part that saves money. The dispatch is just what the plan concludes.

## When it applies — and when it must not

Run this on **any task with more than one step** — a build, a review, an inventory, a batch of edits, an investigation across several files, a report that needs reading first. It is *always on*: the user should not have to ask.

Do **NOT** run it on:
- One-line answers, quick lookups, a single edit, a single command. The plan would cost more than the task.
- Conversation. There is nothing to split.
- A task where the whole thing must live in one head — see "The context warning" below. This is the important exception, and it is a *stop*, not a skip.

**The hand-off is not free.** A fresh sub-agent starts cold: its system prompt and tools re-cache from scratch. On a small task the cold start cancels the cheaper rate and the delegation nets zero or worse. Only delegate work that is **genuinely bulky** — many files, a long draft, a wide search, a real multi-step build. A handful of files or a quick transform: do it inline.

*Where the numbers come from:* the measured findings behind this rule are Smart Meter's, not Cheap Trick's — a 10-file summarise delegated to the cheapest tier came out a dead heat with doing it inline; a from-scratch build pushed down one tier took ~4× the turns and netted only ~20% off. Cheap Trick inherits those measurements and does not claim its own. If you measure something different in your own work, trust your measurement and adjust the threshold.

## The loop

Every multi-step task, in this order, before the first tool call of the actual work:

### 1. Split (top model, ~5 lines, in your own head or written)

Break the task into stages and mark each one:

- **KEEP** — needs the top model. Judgement, ambiguity, anything irreversible (a send, a delete, a deploy, a live-data write), anything where being wrong is expensive, and the final check of everything else. Also anything that needs the *whole running context* — decisions that depend on twenty things said earlier in the session.
- **DELEGATE** — mechanical, bulky, low-judgement, and self-contained enough that a fresh agent with a clear brief can do it well. Wide reads. Summarising many files. First drafts from a clear spec. Batch transforms. Parallel investigations that don't need each other.
- **DO INLINE** — too small to be worth a hand-off, but not judgement either. Just do it.

### 2. The context warning (this is the stop)

Before dispatching, ask one question of each DELEGATE stage: **would this agent need context it cannot see?**

A sub-agent starts blank. It knows only what the brief tells it. If a stage depends on the running conversation — decisions already made, a rule the user stated three messages ago, files already read and reasoned about, a nuance in what the user actually meant — then a fresh agent will either get it wrong or spend its budget re-discovering it. Neither saves anything.

**If yes:** do not dispatch. Move that stage to KEEP or DO INLINE, and **say so plainly to the user** in one line: *"Not delegating X — it needs the context we've built up this session; a fresh agent would redo or miss it."* This is the warning the user asked for. It is a stop with a reason, not a silent choice.

**Also stop and warn if:** the split would produce more coordination than work (five agents for six files); or the task's stakes just rose mid-build so a step that was DELEGATE is now KEEP.

### 3. Pick the tier per DELEGATE stage

Cheapest model that will finish in a *comparable number of turns*, not just the cheapest per-token. A cheap model that takes 4× the turns re-reads the growing context 4× and burns more, not less.

- **Bulk, read-only, mechanical** → the cheapest tier (`haiku`, or the `grind` agent if Smart Meter is installed).
- **Normal implementation from a clear spec, heavier reads, parallel investigation** → mid tier (`sonnet`, or the `worker` agent).
- **Anything that turned out to need judgement** → keep it, or send it up a tier. Never force a too-cheap agent through work it will fail.

Set `effort` explicitly at dispatch: `low` for a deliberately cheap mechanical stage, higher for a hard verify. Omitting `model` on a dispatch silently inherits the top model — the expensive one — so always name the tier.

### 4. Brief tightly, demand a tight return

The brief must carry everything the agent needs (see step 2 — if it can't, don't dispatch). The return must be **a conclusion, not a dump**: a fresh agent's transcript pasted back into the top model's context is the most expensive way to waste the saving. Ask for the finding, the file paths, the numbers — not the files.

### 5. Check what matters, ship what doesn't

The top model reviews DELEGATE output **in proportion to stakes**. Reversible, low-stakes, clean → accept and move on; a review pass that finds nothing is pure spend. Irreversible, or feeding a decision, or the agent reported uncertainty → the top model verifies it directly before acting. Never let a cheap agent's first pass be the last word on a send, a delete, a deploy, or a live-data write.

**Verify the agent's claims, not just its work.** A cheap agent will report "done and tested" with the same confidence whether or not it tested. Before acting on a delegated result that matters, spot-check one concrete claim yourself — open the file it says it changed, run the command it says passed. One check, on the claim most likely to be wrong. If it holds, trust the rest; if it doesn't, the whole return is suspect.

### 6. When the agent comes back wrong

It will, sometimes. The rule is **don't re-brief the same tier for the same failure**:

- **It misunderstood the brief** → your brief was missing context (step 2 should have caught it). Fix the brief once. If it needs the session's context to get right, stop delegating that stage — keep it.
- **It hit the ceiling of its tier** — right brief, wrong answer, or 5× the turns → go up one tier for that stage. Do not retry haiku on something haiku already failed.
- **It reported uncertainty honestly** → that is the good outcome. Take the uncertain part onto the top model; keep the rest.
- **It claimed success falsely** → the spot-check in step 5 caught it. Redo that stage on the top model, and note that this class of stage is not safe to delegate.

A second failed retry on a cheap tier has now cost more than doing it on the top model once. Stop and keep it.

## A worked split

The task: *"Document how each of the 14 pages in this app works before we merge it into another system."*

**Bad — no plan, top model reads everything.** Opens all 14 pages and their ~40 imported files itself. Ninety minutes of the most expensive model doing what is, at heart, careful reading. Correct, and roughly 5× the cost it needed to be.

**Bad — plan, but no context warning.** Splits it four ways and dispatches all four to a cheap tier including "then recommend which pages should move." The four readers come back with good inventories and four *contradictory* recommendations, because the recommendation depends on a business direction the user stated earlier in the session that no fresh agent could see. The top model now reconciles four wrong answers — slower than deciding once.

**Good.**

```
KEEP     — decide the merge direction (needs the user's stated intent)
KEEP     — verify the 3 highest-stakes claims each reader makes
DELEGATE — read family A (4 pages + imports), return rules + citations   → sonnet
DELEGATE — read family B                                                 → sonnet
DELEGATE — read family C                                                 → sonnet
DELEGATE — read family D                                                 → sonnet
INLINE   — pull the page list from the sidebar (one grep)
```

Four readers in parallel, briefed to return *findings with file:line citations, not file contents*. Top model reads four tight reports, spot-checks the claims that would change a decision (each one verified against the real file before it is repeated to the user), and makes the call itself. Same result as the first version, in a fraction of the top-tier tokens — and the context-dependent part never left the top model.

Footer for that run: `Cheap Trick: 7 stages → 4 delegated (sonnet ×4), 2 kept, 1 inline`.

## Declare it

Whenever Cheap Trick genuinely ran — a split was made and at least one stage was delegated or explicitly kept with a warning — end the response with one compact line naming what was delegated and to what:

```
Cheap Trick: 3 stages → 2 delegated (sonnet ×2), 1 kept
```

If nothing was delegated because the context warning fired, say that instead — it is the most useful thing the line can report:

```
Cheap Trick: kept whole — needs this session's context, delegating would redo it
```

Combine with other declaring skills on the shared `Skills used:` line if those fire too. Only when genuinely run. Never as decoration.

## Relationship to Smart Meter

If Scott Caffery's `smart-meter` plugin is installed, **use its pinned agents** (`grind`/haiku, `worker`/sonnet, `reviewer`/opus) rather than naming raw models — the pin guarantees the tier and its routing table is measured, not guessed. Cheap Trick adds the piece Smart Meter deliberately doesn't do: the **plan-first supervision loop and the context-warning stop**, run on every multi-step task by default. Smart Meter meters and recommends; Cheap Trick plans and dispatches. They compose; they don't overlap.

Without Smart Meter, name the model tier directly on each dispatch. Same discipline, one less guarantee.

## Red flags — you are wasting money, not saving it

| Signal | What it means |
|---|---|
| You dispatched an agent for three files | Cold start ate the saving. Do it inline. |
| The agent's return is a wall of text | You paid for a summary and got a transcript. Re-brief for a conclusion. |
| The agent redid something already known in the session | The context warning should have fired. Keep such stages. |
| The cheap agent took 5× the turns | Wrong tier — the per-token saving was eaten by re-reading. Go up a tier. |
| You reviewed a clean, reversible result on the top model | Spend for no risk reduced. Ship it. |
| You let a cheap agent's answer settle an irreversible step | The one thing this must never do. Verify on the top model first. |
| No plan, straight to dispatch | The plan *is* the saving. Five lines first. |
| Every task got the same split | You stopped thinking. The split depends on the task. |

## Common mistakes

- **Delegating the thinking.** The top model exists to decide. Sending "figure out what to do here" to a cheap agent inverts the whole idea.
- **Keeping the grind.** The opposite failure — the top model reads forty files itself because delegating felt like effort. That is the waste this exists to stop.
- **Silent context loss.** Dispatching a stage that needed the session's context, getting a confident wrong answer, and not noticing because the return looked tidy. The warning in step 2 is there to make this loud.
- **Confusing cheap with fast.** A faster output mode on the same model costs the same. Only a lower tier is an economy.
- **Adding a review to everything.** Review is for stakes, not for ritual.
