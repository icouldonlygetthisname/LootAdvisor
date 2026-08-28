-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAImportFrame = private.NewLib("LootAdvisorImportFrame")

local LibStub = _G.LibStub
local AceGUI = LibStub("AceGUI-3.0")
local AL = LibStub("AceLocale-3.0"):GetLocale("LootAdvisor")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAImportService = private.ImportLib("LootAdvisorImportService")

local frame
local selectedKind = LAConstants.REPORT_KIND_RAID

local function SetStatus(status, text, isError)
	status:SetText(text)
	if isError then
		status:SetColor(1, 0.3, 0.3)
	else
		status:SetColor(0.23, 0.88, 0.24)
	end
end

local function BuildFrame()
	frame = AceGUI:Create("Frame")
	frame:SetTitle(AL["IMPORT_TITLE"])
	frame:SetLayout("Flow")
	frame:SetWidth(520)
	frame:SetHeight(480)
	frame:SetCallback("OnClose", function(widget)
		AceGUI:Release(widget)
		frame = nil
	end)

	local modeDropdown = AceGUI:Create("Dropdown")
	modeDropdown:SetLabel(AL["IMPORT_MODE_LABEL"])
	modeDropdown:SetList({
		[LAConstants.REPORT_KIND_RAID] = AL["IMPORT_MODE_RAID"],
		[LAConstants.REPORT_KIND_MPLUS] = AL["IMPORT_MODE_MPLUS"],
	})
	modeDropdown:SetValue(selectedKind)
	modeDropdown:SetWidth(220)
	modeDropdown:SetCallback("OnValueChanged", function(widget, event, key)
		selectedKind = key
	end)
	frame:AddChild(modeDropdown)

	local hint = AceGUI:Create("Label")
	hint:SetText(AL["IMPORT_PASTE_HINT"])
	hint:SetFullWidth(true)
	frame:AddChild(hint)

	local warning = AceGUI:Create("Label")
	warning:SetText(LAConstants.COLOR_WARN .. AL["IMPORT_PASTE_WARNING"] .. LAConstants.COLOR_RESET)
	warning:SetFullWidth(true)
	frame:AddChild(warning)

	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:SetLabel("")
	editBox:SetFullWidth(true)
	editBox:SetNumLines(18)
	editBox:DisableButton(true)
	frame:AddChild(editBox)

	local status = AceGUI:Create("Label")
	status:SetFullWidth(true)
	frame:AddChild(status)

	local parseButton = AceGUI:Create("Button")
	parseButton:SetText(AL["IMPORT_PARSE_BUTTON"])
	parseButton:SetWidth(160)
	parseButton:SetCallback("OnClick", function()
		local text = editBox:GetText()
		local ok, reason, count = LAImportService.Import(selectedKind, text)
		if ok then
			local kindLabel = (selectedKind == LAConstants.REPORT_KIND_RAID) and AL["IMPORT_MODE_RAID"] or AL["IMPORT_MODE_MPLUS"]
			SetStatus(status, string.format(AL["IMPORT_SUCCESS"], count, kindLabel), false)
		elseif reason == "empty" then
			SetStatus(status, AL["IMPORT_FAIL_EMPTY"], true)
		elseif reason and reason:match("^decode:") then
			SetStatus(status, AL["IMPORT_FAIL_DECODE"], true)
		else
			SetStatus(status, AL["IMPORT_FAIL_NO_ITEMS"], true)
		end
	end)
	frame:AddChild(parseButton)

	return frame
end

function LAImportFrame.Open()
	if frame then
		frame:Show()
		return
	end
	BuildFrame()
end

function LAImportFrame.Toggle()
	if frame then
		AceGUI:Release(frame)
		frame = nil
	else
		LAImportFrame.Open()
	end
end
