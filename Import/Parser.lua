-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAParser = private.NewLib("LootAdvisorParser")

---============================================================================
-- Raidbots Droptimizer report JSON -> normalized LootAdvisor report
--
-- Confirmed against a real report (2026-08-28). Raidbots does NOT ship a
-- precomputed "upgrade %" field anywhere - the report is a raw SimC output.
-- The shape that matters:
--
--   <report>.sim.players[1].collected_data.dps.mean
--       -- baseline DPS with currently equipped gear, no swaps.
--   <report>.sim.profilesets.results[n] = {
--       name = "<instanceId>/<encounterId>/<sourceKey>/<itemId>/<itemLevel>/<bonusId>/<slot>/...",
--       mean = <dps with that single item swapped in>,
--       ...
--   }
--       -- upgrade% for that candidate = (mean - baseline) / baseline * 100.
--       -- encounterId/instanceId in the name are frequently -1 (not resolvable
--       -- on their own, especially for M+), so they're only used to pull the
--       -- itemId back out - NOT for the display source name.
--   <report>...itemLibrary[n] = {
--       id = <itemId>, name = <item name>, itemLevel = <ilvl>,
--       encounter = { name = <boss name>, ... },              -- may be absent
--       overrides = { instance = { name = <raid/dungeon name>, ... } },
--   }
--       -- the authoritative item catalog: gives a clean display name and the
--       -- boss (raid) or zone (M+) this item actually belongs to. This is
--       -- searched for generically (matched by shape, not by exact path)
--       -- since its exact nesting varies and isn't worth hardcoding.
--
-- Both "sim" blocks (baseline+profilesets) and itemLibrary arrays are found
-- via a generic recursive shape search rather than a single hardcoded path,
-- so this keeps working if Raidbots nests things slightly differently
-- between raid/M+ reports or across report format revisions.
--
-- Normalized shape returned by LAParser.ExtractUpgrades:
--   {
--     generatedAt = epoch,
--     entries = {
--       -- best (highest %) source for each item - fast lookup by itemID
--       -- alone, e.g. for the live drop banner.
--       [itemID] = { itemID, name, ilvl, source, upgradePct },
--       ...
--     },
--     bySource = {
--       -- every item grouped under the boss/zone it came from - used by the
--       -- Raid/M+ windows to build a per-boss or per-dungeon list.
--       [sourceName] = {
--         { itemID, name, ilvl, source, upgradePct },
--         ...
--       },
--     },
--   }
---============================================================================

-- Splits `str` on "/" preserving empty fields (Lua's usual gmatch-based split
-- idioms drop empty trailing segments, which the profileset name format
-- relies on - e.g. ".../main_hand////" has 4 trailing empty fields).
local function splitBySlash(str)
	local parts = {}
	local pos = 1
	while true do
		local slashPos = string.find(str, "/", pos, true)
		if not slashPos then
			table.insert(parts, string.sub(str, pos))
			break
		end
		table.insert(parts, string.sub(str, pos, slashPos - 1))
		pos = slashPos + 1
	end
	return parts
end

---============================================================================
-- Item catalog: itemId -> { name, ilvl, source }
---============================================================================

