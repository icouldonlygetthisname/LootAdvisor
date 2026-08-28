-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAConfigDB = private.NewLib("LootAdvisorConfigDB")

local LAConstants = private.ImportLib("LootAdvisorConstants")

---============================================================================
-- Roll threshold
---============================================================================

function LAConfigDB.GetThreshold()
	return private.db.settings.threshold or LAConstants.DEFAULT_THRESHOLD
end

function LAConfigDB.SetThreshold(value)
	private.db.settings.threshold = value
end

---============================================================================
-- Bonus-roll ("voidcore") currency
---============================================================================

function LAConfigDB.GetCurrencyID()
	return private.db.settings.currencyID
end

function LAConfigDB.SetCurrencyID(currencyID)
	private.db.settings.currencyID = currencyID
end
