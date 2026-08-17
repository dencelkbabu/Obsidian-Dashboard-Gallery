<#
.SYNOPSIS
    Deploys changes from Git repository -> Obsidian Vault.

.DESCRIPTION
    Copies modified CSS snippets and dashboard markdown notes (Dashboard-*.css / Dashboard-*.md)
    from this repo into your Obsidian Vault (D:\Obsidian Vault).
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
    Get-ChildItem -Path "$RepoDashboards\Dashboard-*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $VaultDashboards -Force
        Write-Host "  ✔ Deployed Dashboard: $($_.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✨ Push to Obsidian Vault complete!`n" -ForegroundColor Green
