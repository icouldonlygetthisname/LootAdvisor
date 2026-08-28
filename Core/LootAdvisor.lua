-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local LibStub = _G.LibStub
local ADDON_NAME, private = ...

local LootAdvisor = LibStub("AceAddon-3.0"):NewAddon("LootAdvisor", "AceConsole-3.0")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAEventHandler = private.ImportLib("LootAdvisorEventHandler")
local LACommandLine = private.ImportLib("LootAdvisorCommandLine")
local LAOptions = private.ImportLib("LootAdvisorOptions")
local LAImportService = private.ImportLib("LootAdvisorImportService")

function LootAdvisor:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LootAdvisorDB", LAConstants.PROFILE_DEFAULTS, true)

	-- Shared, mirrors RareScanner's private.db/private.dbchar convention:
	-- every Data\*.lua file reads/writes through these rather than touching
	-- self.db directly.
	private.dbm = self.db
	private.db = self.db.profile
	private.dbchar = self.db.char

	LAOptions.Setup()

	self:RegisterChatCommand(LAConstants.SLASH_CMD, LACommandLine.SlashCommand)
	self:RegisterChatCommand(LAConstants.SLASH_CMD_ALT, LACommandLine.SlashCommand)
end

function LootAdvisor:OnEnable()
	LAEventHandler.RegisterEvents()

	-- Character name/realm aren't reliable before PLAYER_LOGIN, so file-based
	-- import processing waits until here rather than OnInitialize.
	LAImportService.ProcessPendingImports()

	local AL = LibStub("AceLocale-3.0"):GetLocale("LootAdvisor")
	print(LAConstants.COLOR_HEADER .. LAConstants.ADDON_NAME .. LAConstants.COLOR_RESET .. " " .. AL["ADDON_LOADED_MSG"])
end
