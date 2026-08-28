-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local LibStub = _G.LibStub
local ADDON_NAME, private = ...

local LAImportService = private.NewLib("LootAdvisorImportService")

local AL = LibStub("AceLocale-3.0"):GetLocale("LootAdvisor")

local Json = private.Json
local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAParser = private.ImportLib("LootAdvisorParser")
local LAReportDB = private.ImportLib("LootAdvisorReportDB")

local function CountEntries(normalized)
	local count = 0
	for _ in pairs(normalized.entries) do
		count = count + 1
	end
	return count
end

-- Decodes `jsonText` (raw JSON pasted by the user), extracts upgrade
-- entries, and saves the result as the current character's report of the
-- given kind (LAConstants.REPORT_KIND_RAID / REPORT_KIND_MPLUS).
--
-- NOTE: pasting a large report here goes through the pure-Lua JSON decoder
-- and a big WoW EditBox, both of which get slow on big reports. For raid-size
-- reports, prefer the file-based import (see ProcessPendingImports below).
--
-- Returns: success (boolean), message (string), itemCount (number|nil)
function LAImportService.Import(kind, jsonText)
	if not jsonText or jsonText:match("^%s*$") then
		return false, "empty", nil
	end

	local decoded, decodeErr = Json.decode(jsonText)
	if not decoded then
		return false, "decode:" .. tostring(decodeErr), nil
	end

	local normalized, parseErr = LAParser.ExtractUpgrades(decoded)
	if not normalized then
		return false, "parse:" .. tostring(parseErr), nil
	end

	LAReportDB.SaveReport(kind, normalized)

	return true, "ok", CountEntries(normalized)
end

---============================================================================
-- File-based import.
--
-- Tools\Import-Reports.ps1 (run outside the game) reads *-raid.json /
-- *-mplus.json files from Imports\Raid and Imports\MPlus, converts them to
-- plain Lua tables (no JSON decoding needed on this side at all), and writes
-- them into the LootAdvisorImportsDB SavedVariables global - a separate
-- global from LootAdvisorDB so this never touches your settings/history.
-- This is the recommended path for full raid reports: it avoids both the
-- slow paste box and the Lua JSON decoder entirely.
---============================================================================

local function ImportPendingKind(kind, rawTable, sourceFile)
	if not rawTable then
		return
	end
	local normalized, err = LAParser.ExtractUpgrades(rawTable)
	local kindLabel = (kind == LAConstants.REPORT_KIND_RAID) and AL["IMPORT_MODE_RAID"] or AL["IMPORT_MODE_MPLUS"]
	if normalized then
		LAReportDB.SaveReport(kind, normalized)
		print(string.format(AL["FILE_IMPORT_SUCCESS"], CountEntries(normalized), kindLabel, tostring(sourceFile)))
	else
		print(string.format(AL["FILE_IMPORT_FAIL"], kindLabel, tostring(sourceFile), tostring(err)))
	end
end

-- Call once at login (see Core\LootAdvisor.lua OnEnable). Safe to call every
-- login: a character with nothing pending is a no-op, and each entry is
-- consumed (cleared) once processed so it won't reprocess next time.
function LAImportService.ProcessPendingImports()
	local pendingDB = _G.LootAdvisorImportsDB
	if type(pendingDB) ~= "table" then
		return
	end

	local charName = UnitName("player")
	local pending = pendingDB[charName]
	if not pending then
		return
	end

	ImportPendingKind(LAConstants.REPORT_KIND_RAID, pending.raid, pending.raidSourceFile)
	ImportPendingKind(LAConstants.REPORT_KIND_MPLUS, pending.mplus, pending.mplusSourceFile)

	pendingDB[charName] = nil
end
