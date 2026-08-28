-- Locale
local AceLocale = LibStub:GetLibrary("AceLocale-3.0");
local AL = AceLocale:NewLocale("LootAdvisor", "enUS", true, true);

if AL then

AL["ADDON_LOADED_MSG"] = "Loaded. Type /loot help for commands."

-- Slash command help
AL["CMD_HELP_HEADER"] = "LootAdvisor commands:"
AL["CMD_HELP_IMPORT"] = "- opens the report import window"
AL["CMD_HELP_RAID"] = "- opens the raid roll/pass window"
AL["CMD_HELP_MPLUS"] = "- opens the Mythic+ dungeon ranking window"
AL["CMD_HELP_CONFIG"] = "- opens the options panel"
AL["CMD_HELP_HELP"] = "- shows this help"
AL["CMD_HELP_FILES"] = "Drop *-raid.json / *-mplus.json into the addon's Imports\\Raid and Imports\\MPlus folders, then run Tools\\Import-Reports.ps1 and /reload - faster than pasting for big reports."

-- Import window
AL["IMPORT_TITLE"] = "LootAdvisor - Import Report"
AL["IMPORT_MODE_LABEL"] = "Report type"
AL["IMPORT_MODE_RAID"] = "Raid"
AL["IMPORT_MODE_MPLUS"] = "Mythic+"
AL["IMPORT_PASTE_HINT"] = "Paste the raw JSON from your Raidbots Droptimizer report below, then click Parse."
AL["IMPORT_PARSE_BUTTON"] = "Parse"
AL["IMPORT_CLOSE_BUTTON"] = "Close"
AL["IMPORT_SUCCESS"] = "Imported %d item(s) from your %s report."
AL["IMPORT_FAIL_EMPTY"] = "Paste some report JSON first."
AL["IMPORT_FAIL_DECODE"] = "Couldn't parse that as JSON. Make sure you copied the whole report."
AL["IMPORT_FAIL_NO_ITEMS"] = "That JSON parsed, but no upgrade items were found in it. The report format may not match what LootAdvisor expects yet - let the author know."
AL["IMPORT_PASTE_WARNING"] = "Pasting a full report here can be slow/laggy for large reports. For big raid reports, the file-based import (Tools\\Import-Reports.ps1) is faster and recommended."

-- File-based import (Tools\Import-Reports.ps1 -> Imports\Raid, Imports\MPlus)
AL["FILE_IMPORT_SUCCESS"] = "Imported %d item(s) from your file-based %s report (%s)."
AL["FILE_IMPORT_FAIL"] = "File-based %s import (%s) failed: %s"

-- Raid window
AL["RAID_WINDOW_TITLE"] = "LootAdvisor - Raid"
AL["RAID_NO_REPORT"] = "No raid report imported yet. Use /loot import to add one."
AL["RAID_ALREADY_WON"] = "Already won this week"
AL["RAID_MARK_WON"] = "Mark won"
AL["RAID_MARK_NOT_WON"] = "Unmark"
AL["RAID_GENERATED_AT"] = "Report imported: %s"

-- M+ window
AL["MPLUS_WINDOW_TITLE"] = "LootAdvisor - Mythic+"
AL["MPLUS_NO_REPORT"] = "No Mythic+ report imported yet. Use /loot import to add one."
AL["MPLUS_BEST_UPGRADE"] = "Best upgrade: %s%%"
AL["MPLUS_GENERATED_AT"] = "Report imported: %s"

-- Bonus roll / currency advisor
AL["BONUS_ROLL_SUGGESTION"] = "Best bonus-roll target: %s from %s (+%s%%)"
AL["BONUS_ROLL_NONE_AVAILABLE"] = "No bonus rolls available."
AL["BONUS_ROLL_NO_CURRENCY_SET"] = "Pick your bonus-roll currency in /loot config to enable this."
AL["BONUS_ROLL_ALL_WON"] = "You've already won every tracked item this week."

-- Drop banner
AL["DROP_BANNER_ROLL"] = "%s  |cFF3CE13FROLL|r  (+%s%%)"
AL["DROP_BANNER_PASS"] = "%s  |cFF9D9D9DPASS|r  (+%s%%)"

-- Options
AL["OPTIONS_HEADER"] = "LootAdvisor"
AL["OPTIONS_THRESHOLD"] = "Roll threshold (%)"
AL["OPTIONS_THRESHOLD_DESC"] = "Minimum DPS upgrade percentage for an item to be marked ROLL instead of PASS."
AL["OPTIONS_CURRENCY"] = "Bonus-roll currency"
AL["OPTIONS_CURRENCY_DESC"] = "Which currency is your bonus-roll (\"voidcore\") currency. Used to recommend the best boss/item to spend it on."
AL["OPTIONS_CURRENCY_NONE"] = "- None selected -"
AL["OPTIONS_CURRENCY_SEARCH"] = "Find currency ID by name"
AL["OPTIONS_CURRENCY_SEARCH_DESC"] = "Type part of your bonus-roll currency's name (as it appears in your Currency tab) and press Enter - matches print to chat with their ID, which you can then paste above."
AL["OPTIONS_CURRENCY_SEARCH_NONE"] = "No tracked currencies matched \"%s\". Make sure it's shown in your Currency tab (Character Pane), or enter its numeric ID directly above."
AL["OPTIONS_CURRENCY_SEARCH_RESULT"] = "%s - id %d (qty %d)"
AL["OPTIONS_RESET_RAID"] = "Clear imported raid report"
AL["OPTIONS_RESET_MPLUS"] = "Clear imported Mythic+ report"
AL["OPTIONS_RESET_HISTORY"] = "Clear loot history"
AL["OPTIONS_RESET_CONFIRM"] = "Cleared."

-- Shared labels
AL["UPGRADE_LABEL"] = "Upgrade"
AL["ITEM_LEVEL_LABEL"] = "ilvl"
AL["SOURCE_LABEL"] = "Source"
AL["VERDICT_ROLL"] = "ROLL"
AL["VERDICT_PASS"] = "PASS"

end