-- `quality` is required specifically to avoid matching Raidbots' embedded
-- boss/encounter catalog arrays, which also look like {id=N, name=S,
-- icon=S, ...} but have no `quality` - without this, a boss list would get
-- misdetected as an item catalog too (harmless in practice since encounter
-- IDs and item IDs don't collide, but wasteful and worth avoiding).
local function looksLikeItemCatalogEntry(t)
	return type(t) == "table"
		and type(t.id) == "number"
		and type(t.name) == "string"
		and type(t.quality) == "number"
		and (type(t.itemLevel) == "number" or t.itemLevel == nil)
end

local function catalogSourceName(item)
	if type(item.encounter) == "table" and type(item.encounter.name) == "string" then
		return item.encounter.name
	end
	if type(item.overrides) == "table"
		and type(item.overrides.instance) == "table"
		and type(item.overrides.instance.name) == "string"
	then
		return item.overrides.instance.name
	end
	if type(item.instance) == "table" and type(item.instance.name) == "string" then
		return item.instance.name
	end
	return nil
end

local function findItemCatalog(node, catalog, seen, depth)
	if depth > 16 or type(node) ~= "table" then
		return
	end
	if seen[node] then
		return
	end
	seen[node] = true

	if node[1] ~= nil and looksLikeItemCatalogEntry(node[1]) then
		for _, item in ipairs(node) do
			if looksLikeItemCatalogEntry(item) then
				catalog[item.id] = {
					name = item.name,
					ilvl = item.itemLevel,
					source = catalogSourceName(item),
				}
			end
		end
		return
	end

	for _, v in pairs(node) do
		if type(v) == "table" then
			findItemCatalog(v, catalog, seen, depth + 1)
		end
	end
end

---============================================================================
-- Sim blocks: baseline DPS + profileset results
---============================================================================

local function getBaselineMean(simBlock)
	local players = simBlock.players
	if type(players) ~= "table" or type(players[1]) ~= "table" then
		return nil
	end
	local collected = players[1].collected_data
	if type(collected) ~= "table" or type(collected.dps) ~= "table" then
		return nil
	end
	return collected.dps.mean
end

local function looksLikeSimBlock(t)
	if type(t) ~= "table" then
		return false
	end
	if type(getBaselineMean(t)) ~= "number" then
		return false
	end
	return type(t.profilesets) == "table" and type(t.profilesets.results) == "table"
end

local function findSimBlocks(node, found, seen, depth)
	if depth > 16 or type(node) ~= "table" then
		return
	end
	if seen[node] then
		return
	end
	seen[node] = true

	if looksLikeSimBlock(node) then
		table.insert(found, node)
		return
	end

	for _, v in pairs(node) do
		if type(v) == "table" then
			findSimBlocks(v, found, seen, depth + 1)
		end
	end
end

-- Extracts and normalizes upgrade entries from a decoded Raidbots report.
-- Returns a normalized report table, or nil + an error message if nothing
-- usable could be found.
function LAParser.ExtractUpgrades(decodedJson)
	if type(decodedJson) ~= "table" then
		return nil, "decoded report is not a table"
	end

	local catalog = {}
	findItemCatalog(decodedJson, catalog, {}, 0)

	local simBlocks = {}
	findSimBlocks(decodedJson, simBlocks, {}, 0)

	if #simBlocks == 0 then
		return nil, "couldn't find simulation results (baseline DPS + profilesets) in this report"
	end

	-- Merge every sim block's results into one deduped set, keyed by
	-- itemID + source. If the same key shows up more than once (multiple
	-- swap variants for the same item/boss, e.g. trinket1 vs trinket2, or a
	-- duplicate across sim blocks), keep whichever has the higher %.
	local bySourceKey = {}
	local count = 0
	for _, simBlock in ipairs(simBlocks) do
		local baseline = getBaselineMean(simBlock)
		for _, result in ipairs(simBlock.profilesets.results) do
			if type(result) == "table" and type(result.name) == "string" and result.name ~= ""
				and type(result.mean) == "number" and baseline and baseline ~= 0
			then
				local fields = splitBySlash(result.name)
				local itemID = tonumber(fields[4])
				if itemID then
					local upgradePct = (result.mean - baseline) / baseline * 100
					local catalogEntry = catalog[itemID]
					local source = (catalogEntry and catalogEntry.source) or "Unknown"
					local key = tostring(itemID) .. "|" .. tostring(source)

					local existing = bySourceKey[key]
					if not existing or upgradePct > existing.upgradePct then
						bySourceKey[key] = {
							itemID = itemID,
							name = catalogEntry and catalogEntry.name,
							ilvl = (catalogEntry and catalogEntry.ilvl) or tonumber(fields[5]),
							source = source,
							upgradePct = upgradePct,
						}
						if not existing then
							count = count + 1
						end
					end
				end
			end
		end
	end

	if count == 0 then
		return nil, "no upgrade candidates found in this report's simulation results"
	end

	-- Build the two views described above from the deduped set.
	local entries = {}
	local bySource = {}
	for _, entry in pairs(bySourceKey) do
		bySource[entry.source] = bySource[entry.source] or {}
		table.insert(bySource[entry.source], entry)

		local best = entries[entry.itemID]
		if not best or entry.upgradePct > best.upgradePct then
			entries[entry.itemID] = entry
		end
	end

	return {
		generatedAt = time(),
		entries = entries,
		bySource = bySource,
	}
end
