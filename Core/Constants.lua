-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local LAConstants = private.NewLib("LootAdvisorConstants")

---============================================================================
-- General
---============================================================================

LAConstants.ADDON_NAME = "LootAdvisor"
LAConstants.SLASH_CMD = "loot"
LAConstants.SLASH_CMD_ALT = "la"

-- Default minimum DPS-upgrade percentage for an item to be considered a ROLL.
-- The user asked for 0.9% specifically.
LAConstants.DEFAULT_THRESHOLD = 0.9

---============================================================================
-- Report kinds
---============================================================================

LAConstants.REPORT_KIND_RAID = "raid"
LAConstants.REPORT_KIND_MPLUS = "mplus"

LAConstants.SOURCE_TYPE_BOSS = "boss"
LAConstants.SOURCE_TYPE_VAULT = "vault"
LAConstants.SOURCE_TYPE_DUNGEON_END = "dungeonEnd"

---============================================================================
-- Verdicts
---============================================================================

LAConstants.VERDICT_ROLL = "ROLL"
LAConstants.VERDICT_PASS = "PASS"

---============================================================================
-- Colors (chat / UI text)
---============================================================================

LAConstants.COLOR_ROLL = "|cFF3CE13F"   -- green
LAConstants.COLOR_PASS = "|cFF9D9D9D"   -- grey
LAConstants.COLOR_HEADER = "|cFF00C0FA" -- light blue
LAConstants.COLOR_WARN = "|cFFFFD100"   -- gold
LAConstants.COLOR_RESET = "|r"

---============================================================================
-- Slash sub-commands
---============================================================================

LAConstants.CMD_IMPORT = "import"
LAConstants.CMD_RAID = "raid"
LAConstants.CMD_MPLUS = "mplus"
LAConstants.CMD_CONFIG = "config"
LAConstants.CMD_HELP = "help"

---============================================================================
-- AceDB defaults
---============================================================================

LAConstants.PROFILE_DEFAULTS = {
	profile = {
		settings = {
			threshold = LAConstants.DEFAULT_THRESHOLD,
			currencyID = nil,
			debugMode = false,
		},
		reports = {
			raid = {},
			mplus = {},
		},
	},
	char = {
		lootHistory = {},
	},
}
