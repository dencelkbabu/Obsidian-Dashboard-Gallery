<#
.SYNOPSIS
    Pulls edits from Obsidian Vault -> Git Dev Repo.

.DESCRIPTION
    Copies modified CSS snippets and dashboards (Dashboard-*.css / Dashboard-*.md) from D:\Obsidian Vault
    into this git repository for review, staging, and git commit.
#>

param (
    [string]$VaultPath = "D:\Obsidian Vault",
    [string]$RepoPath = "$PSScriptRoot"
)

$RepoSnippets    = Join-Path $RepoPath ".obsidian\snippets"
$RepoDashboards   = Join-Path $RepoPath "dashboards"

$VaultSnippets   = Join-Path $VaultPath ".obsidian\snippets"
$VaultDashboards = Join-Path $VaultPath "dashboards"

Write-Host "`n📥 Pulling Obsidian Vault -> Git Repo ($RepoPath)..." -ForegroundColor Cyan

# 1. Pull CSS Snippets (Vault -> Repo)
if (Test-Path $VaultSnippets) {
    Get-ChildItem -Path "$VaultSnippets\Dashboard-*.css" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $RepoSnippets -Force
        Write-Host "  ✔ Pulled Snippet: $($_.Name)" -ForegroundColor Green
    }
}

# 2. Pull Dashboard Notes (Vault -> Repo)
if (Test-Path $VaultDashboards) {
    Get-ChildItem -Path "$VaultDashboards\Dashboard-*.md" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $RepoDashboards -Force
        Write-Host "  ✔ Pulled Dashboard: $($_.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✨ Vault changes pulled! Run 'git status' to review and commit changes.`n" -ForegroundColor Yellow
