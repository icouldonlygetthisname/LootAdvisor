LootAdvisor - file-based report import
=======================================

1. Open your Raidbots Droptimizer report in a browser.
2. Copy the report's raw JSON (the report page itself, or its JSON data
   endpoint - whatever you'd otherwise paste into the in-game import window).
3. Save it as a .json file, named after your character:

     Imports\Raid\<CharacterName>-raid.json
     Imports\MPlus\<CharacterName>-mplus.json

   Example: Imports\Raid\Thrall-raid.json

4. Run Tools\Import-Reports.ps1 (right-click it -> Run with PowerShell, or
   open a PowerShell window in this folder and run
   ".\Tools\Import-Reports.ps1"). It converts the JSON and writes it into
   your account's SavedVariables - it does not touch WoW while it's running.
5. In-game: /reload (or just log in). LootAdvisor picks up the import
   automatically for whichever character matches the file name and prints a
   confirmation to chat. The .json files are deleted after a successful run
   so you don't reimport the same report by accident.

   IMPORTANT: if WoW is already running when you run the script, /reload
   right away. WoW only writes its SavedVariables file on logout/reload, so
   if something else saves first (camping out, another /reload) before you
   do, it'll overwrite what the script just wrote and you'll need to run it
   again.

This avoids pasting large reports into the in-game import window, which can
be slow/laggy for full raid reports. The in-game /loot import window still
works and is fine for small reports (or if you'd rather not leave the game).
