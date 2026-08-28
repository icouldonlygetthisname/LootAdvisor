-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAOptions = private.NewLib("LootAdvisorOptions")

local LibStub = _G.LibStub
local AL = LibStub("AceLocale-3.0"):GetLocale("LootAdvisor")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAConfigDB = private.ImportLib("LootAdvisorConfigDB")
local LAReportDB = private.ImportLib("LootAdvisorReportDB")
local LALootHistoryDB = private.ImportLib("LootAdvisorLootHistoryDB")
local LACurrencyAdvisor = private.ImportLib("LootAdvisorCurrencyAdvisor")

local function GetOptionsTable()
	return {
		type = "group",
		name = AL["OPTIONS_HEADER"],
		args = {
			threshold = {
				type = "range",
				name = AL["OPTIONS_THRESHOLD"],
				desc = AL["OPTIONS_THRESHOLD_DESC"],
				min = 0,
				max = 20,
				step = 0.1,
				bigStep = 0.5,
				get = function()
					return LAConfigDB.GetThreshold()
				end,
				set = function(_, value)
					LAConfigDB.SetThreshold(value)
				end,
				order = 1,
			},
			currencyID = {
				type = "input",
				name = AL["OPTIONS_CURRENCY"],
				desc = AL["OPTIONS_CURRENCY_DESC"],
				get = function()
					local id = LAConfigDB.GetCurrencyID()
					return id and tostring(id) or ""
				end,
				set = function(_, value)
					LAConfigDB.SetCurrencyID(tonumber(value))
				end,
				order = 2,
			},
			currencySearch = {
				type = "input",
				name = AL["OPTIONS_CURRENCY_SEARCH"],
				desc = AL["OPTIONS_CURRENCY_SEARCH_DESC"],
				get = function()
					return ""
				end,
				set = function(_, value)
					local results = LACurrencyAdvisor.FindTrackedCurrencies(value)
					if #results == 0 then
						print(string.format(AL["OPTIONS_CURRENCY_SEARCH_NONE"], value))
					else
						for _, result in ipairs(results) do
							print(string.format(AL["OPTIONS_CURRENCY_SEARCH_RESULT"], result.name, result.currencyID, result.quantity or 0))
						end
					end
				end,
				order = 3,
			},
			resetRaid = {
				type = "execute",
				name = AL["OPTIONS_RESET_RAID"],
				func = function()
					LAReportDB.ClearReport(LAConstants.REPORT_KIND_RAID)
					print(AL["OPTIONS_RESET_CONFIRM"])
				end,
				order = 4,
			},
			resetMplus = {
				type = "execute",
				name = AL["OPTIONS_RESET_MPLUS"],
				func = function()
					LAReportDB.ClearReport(LAConstants.REPORT_KIND_MPLUS)
					print(AL["OPTIONS_RESET_CONFIRM"])
				end,
				order = 5,
			},
			resetHistory = {
				type = "execute",
				name = AL["OPTIONS_RESET_HISTORY"],
				func = function()
					LALootHistoryDB.ClearAll()
					print(AL["OPTIONS_RESET_CONFIRM"])
				end,
				order = 6,
			},
		},
	}
end

-- Called once from Core\LootAdvisor.lua's OnInitialize.
function LAOptions.Setup()
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")

	AceConfig:RegisterOptionsTable(LAConstants.ADDON_NAME, GetOptionsTable())
	AceConfigDialog:AddToBlizOptions(LAConstants.ADDON_NAME, LAConstants.ADDON_NAME)
end
