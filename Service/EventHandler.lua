-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAEventHandler = private.NewLib("LootAdvisorEventHandler")

local LALootWatcher = private.ImportLib("LootAdvisorLootWatcher")

local eventFrame

-- Single event frame + dispatch table, in the spirit of RareScanner's
-- RSEventHandler (one frame for the whole addon rather than one per module).
local DISPATCH = {
	ENCOUNTER_START = function(encounterID, encounterName, difficultyID, groupSize)
		LALootWatcher.OnEncounterStart(encounterID, encounterName, difficultyID, groupSize)
	end,
	CHAT_MSG_LOOT = function(message)
		LALootWatcher.OnChatMsgLoot(message)
	end,
}

local function OnEvent(self, event, ...)
	local handler = DISPATCH[event]
	if handler then
		handler(...)
	end
end

function LAEventHandler.RegisterEvents()
	if eventFrame then
		return
	end
	eventFrame = CreateFrame("Frame")
	for event in pairs(DISPATCH) do
		eventFrame:RegisterEvent(event)
	end
	eventFrame:SetScript("OnEvent", OnEvent)
end
