# Cheap Trick

Cheap Trick routes work to the cheapest model that can finish it safely. The repository now ships two independent plugin packages so Codex and Claude Code can evolve without changing each other's instructions.

## Packages

```text
cheap-trick/
├── .agents/plugins/marketplace.json    # Native Codex marketplace
├── .claude-plugin/marketplace.json     # Claude Code marketplace
├── plugins/cheap-trick/                # Codex-only plugin
│   ├── .codex-plugin/plugin.json
│   ├── hooks/
│   └── skills/cheap-trick/SKILL.md
└── claude-code/                        # Claude Code-only plugin
    ├── .claude-plugin/plugin.json
    ├── hooks/
    └── skills/cheap-trick/SKILL.md
```

The Claude Code skill and hook are preserved unchanged inside `claude-code/`. The Codex package has its own manifest, hook, skill, model names, and tests.

## What the Codex package does

The `UserPromptSubmit` hook runs on every prompt. Cheap Trick then:

- keeps judgement, session-dependent decisions, and irreversible actions on the controller;
- delegates only bounded work that a fresh child can understand;
- sets the exact subagent model and reasoning effort on every dispatch;
- prefers GPT-5.6 Luna for mechanical bulk work, Terra for normal implementation, and Sol for hard judgement and final high-stakes checks;
- considers GPT-5.3-Codex-Spark only when it is in the live spawn allowlist and fast, focused coding fits;
- reports a model-by-model token estimate on every turn, clearly labelled as estimated rather than actual usage.

Token estimates are ranges for incremental work created by the turn. They include new prompts, file and tool text, reasoning, retries, and returns. They exclude fixed cached system/tool instructions that the agent cannot measure. Codex collaboration tools do not currently return actual token telemetry, so the plugin never pretends an estimate is a measurement.

Spark is treated as a speed option, not a known cheap tier. OpenAI describes the preview as text-only with a 128k context window and separate limits; its final Codex credit rate is not published. Codex may offer Spark as a main model while the live subagent tool excludes it as a child model. Cheap Trick checks both live lists and keeps them separate. See [Introducing GPT-5.3-Codex-Spark](https://openai.com/index/introducing-gpt-5-3-codex-spark/) and the [Codex rate card](https://help.openai.com/en/articles/20001106-codex-rate-card).

## Install for Codex

```powershell
codex plugin marketplace add https://github.com/naamdog/cheap-trick.git
codex plugin add cheap-trick@cheap-trick
```

For a machine-level fallback that prevents an accidental child from inheriting Sol, add this to `~/.codex/config.toml`:

```toml
[features]
multi_agent = true

[agents]
default_subagent_model = "gpt-5.6-terra"
default_subagent_reasoning_effort = "medium"
```

The skill still sets both values explicitly on every real dispatch. The fallback catches omissions.

Start a new Codex thread after installing or updating so the new skill and hook load. Trust the hook when Codex asks; an untrusted hook cannot run on every prompt.

The checked-in hook configuration targets Windows PowerShell. On macOS or Linux, replace its command with `"${CLAUDE_PLUGIN_ROOT}/hooks/cheap-trick-reminder.sh"`; the matching POSIX script ships in the same folder.

## Install for Claude Code

```text
/plugin marketplace add naamdog/cheap-trick
/plugin install cheap-trick@cheap-trick
```

Restart Claude Code after installing. Its existing behavior is unchanged.

Its checked-in hook also targets Windows PowerShell, exactly as before. The matching POSIX script remains under `claude-code/hooks/` for macOS and Linux users.

## Validate

From the repository root:

```powershell
./tests/validate-platform-layout.ps1
./tests/verify-installed-codex-hook.ps1
claude plugin validate ./claude-code
python "$env:USERPROFILE/.codex/skills/.system/skill-creator/scripts/quick_validate.py" ./plugins/cheap-trick/skills/cheap-trick
python "$env:USERPROFILE/.codex/skills/.system/plugin-creator/scripts/validate_plugin.py" ./plugins/cheap-trick
```

## License

MIT — see [LICENSE](LICENSE).
