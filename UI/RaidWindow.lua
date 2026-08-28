-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LARaidWindow = private.NewLib("LootAdvisorRaidWindow")

local LibStub = _G.LibStub
local AceGUI = LibStub("AceGUI-3.0")
local AL = LibStub("AceLocale-3.0"):GetLocale("LootAdvisor")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAUtils = private.ImportLib("LootAdvisorUtils")
local LAReportDB = private.ImportLib("LootAdvisorReportDB")
local LAConfigDB = private.ImportLib("LootAdvisorConfigDB")
local LALootHistoryDB = private.ImportLib("LootAdvisorLootHistoryDB")
local LACurrencyAdvisor = private.ImportLib("LootAdvisorCurrencyAdvisor")

local frame

local function VerdictText(upgradePct, threshold)
	local pctText = LAUtils.FormatPercent(upgradePct)
	if upgradePct >= threshold then
		return string.format("%s%s%s  (+%s%%)", LAConstants.COLOR_ROLL, AL["VERDICT_ROLL"], LAConstants.COLOR_RESET, pctText)
	end
	return string.format("%s%s%s  (+%s%%)", LAConstants.COLOR_PASS, AL["VERDICT_PASS"], LAConstants.COLOR_RESET, pctText)
end

local RefreshContent -- forward declaration, used by row buttons

local function AddItemRow(parent, bossName, item, threshold, won)
	local row = AceGUI:Create("SimpleGroup")
	row:SetLayout("Flow")
	row:SetFullWidth(true)
	parent:AddChild(row)

	local label = AceGUI:Create("Label")
	local displayName = item.name or ("item:" .. tostring(item.itemID))
	local ilvlText = item.ilvl and string.format(" (%s %s)", item.ilvl, AL["ITEM_LEVEL_LABEL"]) or ""
	local wonText = won and (" |cFF9D9D9D[" .. AL["RAID_ALREADY_WON"] .. "]|r") or ""
	label:SetText(string.format("%s%s  %s%s", displayName, ilvlText, VerdictText(item.upgradePct, threshold), wonText))
	label:SetWidth(340)
	row:AddChild(label)

	local markButton = AceGUI:Create("Button")
	markButton:SetText(won and AL["RAID_MARK_NOT_WON"] or AL["RAID_MARK_WON"])
	markButton:SetWidth(100)
	markButton:SetCallback("OnClick", function()
		if won then
			LALootHistoryDB.UnmarkWon(bossName, item.itemID)
		else
			LALootHistoryDB.MarkWon(bossName, item.itemID, item.name)
		end
		RefreshContent()
	end)
	row:AddChild(markButton)
end

RefreshContent = function()
	if not frame then
		return
	end
	frame:ReleaseChildren()

	local report = LAReportDB.GetReport(LAConstants.REPORT_KIND_RAID)
	if not report or not report.bySource or not next(report.bySource) then
		local empty = AceGUI:Create("Label")
		empty:SetText(AL["RAID_NO_REPORT"])
		empty:SetFullWidth(true)
		frame:AddChild(empty)
		return
	end

	-- Header rows go straight on the frame; the (potentially long) per-boss
	-- breakdown goes in a scroll container so it doesn't overflow the window.

	local threshold = LAConfigDB.GetThreshold()

	local genLabel = AceGUI:Create("Label")
	genLabel:SetText(string.format(AL["RAID_GENERATED_AT"], LAUtils.FormatTimestamp(report.generatedAt)))
	genLabel:SetFullWidth(true)
	frame:AddChild(genLabel)

	local currencyQty = LACurrencyAdvisor.GetCurrencyQuantity()
	local suggestion = AceGUI:Create("Label")
	suggestion:SetFullWidth(true)
	if currencyQty == nil then
		suggestion:SetText(LAConstants.COLOR_WARN .. AL["BONUS_ROLL_NO_CURRENCY_SET"] .. LAConstants.COLOR_RESET)
	elseif currencyQty <= 0 then
		suggestion:SetText(AL["BONUS_ROLL_NONE_AVAILABLE"])
	else
		local best = LACurrencyAdvisor.GetBestTarget()
		if best then
			suggestion:SetText(LAConstants.COLOR_HEADER .. string.format(
				AL["BONUS_ROLL_SUGGESTION"],
				best.name or ("item:" .. tostring(best.itemID)),
				best.source,
				LAUtils.FormatPercent(best.upgradePct)
			) .. LAConstants.COLOR_RESET)
		else
			suggestion:SetText(AL["BONUS_ROLL_ALL_WON"])
		end
	end
	frame:AddChild(suggestion)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	scroll:SetFullWidth(true)
	scroll:SetHeight(600)
	frame:AddChild(scroll)

	-- Stable boss ordering.
	local bossNames = {}
	for bossName in pairs(report.bySource) do
		table.insert(bossNames, bossName)
	end
	table.sort(bossNames)

	for _, bossName in ipairs(bossNames) do
		local items = report.bySource[bossName]
		table.sort(items, function(a, b)
			return a.upgradePct > b.upgradePct
		end)

		-- Build the group and populate its rows BEFORE adding it to the
		-- scroll container. scroll:AddChild() triggers the scroll frame's
		-- height recalculation immediately, reading each child's height *at
		-- that moment* - adding an empty group and filling it afterward
		-- means that recalculation never happens again for it, so the very
		-- last group added would get a stale (too-short) height and its
		-- bottom rows would be clipped with no way to scroll to them.
		local group = AceGUI:Create("InlineGroup")
		group:SetTitle(bossName)
		group:SetFullWidth(true)
		group:SetLayout("List")

		local won = LALootHistoryDB.GetWonForBoss(bossName)
		for _, item in ipairs(items) do
			AddItemRow(group, bossName, item, threshold, won[item.itemID] or false)
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
	frame:SetTitle(AL["RAID_WINDOW_TITLE"])
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

function LARaidWindow.Open()
	if frame then
		RefreshContent()
		frame:Show()
		return
	end
	BuildFrame()
end

function LARaidWindow.Toggle()
	if frame then
		AceGUI:Release(frame)
		frame = nil
	else
		LARaidWindow.Open()
	end
end
