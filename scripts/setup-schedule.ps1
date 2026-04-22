# Sets up daily + weekly usage-reporter via Windows Task Scheduler
# Run in PowerShell as Administrator
# For Windows users WITHOUT WSL

param(
  [string]$ClaudePath = "",
  [switch]$Remove
)

$TaskNameDaily  = "ClaudeAgentPipeline-DailyReport"
$TaskNameWeekly = "ClaudeAgentPipeline-WeeklyReport"
$LogFile        = "$env:USERPROFILE\.claude\usage-reports.log"

# Find claude CLI
if (-not $ClaudePath) {
  $ClaudePath = (Get-Command claude -ErrorAction SilentlyContinue)?.Source
  if (-not $ClaudePath) {
    Write-Error "claude CLI not found. Install it from https://claude.ai/code and ensure it is in PATH."
    exit 1
  }
}

Write-Host "Claude CLI: $ClaudePath"

if ($Remove) {
  Unregister-ScheduledTask -TaskName $TaskNameDaily  -Confirm:$false -ErrorAction SilentlyContinue
  Unregister-ScheduledTask -TaskName $TaskNameWeekly -Confirm:$false -ErrorAction SilentlyContinue
  Write-Host "Removed scheduled tasks."
  exit 0
}

# Ensure log directory exists
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null

# Daily at 9am
$actionDaily  = New-ScheduledTaskAction -Execute $ClaudePath -Argument "-p `"@\`"usage-reporter\`" daily`" >> `"$LogFile`" 2>&1"
$triggerDaily = New-ScheduledTaskTrigger -Daily -At 9am
Register-ScheduledTask -TaskName $TaskNameDaily `
  -Action $actionDaily -Trigger $triggerDaily `
  -RunLevel Highest -Force | Out-Null

# Weekly Monday 9am
$actionWeekly  = New-ScheduledTaskAction -Execute $ClaudePath -Argument "-p `"@\`"usage-reporter\`" weekly`" >> `"$LogFile`" 2>&1"
$triggerWeekly = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Monday -At 9am
Register-ScheduledTask -TaskName $TaskNameWeekly `
  -Action $actionWeekly -Trigger $triggerWeekly `
  -RunLevel Highest -Force | Out-Null

Write-Host ""
Write-Host "Scheduled:"
Write-Host "  Daily  — 9am, logs to $LogFile"
Write-Host "  Weekly — Monday 9am, logs to $LogFile"
Write-Host ""
Write-Host "To remove: .\setup-schedule.ps1 -Remove"
Write-Host "To view tasks: Get-ScheduledTask | Where-Object { `$_.TaskName -like 'ClaudeAgent*' }"
