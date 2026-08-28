-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LALootWatcher = private.NewLib("LootAdvisorLootWatcher")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAUtils = private.ImportLib("LootAdvisorUtils")
local LAUpgradeLookup = private.ImportLib("LootAdvisorUpgradeLookup")
local LALootHistoryDB = private.ImportLib("LootAdvisorLootHistoryDB")
local LADropBanner = private.ImportLib("LootAdvisorDropBanner")

---============================================================================
-- Personal Loot has no roll popup - an item is simply awarded and announced
-- in the loot chat channel. We watch that channel (CHAT_MSG_LOOT) for the
-- player's own "You receive loot: ..." lines, using Blizzard's own
-- LOOT_ITEM_SELF* format strings turned into match patterns so this doesn't
-- depend on a hardcoded, locale-specific string.
---============================================================================

local function EscapeAndCapture(fmt)
	-- Swap %s/%d placeholders for control-char markers first so the magic
	-- character escape pass below doesn't touch them, then turn the markers
	-- into capture groups.
	local s = fmt:gsub("%%s", "\1"):gsub("%%d", "\2")
	s = s:gsub("([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
	s = s:gsub("\1", "(.+)"):gsub("\2", "(%%d+)")
	return s
end

local SELF_PATTERNS = {}
local function BuildSelfPatterns()
	if #SELF_PATTERNS > 0 then
		return
	end
	-- These globals are provided by Blizzard's FrameXML and cover the
	-- singular / stacked / currency variants of "you looted this".
	local formats = { LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE }
	for _, fmt in ipairs(formats) do
		if fmt then
			table.insert(SELF_PATTERNS, EscapeAndCapture(fmt))
		end
	end
end

local currentBossName = nil

-- Registered with ENCOUNTER_START via EventHandler. Remembers the boss name
-- so loot that comes in during/shortly after the fight can be attributed to
-- it. Deliberately not cleared on ENCOUNTER_END - loot toasts often arrive
-- right as/after a kill, so "last known boss in this raid" is the better
-- guess than "no boss".
function LALootWatcher.OnEncounterStart(encounterID, encounterName)
	currentBossName = encounterName
end

-- Returns kind ("raid"/"mplus") and a source name (boss/dungeon) describing
-- where the player currently is, or nil if not somewhere LootAdvisor tracks.
function LALootWatcher.GetCurrentContext()
	local inInstance, instanceType = IsInInstance()
	if not inInstance then
		return nil
	end

	if instanceType == "raid" then
		return LAConstants.REPORT_KIND_RAID, currentBossName
	elseif instanceType == "party" then
		local isMythicPlus = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()
		if isMythicPlus then
			local dungeonName = GetInstanceInfo()
			return LAConstants.REPORT_KIND_MPLUS, dungeonName
		end
	end

	return nil
end

local function ExtractItemID(itemLink)
	if not itemLink then
		return nil
	end
	local idStr = itemLink:match("item:(%d+)")
	return idStr and tonumber(idStr)
end

-- Registered with CHAT_MSG_LOOT via EventHandler.
function LALootWatcher.OnChatMsgLoot(message)
	BuildSelfPatterns()

	local itemLink
	for _, pattern in ipairs(SELF_PATTERNS) do
		local captured = message:match(pattern)
		if captured then
			itemLink = captured
			break
		end
	end
	if not itemLink then
		return
	end

	local itemID = ExtractItemID(itemLink)
	if not itemID then
		return
	end

	local kind, source = LALootWatcher.GetCurrentContext()
	if not kind then
		return
	end

	local result = LAUpgradeLookup.Lookup(kind, itemID, source)
	if not result then
		return -- item isn't in the imported report; nothing to say about it
	end

	local pctText = LAUtils.FormatPercent(result.entry.upgradePct)
	local text
	if result.verdict == LAConstants.VERDICT_ROLL then
		text = string.format("%s  %sROLL%s  (+%s%%)", itemLink, LAConstants.COLOR_ROLL, LAConstants.COLOR_RESET, pctText)
	else
		text = string.format("%s  %sPASS%s  (+%s%%)", itemLink, LAConstants.COLOR_PASS, LAConstants.COLOR_RESET, pctText)
	end
	LADropBanner.Show(text)

	if kind == LAConstants.REPORT_KIND_RAID and source then
		LALootHistoryDB.MarkWon(source, itemID, result.entry.name)
	end
end
