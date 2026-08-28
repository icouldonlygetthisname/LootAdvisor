-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LALootHistoryDB = private.NewLib("LootAdvisorLootHistoryDB")

local LAUtils = private.ImportLib("LootAdvisorUtils")

---============================================================================
-- Storage shape (see Core\Constants.lua PROFILE_DEFAULTS):
--   private.dbchar.lootHistory[weekKey][bossName][itemID] = { won = true, itemName, timestamp }
--
-- Per-character, bucketed by weekly reset (see Utils.GetCurrentWeekKey), so
-- "already won" naturally only reflects the current lockout without needing
-- an explicit purge.
---============================================================================

-- Records that the current character won `itemID` from `bossName` this week.
-- `itemName` is stored purely for display (e.g. in a manual "already won"
-- list) so the UI doesn't need to re-resolve the item.
function LALootHistoryDB.MarkWon(bossName, itemID, itemName)
	if not bossName or not itemID then
		return
	end
	local weekKey = LAUtils.GetCurrentWeekKey()
	local history = private.dbchar.lootHistory
	history[weekKey] = history[weekKey] or {}
	history[weekKey][bossName] = history[weekKey][bossName] or {}
	history[weekKey][bossName][itemID] = {
		won = true,
		itemName = itemName,
		timestamp = time(),
	}
end

function LALootHistoryDB.UnmarkWon(bossName, itemID)
	local weekKey = LAUtils.GetCurrentWeekKey()
	local history = private.dbchar.lootHistory
	if history[weekKey] and history[weekKey][bossName] then
		history[weekKey][bossName][itemID] = nil
	end
end

-- Returns true if the current character has already won `itemID` from
-- `bossName` during the current weekly reset.
function LALootHistoryDB.HasWon(bossName, itemID)
	local weekKey = LAUtils.GetCurrentWeekKey()
	local history = private.dbchar.lootHistory
	return history[weekKey]
		and history[weekKey][bossName]
		and history[weekKey][bossName][itemID] ~= nil
		or false
end

-- Returns the set of itemIDs won this week for a given boss: { [itemID] = true, ... }
function LALootHistoryDB.GetWonForBoss(bossName)
	local weekKey = LAUtils.GetCurrentWeekKey()
	local history = private.dbchar.lootHistory
	local bossHistory = history[weekKey] and history[weekKey][bossName]
	local won = {}
	if bossHistory then
		for itemID in pairs(bossHistory) do
			won[itemID] = true
		end
	end
	return won
end

function LALootHistoryDB.ClearAll()
	private.dbchar.lootHistory = {}
end
