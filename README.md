# Cheap Trick

A Claude Code plugin that makes the top model supervise multi-step work instead of grinding through it - splitting a task into what it keeps and what it hands to cheaper sub-agents, automatically, without having to ask for it every time.

## What it does

Ships a skill (`cheap-trick`) plus a `UserPromptSubmit` hook that reminds Claude, before the first tool call of any multi-step task, to plan the split:

- KEEP stages that need judgement, are irreversible, or need context only this session has.
- DELEGATE bulky, mechanical stages to a cheaper sub-agent - naming the model tier or the pinned `grind`/`worker` agent explicitly, with effort set explicitly, on every dispatch.
- DO INLINE anything too small to justify a cold-start hand-off.
- Before any DELEGATE step, run the CONTEXT WARNING check: if a fresh agent would need context it cannot see, that step gets kept instead of dispatched, and Claude tells the user in one plain line why.
- Delegated work comes back as tight conclusions, never transcripts, and gets reviewed in proportion to stakes - a cheap agent's first pass never settles a send, delete, deploy, or live-data write on its own.
- It skips itself entirely for one-line answers, single lookups, single edits, and conversation, where planning the split would cost more than just doing the task.
- When it genuinely runs, the response ends with a compact one-line declaration, e.g. `Cheap Trick: 3 stages -> 2 delegated (sonnet x2), 1 kept`, so you can see, turn by turn, how the work was actually split.

## Why it exists

The model you are running on is the most expensive brain in the room. Its job on multi-step work is to supervise, not grind: decide the split, dispatch the mechanical part to a cheaper agent, keep the judgement calls and irreversible steps for itself, and check the result. Every token the top model spends doing something a cheaper model would do equally well is waste - and every token a cheap model spends getting something wrong is a bigger waste, because the top model then has to redo it.

Left to habit, the temptation runs the other way: grinding through file reads and boilerplate directly feels faster than planning a hand-off, right up until it isn't. The hook removes the remembering - it fires on every prompt and puts the split-the-task question in front of Claude before the first tool call, along with the one guardrail that keeps delegation honest: if a fresh sub-agent would be missing context this session already has, that step does not get delegated, full stop.

## Install

In any Claude Code session:

```
/plugin marketplace add naamdog/cheap-trick
/plugin install cheap-trick@cheap-trick
```

Start a new session (or restart Claude Code) so the skill and hook load. Manage it any time with `/plugin list`, `/plugin disable cheap-trick`, or `/plugin uninstall cheap-trick@cheap-trick`.

## macOS / Linux note

The hook ships two versions of the reminder script. Both emit the exact same single-line JSON:

- `hooks/cheap-trick-reminder.ps1` - Windows (PowerShell). This is the one wired up in `hooks/hooks.json` by default.
- `hooks/cheap-trick-reminder.sh` - macOS/Linux (POSIX `sh`).

If you're on macOS or Linux, switch `hooks/hooks.json` over to the `.sh` script:

1. Make it executable once (it's already tracked with the executable bit set, but if that's ever lost): `chmod +x hooks/cheap-trick-reminder.sh`
2. Edit `hooks/hooks.json` and replace the PowerShell `command` value with:
   ```
   "\"${CLAUDE_PLUGIN_ROOT}/hooks/cheap-trick-reminder.sh\""
   ```

`hooks.json` can't hold comments, which is why this note lives here instead.

## Works with Smart Meter

If [`smart-meter`](https://github.com/sjcaffery/smart-meter) (by Scott Caffery) is also installed, Cheap Trick dispatches to its pinned `grind`, `worker`, and `reviewer` agents instead of generic sub-agents. The two plugins compose rather than overlap: Smart Meter meters token spend and recommends when to economize; Cheap Trick plans the split and does the dispatching. One measures, the other decides and acts.

## License

MIT - see [LICENSE](LICENSE).
