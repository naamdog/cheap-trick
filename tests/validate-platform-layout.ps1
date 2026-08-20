$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        $failures.Add($Message)
    }
}

function Assert-NormalizedHash {
    param(
        [string]$RelativePath,
        [string]$ExpectedHash
    )

    $path = Join-Path $repo $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        $failures.Add("Missing preserved Claude file: $RelativePath")
        return
    }

    $normalized = (Get-Content -LiteralPath $path) -join "`n"
    $bytes = [Text.Encoding]::UTF8.GetBytes($normalized)
    $actual = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
    if ($actual -ne $ExpectedHash) {
        $failures.Add("Claude file changed unexpectedly: $RelativePath")
    }
}

$claudeRoot = Join-Path $repo 'claude-code'
$codexRoot = Join-Path $repo 'plugins\cheap-trick'

Assert-True (Test-Path -LiteralPath (Join-Path $claudeRoot '.claude-plugin\plugin.json')) 'Claude plugin manifest is not isolated under claude-code.'
Assert-True (Test-Path -LiteralPath (Join-Path $codexRoot '.codex-plugin\plugin.json')) 'Native Codex plugin manifest is missing.'
Assert-True (-not (Get-ChildItem -LiteralPath (Join-Path $repo 'skills') -Filter 'SKILL.md' -File -Recurse -ErrorAction SilentlyContinue)) 'Root skills contain a duplicate discoverable skill.'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $repo 'hooks\hooks.json'))) 'Root hooks contain a duplicate discoverable hook.'

Assert-NormalizedHash 'claude-code\skills\cheap-trick\SKILL.md' 'dd0fb55c683d5899edabe937f4c042830ee5d154ecc6f3c64eb0a63eea5ebe43'
Assert-NormalizedHash 'claude-code\hooks\hooks.json' 'c8b46e51767707b2f80fbb58fb7996f5d448cb01aee0d2ae6923eecea401095a'
Assert-NormalizedHash 'claude-code\hooks\cheap-trick-reminder.ps1' '0ac40fca96e257f85fa05ca89900fba726741ba563191857e6b2b5c6e4510766'
Assert-NormalizedHash 'claude-code\hooks\cheap-trick-reminder.sh' '8158b9536168d3744e1624c2fed70ac30a5984045feb53795597e800252a3f23'

$codexSkillPath = Join-Path $codexRoot 'skills\cheap-trick\SKILL.md'
if (Test-Path -LiteralPath $codexSkillPath) {
    $codexSkill = Get-Content -LiteralPath $codexSkillPath -Raw
    Assert-True ($codexSkill -match 'live spawn allowlist') 'Codex skill does not require checking the live spawn allowlist.'
    Assert-True ($codexSkill -match 'reasoning_effort') 'Codex skill does not require explicit subagent reasoning effort.'
    Assert-True ($codexSkill -match 'fresh agent lacks session context') 'Codex skill does not enforce the fresh-context gate.'
    Assert-True ($codexSkill -match 'send, delete, deploy, publish, merge, payment, or live-data write') 'Codex skill does not keep irreversible actions on the controller.'
    Assert-True ($codexSkill -match 'gpt-5\.3-codex-spark') 'Codex skill does not include the Spark option.'
    Assert-True ($codexSkill -match 'main model catalog but not the spawn allowlist') 'Codex skill confuses Spark controller and subagent availability.'
    Assert-True ($codexSkill -match 'estimate range') 'Codex skill does not require token estimate ranges.'
    Assert-True ($codexSkill -match 'MODEL PLAN') 'Codex skill does not require the per-turn model and token receipt.'
    Assert-True ($codexSkill -match 'actual usage telemetry') 'Codex skill does not distinguish estimates from actual token telemetry.'
    Assert-True ($codexSkill -match 'estimated, not actual') 'Codex skill does not label the model receipt as an estimate.'
    Assert-True ($codexSkill -match 'For a tiny turn') 'Codex skill does not cover the every-turn tiny-task receipt.'
} else {
    $failures.Add('Codex skill is missing.')
}

$codexHookPath = Join-Path $codexRoot 'hooks\cheap-trick-reminder.ps1'
if (Test-Path -LiteralPath $codexHookPath) {
    $hookJson = & $codexHookPath
    try {
        $hook = $hookJson | ConvertFrom-Json
    } catch {
        $failures.Add('Codex PowerShell hook does not emit valid JSON.')
        $hook = $null
    }

    if ($hook) {
        $context = $hook.hookSpecificOutput.additionalContext
        Assert-True ($hook.hookSpecificOutput.hookEventName -eq 'UserPromptSubmit') 'Codex hook emits the wrong event name.'
        Assert-True ($context -match 'reasoning_effort') 'Codex hook omits explicit effort guidance.'
        Assert-True ($context -match 'main-model option is not a spawn option') 'Codex hook confuses Spark controller and child availability.'
        Assert-True ($context -match 'final fenced run box') 'Codex hook omits the fenced receipt requirement.'
        Assert-True ($context -match 'estimated, not actual') 'Codex hook omits the token-estimate label.'
    }
} else {
    $failures.Add('Codex PowerShell hook is missing.')
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'PASS: Claude and Codex plugin parts are separate and the Codex routing contract is present.'
