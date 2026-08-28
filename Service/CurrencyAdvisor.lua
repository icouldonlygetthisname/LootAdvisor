-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LACurrencyAdvisor = private.NewLib("LootAdvisorCurrencyAdvisor")

local LAConstants = private.ImportLib("LootAdvisorConstants")
local LAConfigDB = private.ImportLib("LootAdvisorConfigDB")
local LAReportDB = private.ImportLib("LootAdvisorReportDB")
local LALootHistoryDB = private.ImportLib("LootAdvisorLootHistoryDB")

---============================================================================
-- Currency quantity
---============================================================================

-- Returns the current quantity of the configured bonus-roll ("voidcore")
-- currency, or nil if none has been configured yet in /loot config.
function LACurrencyAdvisor.GetCurrencyQuantity()
	local currencyID = LAConfigDB.GetCurrencyID()
	if not currencyID then
		return nil
	end
	local ok, info = pcall(C_CurrencyInfo.GetCurrencyInfo, currencyID)
	if ok and info then
		return info.quantity or 0
	end
	return 0
end

-- Best-effort lookup of currencies currently visible in the player's
-- Currency tab, matching `query` against their display name (case
-- insensitive substring match; empty/nil query returns everything tracked).
-- Wrapped defensively: if the currency-list API isn't available the way we
-- expect on this client, this just returns an empty list instead of erroring,
-- and the options panel falls back to manual currency-ID entry.
function LACurrencyAdvisor.FindTrackedCurrencies(query)
	local results = {}
	local ok = pcall(function()
		local n = C_CurrencyInfo.GetCurrencyListSize()
		for i = 1, n do
			local info = C_CurrencyInfo.GetCurrencyListInfo(i)
			if info and not info.isHeader and info.name then
				if not query or query == "" or info.name:lower():find(query:lower(), 1, true) then
					local link = C_CurrencyInfo.GetCurrencyListLink(i)
					local currencyID = link and C_CurrencyInfo.GetCurrencyIDFromLink(link)
					if currencyID then
						table.insert(results, { name = info.name, currencyID = currencyID, quantity = info.quantity })
					end
				end
			end
		end
	end)
	if not ok then
		return {}
	end
	return results
end

---============================================================================
-- Best bonus-roll target
---============================================================================

-- Across the imported raid report, finds the highest-upgrade% item that
-- hasn't already been won this week for its boss. Returns nil if there's no
-- raid report imported, or every tracked item has already been won.
function LACurrencyAdvisor.GetBestTarget()
	local bySource = LAReportDB.GetBySource(LAConstants.REPORT_KIND_RAID)
	local best

	for bossName, items in pairs(bySource) do
		local won = LALootHistoryDB.GetWonForBoss(bossName)
		for _, item in ipairs(items) do
			if not won[item.itemID] then
				if not best or item.upgradePct > best.upgradePct then
					best = item
				end
			end
		end
	end

	return best
end
