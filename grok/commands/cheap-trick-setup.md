---
name: cheap-trick-setup
description: Install the Cheap Trick always-on rules file into ~/.grok/rules/ so it loads on every future Grok Build session.
---

# Cheap Trick setup

Run these steps now, in order:

1. Create the directory `~/.grok/rules/` if it does not already exist.
2. Copy this plugin's `rules/cheap-trick.md` file into `~/.grok/rules/cheap-trick.md`. If a file already exists at that destination, **overwrite it** — do not create a duplicate or a renamed copy alongside it.
3. Confirm success to the user in a single line, stating plainly that Cheap Trick is installed and will take effect starting next session (rules files are loaded at session start, not mid-session).

Do not summarize the rules file's contents back to the user. Do not skip step 2's overwrite behavior even if the destination file looks identical — always replace it with the current plugin copy so the installed rules stay in sync with the plugin version.
