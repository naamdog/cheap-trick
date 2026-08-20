$ErrorActionPreference = 'Stop'

$repo = Split-Path -Parent $PSScriptRoot
$bundledBin = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
$codexExecutable = Get-ChildItem -LiteralPath $bundledBin -Filter 'codex.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $codexExecutable) {
    $codexCommand = Get-Command codex.exe -ErrorAction SilentlyContinue
    if (-not $codexCommand) {
        $codexCommand = Get-Command codex -ErrorAction SilentlyContinue
    }
    if ($codexCommand) {
        $codexExecutable = $codexCommand.Source
    }
}
if (-not $codexExecutable) {
    throw 'Codex CLI is not available on PATH.'
}

$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $codexExecutable
$psi.Arguments = 'app-server --stdio'
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$process = [Diagnostics.Process]::new()
$process.StartInfo = $psi
$started = $false

function Send-Message {
    param([hashtable]$Message)

    $process.StandardInput.WriteLine(($Message | ConvertTo-Json -Compress -Depth 8))
    $process.StandardInput.Flush()
}

function Read-Response {
    param(
        [int]$Id,
        [int]$TimeoutMilliseconds = 15000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $remaining = [Math]::Max(1, [int]($deadline - [DateTime]::UtcNow).TotalMilliseconds)
        $task = $process.StandardOutput.ReadLineAsync()
        if (-not $task.Wait($remaining)) {
            throw "Timed out waiting for app-server response $Id."
        }

        $line = $task.Result
        if ($null -eq $line) {
            throw 'Codex app-server closed before returning the requested response.'
        }

        try {
            $message = $line | ConvertFrom-Json
        } catch {
            continue
        }

        if ($message.id -eq $Id) {
            return $message
        }
    }

    throw "Timed out waiting for app-server response $Id."
}

try {
    if (-not $process.Start()) {
        throw 'Failed to start Codex app-server.'
    }
    $started = $true

    Send-Message @{
        id = 1
        method = 'initialize'
        params = @{
            clientInfo = @{ name = 'cheap-trick-hook-test'; title = 'Cheap Trick Hook Test'; version = '1.0.0' }
            capabilities = @{ experimentalApi = $true }
        }
    }
    $null = Read-Response -Id 1

    Send-Message @{ method = 'initialized' }
    Send-Message @{
        id = 2
        method = 'hooks/list'
        params = @{ cwds = @($repo) }
    }
    $response = Read-Response -Id 2

    $hooks = @(
        $response.result.data |
            ForEach-Object { $_.hooks } |
            Where-Object { $_.pluginId -eq 'cheap-trick@cheap-trick' }
    )

    if ($hooks.Count -ne 1) {
        throw "Expected one installed Cheap Trick hook; found $($hooks.Count)."
    }

    $hook = $hooks[0]
    if ($hook.eventName -ne 'userPromptSubmit') { throw 'Installed hook is not a UserPromptSubmit hook.' }
    if (-not $hook.enabled) { throw 'Installed Cheap Trick hook is disabled.' }
    if ($hook.trustStatus -ne 'trusted') { throw "Installed Cheap Trick hook is $($hook.trustStatus), not trusted." }

    $hooksDir = Split-Path -Parent $hook.sourcePath
    $installedRoot = Split-Path -Parent $hooksDir
    $installedScript = Join-Path $hooksDir 'cheap-trick-reminder.ps1'
    $installedSkill = Join-Path $installedRoot 'skills\cheap-trick\SKILL.md'

    $hookOutput = & $installedScript | ConvertFrom-Json
    $context = $hookOutput.hookSpecificOutput.additionalContext
    if ($hookOutput.hookSpecificOutput.hookEventName -ne 'UserPromptSubmit') { throw 'Installed hook script emits the wrong event.' }
    if ($context -notmatch 'MODEL PLAN') { throw 'Installed hook script omits the model receipt.' }
    if ($context -notmatch 'main-model option is not a spawn option') { throw 'Installed hook script confuses Spark availability.' }
    if ($context -notmatch 'estimated, not actual') { throw 'Installed hook script omits the estimate label.' }

    $sourceSkill = Get-Content -LiteralPath (Join-Path $repo 'plugins\cheap-trick\skills\cheap-trick\SKILL.md') -Raw
    $cachedSkill = Get-Content -LiteralPath $installedSkill -Raw
    if ($sourceSkill -ne $cachedSkill) { throw 'Installed Codex skill does not match the repository source.' }

    Write-Output "PASS: installed hook is enabled, trusted, every-prompt, and matches $installedRoot."
} finally {
    if ($started -and $process.HasExited -eq $false) {
        $process.Kill($true)
        $process.WaitForExit()
    }
}
