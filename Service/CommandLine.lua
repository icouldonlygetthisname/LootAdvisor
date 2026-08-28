-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LACommandLine = private.NewLib("LootAdvisorCommandLine")

local LibStub = _G.LibStub
local AL = LibStub("AceLocale-3.0"):GetLocale("LootAdvisor")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAImportFrame = private.ImportLib("LootAdvisorImportFrame")
local LARaidWindow = private.ImportLib("LootAdvisorRaidWindow")
local LAMPlusWindow = private.ImportLib("LootAdvisorMPlusWindow")

local function PrintHelp()
	print(LAConstants.COLOR_HEADER .. AL["CMD_HELP_HEADER"] .. LAConstants.COLOR_RESET)
	print(string.format("  /%s %s %s", LAConstants.SLASH_CMD, LAConstants.CMD_IMPORT, AL["CMD_HELP_IMPORT"]))
	print(string.format("  /%s %s %s", LAConstants.SLASH_CMD, LAConstants.CMD_RAID, AL["CMD_HELP_RAID"]))
	print(string.format("  /%s %s %s", LAConstants.SLASH_CMD, LAConstants.CMD_MPLUS, AL["CMD_HELP_MPLUS"]))
	print(string.format("  /%s %s %s", LAConstants.SLASH_CMD, LAConstants.CMD_CONFIG, AL["CMD_HELP_CONFIG"]))
	print(string.format("  /%s %s %s", LAConstants.SLASH_CMD, LAConstants.CMD_HELP, AL["CMD_HELP_HELP"]))
	print(LAConstants.COLOR_HEADER .. AL["CMD_HELP_FILES"] .. LAConstants.COLOR_RESET)
end

-- Registered as the AceConsole chat command handler in Core\LootAdvisor.lua.
function LACommandLine.SlashCommand(input)
	-- strtrim is a Blizzard FrameXML global; plain Lua has no string:trim().
	local command = strtrim(input or ""):lower()

	if command == LAConstants.CMD_IMPORT then
		LAImportFrame.Open()
	elseif command == LAConstants.CMD_RAID then
		LARaidWindow.Open()
	elseif command == LAConstants.CMD_MPLUS then
		LAMPlusWindow.Open()
	elseif command == LAConstants.CMD_CONFIG then
		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		Settings.OpenToCategory(AceConfigDialog.BlizOptionsIDMap[LAConstants.ADDON_NAME])
	else
		PrintHelp()
	end
end
