-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAReportDB = private.NewLib("LootAdvisorReportDB")

local LAUtils = private.ImportLib("LootAdvisorUtils")

---============================================================================
-- Storage shape (see Core\Constants.lua PROFILE_DEFAULTS):
--   private.db.reports[kind][playerKey] = {
--       generatedAt = epoch,
--       entries = { [itemID] = { itemID, name, ilvl, slot, source, sourceType, upgradePct } },
--   }
-- kind is LAConstants.REPORT_KIND_RAID or REPORT_KIND_MPLUS.
---============================================================================

-- Saves a normalized report (see Import\Parser.lua) for the current character.
function LAReportDB.SaveReport(kind, normalizedReport)
	local playerKey = LAUtils.GetPlayerKey()
	private.db.reports[kind][playerKey] = normalizedReport
end

-- Returns the normalized report for the current character, or nil if none
-- has been imported yet.
function LAReportDB.GetReport(kind)
	local playerKey = LAUtils.GetPlayerKey()
	return private.db.reports[kind][playerKey]
end

function LAReportDB.ClearReport(kind)
	local playerKey = LAUtils.GetPlayerKey()
	private.db.reports[kind][playerKey] = nil
end

-- Returns the best-known entry for a specific itemID from the given report
-- kind, or nil if that item isn't in the report at all.
function LAReportDB.GetEntry(kind, itemID)
	local report = LAReportDB.GetReport(kind)
	if not report or not report.entries then
		return nil
	end
	return report.entries[itemID]
end

-- Returns the entry for itemID scoped to a specific boss/dungeon `source`
-- name if one exists, otherwise falls back to the best-known entry for that
-- item anywhere in the report. Used when the caller knows the current
-- boss/dungeon (e.g. a live loot drop) and wants the most accurate %.
function LAReportDB.GetEntryForSource(kind, itemID, source)
	local report = LAReportDB.GetReport(kind)
	if not report then
		return nil
	end
	if source and report.bySource and report.bySource[source] then
		for _, entry in ipairs(report.bySource[source]) do
			if entry.itemID == itemID then
				return entry
			end
		end
	end
	return report.entries and report.entries[itemID]
end

-- Returns report.bySource: { [sourceName] = { entry, entry, ... }, ... }
-- or an empty table if no report has been imported.
function LAReportDB.GetBySource(kind)
	local report = LAReportDB.GetReport(kind)
	return (report and report.bySource) or {}
end
