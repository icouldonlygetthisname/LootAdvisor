-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAUtils = private.NewLib("LootAdvisorUtils")

---============================================================================
-- Player identity
---============================================================================

-- Returns a stable "Name-Realm" key for the current character, matching the
-- format Raidbots reports use for their `player.name` field so imported
-- reports can be matched to the character that ran the sim.
function LAUtils.GetPlayerKey()
	local name = UnitName("player")
	local realm = GetRealmName()
	if realm then
		realm = realm:gsub("%s+", "")
	end
	return string.format("%s-%s", name or "Unknown", realm or "Unknown")
end

---============================================================================
-- Weekly reset bucketing (for "already won this week" loot history)
---============================================================================

-- Returns a key identifying the current weekly reset period, e.g. "2026-35".
-- Items won are bucketed by this key so history naturally separates by week
-- without needing an explicit purge on reset.
function LAUtils.GetCurrentWeekKey()
	-- GetQuestResetTime()/C_DateAndTime aren't reliably weekly-reset-aware
	-- across regions, so we approximate with ISO week number from the
	-- server's current date - accurate enough for "did I win this recently"
	-- bucketing, and self-corrects every reset.
	local t = date("*t")
	local dayOfYear = t.yday
	local isoWeek = math.floor((dayOfYear - 1) / 7) + 1
	return string.format("%d-%02d", t.year, isoWeek)
end

---============================================================================
-- Formatting
---============================================================================

function LAUtils.FormatPercent(pct)
	if not pct then
		return "0.00"
	end
	return string.format("%.2f", pct)
end

function LAUtils.FormatTimestamp(epoch)
	if not epoch then
		return "?"
	end
	return date("%Y-%m-%d %H:%M", epoch)
end
