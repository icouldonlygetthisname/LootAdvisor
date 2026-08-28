-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAMPlusWindow = private.NewLib("LootAdvisorMPlusWindow")

local LibStub = _G.LibStub
local AceGUI = LibStub("AceGUI-3.0")
local AL = LibStub("AceLocale-3.0"):GetLocale("LootAdvisor")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAUtils = private.ImportLib("LootAdvisorUtils")
local LAReportDB = private.ImportLib("LootAdvisorReportDB")
local LAConfigDB = private.ImportLib("LootAdvisorConfigDB")

local frame

local function VerdictText(upgradePct, threshold)
	local pctText = LAUtils.FormatPercent(upgradePct)
	if upgradePct >= threshold then
		return string.format("%s%s%s  (+%s%%)", LAConstants.COLOR_ROLL, AL["VERDICT_ROLL"], LAConstants.COLOR_RESET, pctText)
	end
	return string.format("%s%s%s  (+%s%%)", LAConstants.COLOR_PASS, AL["VERDICT_PASS"], LAConstants.COLOR_RESET, pctText)
end

local function RefreshContent()
	if not frame then
		return
	end
	frame:ReleaseChildren()

	local report = LAReportDB.GetReport(LAConstants.REPORT_KIND_MPLUS)
	if not report or not report.bySource or not next(report.bySource) then
		local empty = AceGUI:Create("Label")
		empty:SetText(AL["MPLUS_NO_REPORT"])
		empty:SetFullWidth(true)
		frame:AddChild(empty)
		return
	end

	local threshold = LAConfigDB.GetThreshold()

	local genLabel = AceGUI:Create("Label")
	genLabel:SetText(string.format(AL["MPLUS_GENERATED_AT"], LAUtils.FormatTimestamp(report.generatedAt)))
	genLabel:SetFullWidth(true)
	frame:AddChild(genLabel)

	-- Rank dungeons by their single best available upgrade % - this directly
	-- answers "which key should I push for the biggest upgrade".
	local dungeons = {}
	for dungeonName, items in pairs(report.bySource) do
		local best = 0
		for _, item in ipairs(items) do
			if item.upgradePct > best then
				best = item.upgradePct
			end
		end
		table.insert(dungeons, { name = dungeonName, items = items, best = best })
	end
	table.sort(dungeons, function(a, b)
		return a.best > b.best
	end)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	scroll:SetFullWidth(true)
	scroll:SetHeight(640)
	frame:AddChild(scroll)

	for _, dungeon in ipairs(dungeons) do
		-- Build and populate the group BEFORE adding it to the scroll
		-- container - see the matching comment in RaidWindow.lua for why
		-- (otherwise the last dungeon's rows can end up stuck below the
		-- scrollable range with no way to reach them).
		local group = AceGUI:Create("InlineGroup")
		group:SetTitle(string.format("%s  -  %s", dungeon.name, string.format(AL["MPLUS_BEST_UPGRADE"], LAUtils.FormatPercent(dungeon.best))))
		group:SetFullWidth(true)
		group:SetLayout("List")

		table.sort(dungeon.items, function(a, b)
			return a.upgradePct > b.upgradePct
		end)

		for _, item in ipairs(dungeon.items) do
			local label = AceGUI:Create("Label")
			local displayName = item.name or ("item:" .. tostring(item.itemID))
			local ilvlText = item.ilvl and string.format(" (%s %s)", item.ilvl, AL["ITEM_LEVEL_LABEL"]) or ""
			label:SetText(string.format("%s%s  %s", displayName, ilvlText, VerdictText(item.upgradePct, threshold)))
			label:SetFullWidth(true)
			group:AddChild(label)
		end

		scroll:AddChild(group)
	end

	-- Belt-and-suspenders: force one final layout pass now that everything
	-- is populated, in case anything above still left the scroll region's
	-- computed height stale.
	scroll:DoLayout()
end

local function BuildFrame()
	frame = AceGUI:Create("Frame")
	frame:SetTitle(AL["MPLUS_WINDOW_TITLE"])
	frame:SetLayout("List")
	frame:SetWidth(500)
	frame:SetHeight(760)
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		frame = nil
	end)
	RefreshContent()
	return frame
end

function LAMPlusWindow.Open()
	if frame then
		RefreshContent()
		frame:Show()
		return
	end
	BuildFrame()
end

function LAMPlusWindow.Toggle()
	if frame then
		AceGUI:Release(frame)
		frame = nil
	else
		LAMPlusWindow.Open()
	end
end
