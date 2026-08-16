<#
.SYNOPSIS
    Syncs dashboard templates & snippets between Git dev repo and Obsidian Vault.

.DESCRIPTION
    Maps vault files (including dashboards\Dashboard.md <-> dashboards\Dashboard-Komorebi.md)
    directly between this git repository and your Obsidian Vault.

.PARAMETER Direction
    'FromVault' (default): Pulls edits from Obsidian Vault -> Repo for git commit.
    'ToVault'            : Deploys repo changes -> Obsidian Vault.
    'Watch'              : Continuously watches for changes and syncs in real time.
#>

param (
    [ValidateSet('FromVault', 'ToVault', 'Watch')]
    [string]$Direction = 'FromVault',
    
    [string]$VaultPath = "D:\Obsidian Vault",
    [string]$RepoPath = "$PSScriptRoot"
)

$RepoSnippets    = Join-Path $RepoPath ".obsidian\snippets"
$RepoDashboards   = Join-Path $RepoPath "dashboards"

$VaultSnippets   = Join-Path $VaultPath ".obsidian\snippets"
$VaultDashboards = Join-Path $VaultPath "dashboards"

function Sync-FromVault {
    Write-Host "`n📥 Pulling Vault Edits -> Git Repo..." -ForegroundColor Cyan

    # Pull CSS Snippets from Vault
    if (Test-Path $VaultSnippets) {
        Get-ChildItem -Path "$VaultSnippets\Dashboard-*.css" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $RepoSnippets -Force
            Write-Host "  ✔ Snippet: $($_.Name)" -ForegroundColor Green
        }
    }

    # Pull Dashboard Notes with Komorebi mapping (Dashboard.md -> Dashboard-Komorebi.md)
    if (Test-Path $VaultDashboards) {
        $mainDashboard = Join-Path $VaultDashboards "Dashboard.md"
        if (Test-Path $mainDashboard) {
            Copy-Item -Path $mainDashboard -Destination (Join-Path $RepoDashboards "Dashboard-Komorebi.md") -Force
            Write-Host "  ✔ Mapped: dashboards\Dashboard.md -> dashboards\Dashboard-Komorebi.md" -ForegroundColor Green
        }

        Get-ChildItem -Path "$VaultDashboards\Dashboard-*.md" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $RepoDashboards -Force
            Write-Host "  ✔ Dashboard: $($_.Name)" -ForegroundColor Green
        }
    }

    Write-Host "`n✨ Vault changes pulled into Git repo! Review with 'git status' and commit." -ForegroundColor Yellow
}

function Sync-ToVault {
    Write-Host "`n🚀 Deploying Git Repo -> Obsidian Vault..." -ForegroundColor Cyan
    
    if (!(Test-Path $VaultSnippets)) { New-Item -ItemType Directory -Path $VaultSnippets -Force | Out-Null }
    if (!(Test-Path $VaultDashboards)) { New-Item -ItemType Directory -Path $VaultDashboards -Force | Out-Null }

    # Sync CSS Snippets
    if (Test-Path $RepoSnippets) {
        Copy-Item -Path "$RepoSnippets\Dashboard-*.css" -Destination $VaultSnippets -Force
        Write-Host "  ✔ CSS Snippets synced -> $VaultSnippets" -ForegroundColor Green
    }

    # Sync Dashboard Markdown Notes (Dashboard-Komorebi.md -> Dashboard.md)
    if (Test-Path $RepoDashboards) {
        $komoRepo = Join-Path $RepoDashboards "Dashboard-Komorebi.md"
        if (Test-Path $komoRepo) {
            Copy-Item -Path $komoRepo -Destination (Join-Path $VaultDashboards "Dashboard.md") -Force
            Write-Host "  ✔ Mapped: dashboards\Dashboard-Komorebi.md -> dashboards\Dashboard.md" -ForegroundColor Green
        }

        Get-ChildItem -Path "$RepoDashboards\Dashboard-*.md" | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $VaultDashboards -Force
            Write-Host "  ✔ Dashboard: $($_.Name)" -ForegroundColor Green
        }
    }
    
    Write-Host "✨ Deploy complete!`n" -ForegroundColor Green
}

function Start-Watch {
    Write-Host "`n👀 Watching for changes in Vault ($VaultPath)..." -ForegroundColor Magenta
    Write-Host "Press Ctrl+C to stop watching.`n" -ForegroundColor DarkGray
    
    Sync-FromVault

    $watcherSnippets = New-Object System.IO.FileSystemWatcher
    $watcherSnippets.Path = $VaultSnippets
    $watcherSnippets.Filter = "Dashboard-*.css"
    $watcherSnippets.IncludeSubdirectories = $false
    $watcherSnippets.EnableRaisingEvents = $true

    $watcherDashboards = New-Object System.IO.FileSystemWatcher
    $watcherDashboards.Path = $VaultDashboards
    $watcherDashboards.Filter = "*.md"
    $watcherDashboards.IncludeSubdirectories = $false
    $watcherDashboards.EnableRaisingEvents = $true

    $action = {
        $name = $Event.SourceEventArgs.Name
        Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] Vault file changed: $name -> Syncing to Git Repo..." -ForegroundColor Cyan
        Sync-FromVault
    }

    Register-ObjectEvent $watcherSnippets 'Changed' -Action $action | Out-Null
    Register-ObjectEvent $watcherDashboards 'Changed' -Action $action | Out-Null

    while ($true) { Start-Sleep -Seconds 1 }
}

switch ($Direction) {
    'FromVault' { Sync-FromVault }
    'ToVault'   { Sync-ToVault }
    'Watch'     { Start-Watch }
}
