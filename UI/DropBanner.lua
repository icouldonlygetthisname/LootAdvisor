-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LADropBanner = private.NewLib("LootAdvisorDropBanner")

---============================================================================
-- A small stack of toasts, top-center of screen, each auto-fading after a
-- few seconds. No AceGUI needed here - this is intentionally a lightweight
-- raw-frame widget since it just shows a line of text.
---============================================================================

local ACTIVE_BANNERS = {}
local BANNER_WIDTH = 300
local BANNER_HEIGHT = 36
local BANNER_LIFETIME = 6 -- seconds before fade starts
local BANNER_FADE = 1.5

local function RepositionBanners()
	for i, frame in ipairs(ACTIVE_BANNERS) do
		frame:ClearAllPoints()
		frame:SetPoint("TOP", UIParent, "TOP", 0, -180 - ((i - 1) * (BANNER_HEIGHT + 6)))
	end
end

local function ReleaseBanner(frame)
	for i, f in ipairs(ACTIVE_BANNERS) do
		if f == frame then
			table.remove(ACTIVE_BANNERS, i)
			break
		end
	end
	frame:Hide()
	RepositionBanners()
end

-- Shows a toast with `text` (already colored/formatted by the caller) that
-- fades out after a few seconds.
function LADropBanner.Show(text)
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:SetSize(BANNER_WIDTH, BANNER_HEIGHT)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	frame:SetBackdropColor(0, 0, 0, 0.75)
	frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
	frame:SetFrameStrata("HIGH")

	local fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fontString:SetPoint("CENTER")
	fontString:SetText(text)

	table.insert(ACTIVE_BANNERS, frame)
	RepositionBanners()
	frame:Show()

	C_Timer.After(BANNER_LIFETIME, function()
		if not frame:IsShown() then
			return
		end
		local elapsed = 0
		frame:SetScript("OnUpdate", function(self, delta)
			elapsed = elapsed + delta
			local alpha = 1 - (elapsed / BANNER_FADE)
			if alpha <= 0 then
				self:SetScript("OnUpdate", nil)
				ReleaseBanner(self)
			else
				self:SetAlpha(alpha)
			end
		end)
	end)
end
