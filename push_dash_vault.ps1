<#
.SYNOPSIS
    Deploys changes from Git repository -> Obsidian Vault.

.DESCRIPTION
    Copies modified CSS snippets and dashboard markdown notes from this repo
    into your Obsidian Vault (D:\Obsidian Vault).
    Maps dashboards\Dashboard-Komorebi.md -> dashboards\Dashboard.md.
#>

param (
    [string]$VaultPath = "D:\Obsidian Vault",
    [string]$RepoPath = "$PSScriptRoot"
)

$RepoSnippets    = Join-Path $RepoPath ".obsidian\snippets"
$RepoDashboards   = Join-Path $RepoPath "dashboards"

$VaultSnippets   = Join-Path $VaultPath ".obsidian\snippets"
$VaultDashboards = Join-Path $VaultPath "dashboards"

Write-Host "`n🚀 Pushing Git Repo -> Obsidian Vault ($VaultPath)..." -ForegroundColor Cyan

if (!(Test-Path $VaultSnippets)) { New-Item -ItemType Directory -Path $VaultSnippets -Force | Out-Null }
if (!(Test-Path $VaultDashboards)) { New-Item -ItemType Directory -Path $VaultDashboards -Force | Out-Null }

# 1. Sync CSS Snippets (Repo -> Vault)
if (Test-Path $RepoSnippets) {
    Get-ChildItem -Path "$RepoSnippets\Dashboard-*.css" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $VaultSnippets -Force
        Write-Host "  ✔ Deployed Snippet: $($_.Name)" -ForegroundColor Green
    }
}

# 2. Sync Dashboard Markdown Notes (Repo -> Vault)
if (Test-Path $RepoDashboards) {
    # Mapped: Dashboard-Komorebi.md -> Dashboard.md
    $komoRepo = Join-Path $RepoDashboards "Dashboard-Komorebi.md"
    if (Test-Path $komoRepo) {
        Copy-Item -Path $komoRepo -Destination (Join-Path $VaultDashboards "Dashboard.md") -Force
        Write-Host "  ✔ Mapped: dashboards\Dashboard-Komorebi.md -> dashboards\Dashboard.md" -ForegroundColor Green
    }

    # Other dashboards
    Get-ChildItem -Path "$RepoDashboards\Dashboard-*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $VaultDashboards -Force
        Write-Host "  ✔ Deployed Dashboard: $($_.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✨ Push to Obsidian Vault complete!`n" -ForegroundColor Green
