# LootAdvisor

A World of Warcraft addon that tells you which raid and Mythic+ items are worth rolling on, based on your own [Raidbots](https://www.raidbots.com/) Droptimizer reports - and ranks Mythic+ dungeons by their biggest available upgrade.

## Features

- **Roll/Pass calls** on raid loot, boss by boss, colored against a configurable DPS-upgrade threshold (default 0.9%).
- **Mythic+ dungeon ranking** - see at a glance which dungeon is worth pushing keys in for the biggest upgrade.
- **Live drop banner** - when a tracked item drops (Personal Loot), a toast shows its upgrade % and verdict immediately.
- **Loot history tracking** - marks items you've already won this week per boss, with a manual override.
- **Bonus-roll advisor** - if you track a bonus-roll ("voidcore"-style) currency, it recommends the best not-yet-won item to spend one on.
- **Two import paths**:
  - Paste a report's JSON straight into an in-game window (`/loot import`) - fine for smaller reports.
  - File-based import (recommended for full raid reports) - drop `*-raid.json` / `*-mplus.json` into `Imports/Raid` and `Imports/MPlus`, run `Tools/Import-Reports.ps1`, then `/reload`. See [Imports/README.txt](Imports/README.txt).

## Commands

| Command | Effect |
|---|---|
| `/loot import` | Open the report import window |
| `/loot raid` | Open the raid roll/pass window |
| `/loot mplus` | Open the Mythic+ dungeon ranking window |
| `/loot config` | Open the options panel |
| `/loot help` | List commands |

(`/la` works as a shorthand for `/loot` too.)

## Installation

Copy (or symlink) this folder into `World of Warcraft/_retail_/Interface/AddOns/LootAdvisor`.

## Why file-based import exists

WoW addons can't make HTTP requests or read arbitrary files from disk - the only file the game will load for an addon is its SavedVariables file. `Tools/Import-Reports.ps1` runs outside the game, converts your report JSON to Lua, and writes it into a dedicated SavedVariables global (`LootAdvisorImportsDB`, kept entirely separate from your settings/history) that the addon picks up automatically on next login/reload. This sidesteps pasting large reports into an in-game edit box, which gets slow for full raid-sized reports.

## Structure

```
LootAdvisor/
  Core/        Addon bootstrap, constants, shared helpers
  Data/        SavedVariables access layer (reports, loot history, settings)
  Import/      JSON -> normalized report parsing (works off real Raidbots
               Droptimizer sim data: baseline DPS vs. profileset results)
  Service/     Event handling, slash commands, loot watching, currency advisor
  UI/          AceGUI windows (import, raid, M+, drop banner)
  Options/     AceConfig options panel
  Locales/     AceLocale strings
  ExternalLibs/ Vendored Ace3 libraries
  Imports/     Drop zone for file-based import (raid/mplus JSON)
  Tools/       Import-Reports.ps1 - the file-based import converter
```

Built with [Ace3](https://www.wowace.com/projects/ace3) (AceAddon, AceConsole, AceDB, AceConfig, AceGUI, AceLocale).

## License

Copyright (C) 2026 icouldonlygetthisname

LootAdvisor is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See [LICENSE](LICENSE) for the full text.

The vendored Ace3 libraries in `ExternalLibs/` (including CallbackHandler) keep their own BSD-style license - see [ExternalLibs/Ace3-LICENSE.txt](ExternalLibs/Ace3-LICENSE.txt). LibStub is public domain.
