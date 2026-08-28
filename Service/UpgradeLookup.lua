-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAUpgradeLookup = private.NewLib("LootAdvisorUpgradeLookup")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAReportDB = private.ImportLib("LootAdvisorReportDB")
local LAConfigDB = private.ImportLib("LootAdvisorConfigDB")

-- Looks up `itemID` in the given report kind, optionally scoped to a known
-- boss/dungeon `source`. Returns nil if the item isn't in the imported
-- report at all, otherwise:
--   { entry = <report entry>, verdict = "ROLL"|"PASS", threshold = number }
function LAUpgradeLookup.Lookup(kind, itemID, source)
	if not itemID then
		return nil
	end

	local entry
	if source then
		entry = LAReportDB.GetEntryForSource(kind, itemID, source)
	else
		entry = LAReportDB.GetEntry(kind, itemID)
	end
	if not entry then
		return nil
	end

	local threshold = LAConfigDB.GetThreshold()
	local verdict = (entry.upgradePct >= threshold) and LAConstants.VERDICT_ROLL or LAConstants.VERDICT_PASS

	return {
		entry = entry,
		verdict = verdict,
		threshold = threshold,
	}
end

-- Convenience: true/false roll verdict for itemID, checking raid then M+.
-- Returns nil (unknown) if the item isn't in either imported report.
function LAUpgradeLookup.LookupAnyKind(itemID, source)
	local result = LAUpgradeLookup.Lookup(LAConstants.REPORT_KIND_RAID, itemID, source)
	if result then
		return result, LAConstants.REPORT_KIND_RAID
	end
	result = LAUpgradeLookup.Lookup(LAConstants.REPORT_KIND_MPLUS, itemID, source)
	if result then
		return result, LAConstants.REPORT_KIND_MPLUS
	end
	return nil
end
