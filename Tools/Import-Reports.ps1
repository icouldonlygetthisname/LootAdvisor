<#
.SYNOPSIS
    Converts Raidbots Droptimizer report JSON files dropped into
    Imports\Raid and Imports\MPlus into LootAdvisor's SavedVariables file,
    so the addon can pick them up on next login/reload without ever pasting
    a large report into the game's UI.

.DESCRIPTION
    WoW addons cannot read arbitrary files from disk or make web requests -
    the only file WoW itself will load for an addon is its SavedVariables
    file, written to WTF\Account\<Account>\SavedVariables\LootAdvisor.lua.
    This script does the JSON -> Lua conversion out here (fast, unrestricted)
    and writes the result into a SEPARATE global in that file
    (LootAdvisorImportsDB) so it never touches LootAdvisorDB - your settings,
    imported reports, and loot history are never at risk from this script.

    Run it any time after dropping new *-raid.json / *-mplus.json files into
    Imports\Raid / Imports\MPlus. Then /reload (or log in) in-game.

.NOTES
    Run this from PowerShell (right-click -> Run with PowerShell, or
    `./Import-Reports.ps1` from a PowerShell prompt in this folder).
#>

$ErrorActionPreference = "Stop"

function ConvertTo-LuaLiteral {
	param(
		$Value,
		[int]$IndentLevel = 0
	)

	$indent = "    " * $IndentLevel
	$childIndent = "    " * ($IndentLevel + 1)

	if ($null -eq $Value) {
		return "nil"
	}
	elseif ($Value -is [bool]) {
		if ($Value) { return "true" } else { return "false" }
	}
	elseif ($Value -is [string]) {
		$escaped = $Value.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", '\n').Replace("`t", '\t')
		return '"' + $escaped + '"'
	}
	elseif ($Value -is [double] -or $Value -is [int] -or $Value -is [int64] -or $Value -is [decimal] -or $Value -is [single]) {
		return [string]$Value
	}
	elseif ($Value -is [PSCustomObject]) {
		$items = @()
		foreach ($prop in $Value.PSObject.Properties) {
			$key = '["' + ($prop.Name.Replace('\', '\\').Replace('"', '\"')) + '"]'
			$items += "$childIndent$key = $(ConvertTo-LuaLiteral -Value $prop.Value -IndentLevel ($IndentLevel + 1))"
		}
		if ($items.Count -eq 0) { return "{}" }
		return "{`n" + ($items -join ",`n") + "`n$indent}"
	}
	elseif ($Value -is [System.Collections.IEnumerable]) {
		$items = @()
		foreach ($item in $Value) {
			$items += "$childIndent$(ConvertTo-LuaLiteral -Value $item -IndentLevel ($IndentLevel + 1))"
		}
		if ($items.Count -eq 0) { return "{}" }
		return "{`n" + ($items -join ",`n") + "`n$indent}"
	}
	else {
		return '"' + ($Value.ToString().Replace('\', '\\').Replace('"', '\"')) + '"'
	}
}

# --- Locate folders -----------------------------------------------------

$ToolsDir = $PSScriptRoot
$AddonRoot = Split-Path -Parent $ToolsDir              # ...\LootAdvisor
$AddOnsDir = Split-Path -Parent $AddonRoot             # ...\AddOns
$InterfaceDir = Split-Path -Parent $AddOnsDir          # ...\Interface
$RetailRoot = Split-Path -Parent $InterfaceDir         # ..._retail_

$RaidDir = Join-Path $AddonRoot "Imports\Raid"
$MPlusDir = Join-Path $AddonRoot "Imports\MPlus"
New-Item -ItemType Directory -Force -Path $RaidDir | Out-Null
New-Item -ItemType Directory -Force -Path $MPlusDir | Out-Null

$AccountsDir = Join-Path $RetailRoot "WTF\Account"
if (-not (Test-Path $AccountsDir)) {
	Write-Error "Could not find WTF\Account under `"$RetailRoot`". This script expects to live at <WoW>\_retail_\Interface\AddOns\LootAdvisor\Tools\Import-Reports.ps1 - if you moved it, run it from its original location."
	exit 1
}

# --- Gather *-raid.json / *-mplus.json files, keyed by character name ---

$pending = @{}

function Add-Pending {
	param($CharName, $Kind, $FilePath)
	$json = Get-Content -Raw -Path $FilePath -Encoding UTF8
	# Windows PowerShell 5.1's ConvertFrom-Json has no -Depth parameter at all
	# (it's PowerShell 6+ only, and 5.1 errors out if you pass it) - it has a
	# fixed internal limit of 100, which is plenty for a Droptimizer report.
	if ($PSVersionTable.PSVersion.Major -ge 6) {
		$obj = $json | ConvertFrom-Json -Depth 64
	}
	else {
		$obj = $json | ConvertFrom-Json
	}
	if (-not $pending.ContainsKey($CharName)) {
		$pending[$CharName] = @{}
	}
	$pending[$CharName]["$($Kind)Data"] = $obj
	$pending[$CharName]["$($Kind)File"] = (Split-Path -Leaf $FilePath)
}

$raidFiles = Get-ChildItem -Path $RaidDir -Filter "*-raid.json" -File -ErrorAction SilentlyContinue
foreach ($file in $raidFiles) {
	$charName = $file.BaseName -replace '-raid$', ''
	Write-Host "Reading raid report for $charName ($($file.Name))..."
	Add-Pending -CharName $charName -Kind "raid" -FilePath $file.FullName
}

$mplusFiles = Get-ChildItem -Path $MPlusDir -Filter "*-mplus.json" -File -ErrorAction SilentlyContinue
foreach ($file in $mplusFiles) {
	$charName = $file.BaseName -replace '-mplus$', ''
	Write-Host "Reading Mythic+ report for $charName ($($file.Name))..."
	Add-Pending -CharName $charName -Kind "mplus" -FilePath $file.FullName
}

if ($pending.Count -eq 0) {
	Write-Host "No *-raid.json / *-mplus.json files found in:"
	Write-Host "  $RaidDir"
	Write-Host "  $MPlusDir"
	Write-Host "Nothing to do."
	exit 0
}

# --- Build the LootAdvisorImportsDB Lua block ----------------------------

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("LootAdvisorImportsDB = {")
foreach ($charName in $pending.Keys) {
	$entry = $pending[$charName]
	$keyLiteral = '["' + ($charName.Replace('\', '\\').Replace('"', '\"')) + '"]'
	[void]$sb.AppendLine("    $keyLiteral = {")
	if ($entry.ContainsKey("raidData")) {
		[void]$sb.AppendLine("        raid = $(ConvertTo-LuaLiteral -Value $entry.raidData -IndentLevel 2),")
		[void]$sb.AppendLine("        raidSourceFile = `"$($entry.raidFile)`",")
	}
	if ($entry.ContainsKey("mplusData")) {
		[void]$sb.AppendLine("        mplus = $(ConvertTo-LuaLiteral -Value $entry.mplusData -IndentLevel 2),")
		[void]$sb.AppendLine("        mplusSourceFile = `"$($entry.mplusFile)`",")
	}
	[void]$sb.AppendLine("    },")
}
[void]$sb.AppendLine("}")
$newBlock = $sb.ToString()

# --- Write into every account's SavedVariables\LootAdvisor.lua ----------
# Only the LootAdvisorImportsDB block is touched; LootAdvisorDB (settings,
# already-imported reports, loot history) is left completely alone.

$accountDirs = Get-ChildItem -Path $AccountsDir -Directory -ErrorAction SilentlyContinue
$writtenCount = 0

foreach ($account in $accountDirs) {
	$svDir = Join-Path $account.FullName "SavedVariables"
	if (-not (Test-Path $svDir)) {
		continue
	}
	$svFile = Join-Path $svDir "LootAdvisor.lua"

	$existing = ""
	if (Test-Path $svFile) {
		$existing = Get-Content -Raw -Path $svFile -Encoding UTF8
		$existing = [regex]::Replace($existing, '(?ms)^LootAdvisorImportsDB\s*=\s*\{.*?^\}\s*\r?\n?', '')
	}

	$final = $existing.TrimEnd() + "`n`n" + $newBlock
	Set-Content -Path $svFile -Value $final -Encoding UTF8 -NoNewline
	$writtenCount++
	Write-Host "Wrote pending import(s) for $($pending.Keys -join ', ') to:"
	Write-Host "  $svFile"
}

if ($writtenCount -eq 0) {
	Write-Warning "No SavedVariables folder found under any account in $AccountsDir. Log into WoW with LootAdvisor installed at least once first, then re-run this script."
	exit 1
}

# Clean up processed source files so they aren't re-imported by accident.
$raidFiles | Remove-Item -Force -ErrorAction SilentlyContinue
$mplusFiles | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. /reload (or log in) as $($pending.Keys -join ', ') in-game to finish the import."
Write-Warning "If WoW is currently running, do this now: WoW only writes SavedVariables back to disk on logout/reload, so if something else triggers a save (camping, another /reload) before you pick this up, it'll overwrite what this script just wrote and you'll need to run it again."
