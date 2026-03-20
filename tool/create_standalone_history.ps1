param(
  [string]$LegacyTag = "legacy-history-before-standalone",
  [string]$BackupBranch = "legacy/main-before-standalone",
  [string]$StandaloneBranch = "standalone-main",
  [string]$CommitMessage = "chore: initialize GXU standalone maintenance line"
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
  )

  & git @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "git $($Arguments -join ' ') failed."
  }
}

Push-Location (Resolve-Path "$PSScriptRoot\..")
try {
  $status = git status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to read git status."
  }
  if (-not [string]::IsNullOrWhiteSpace($status)) {
    throw "Working tree is not clean. Commit or stash changes before creating standalone history."
  }

  & git show-ref --verify --quiet "refs/tags/$LegacyTag"
  if ($LASTEXITCODE -eq 0) {
    throw "Tag '$LegacyTag' already exists."
  }

  & git show-ref --verify --quiet "refs/heads/$BackupBranch"
  if ($LASTEXITCODE -eq 0) {
    throw "Branch '$BackupBranch' already exists."
  }

  & git show-ref --verify --quiet "refs/heads/$StandaloneBranch"
  if ($LASTEXITCODE -eq 0) {
    throw "Branch '$StandaloneBranch' already exists."
  }

  Invoke-Git @("tag", $LegacyTag)
  Invoke-Git @("branch", $BackupBranch)
  Invoke-Git @("switch", "--orphan", $StandaloneBranch)
  Invoke-Git @("reset")
  Invoke-Git @("add", "-A")
  Invoke-Git @("commit", "-m", $CommitMessage)

  Write-Host "Standalone history branch created: $StandaloneBranch"
  Write-Host "Legacy tag preserved at: $LegacyTag"
  Write-Host "Legacy backup branch preserved at: $BackupBranch"
}
finally {
  Pop-Location
}
