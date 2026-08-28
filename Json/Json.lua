-----------------------------------------------------------------------
-- Minimal pure-Lua JSON decoder.
--
-- Loads before Core\Core.xml (see LootAdvisor.toc), so the private.NewLib
-- module registry doesn't exist yet - this file attaches itself directly
-- to the shared addon table as `private.Json` instead. Every other file
-- consumes it as: local Json = private.Json
--
-- Only decoding is implemented - LootAdvisor never needs to produce JSON,
-- only read Raidbots report JSON pasted in by the user.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local Json = {}
private.Json = Json

local sByte, sSub, sFind, sChar = string.byte, string.sub, string.find, string.char
local tInsert = table.insert

local function skipWhitespace(str, pos)
	local _, stop = sFind(str, "^[ \t\r\n]*", pos)
	return (stop or pos - 1) + 1
end

local decodeValue -- forward declaration

local escapeMap = {
	['"'] = '"', ["\\"] = "\\", ["/"] = "/",
	b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
}

-- Note: this scans by jumping to the next '"' or '\' via string.find (a
-- single C-level scan) rather than testing one character at a time in Lua -
-- for a large report JSON, a naive per-character loop is slow enough to
-- visibly hang the client, since most string runs (item names, etc.) contain
-- no escapes at all and can be sliced out in one shot.
local function decodeString(str, pos)
	-- pos points at the opening quote
	local out = {}
	local i = pos + 1
	local len = #str
	while true do
		local specialPos = sFind(str, '["\\]', i)
		if not specialPos then
			return nil, len + 1, "unterminated string"
		end
		if specialPos > i then
			tInsert(out, sSub(str, i, specialPos - 1))
		end

		local c = sSub(str, specialPos, specialPos)
		if c == '"' then
			return table.concat(out), specialPos + 1
		end

		-- c == "\\"
		local nextC = sSub(str, specialPos + 1, specialPos + 1)
		if nextC == "u" then
			local hex = sSub(str, specialPos + 2, specialPos + 5)
			local code = tonumber(hex, 16)
			if not code then
				return nil, specialPos, "invalid \\u escape"
			end
			if code < 0x80 then
				tInsert(out, sChar(code))
			elseif code < 0x800 then
				tInsert(out, sChar(0xC0 + math.floor(code / 0x40), 0x80 + (code % 0x40)))
			else
				tInsert(out, sChar(
					0xE0 + math.floor(code / 0x1000),
					0x80 + (math.floor(code / 0x40) % 0x40),
					0x80 + (code % 0x40)
				))
			end
			i = specialPos + 6
		else
			local mapped = escapeMap[nextC]
			if not mapped then
				return nil, specialPos, "invalid escape \\" .. tostring(nextC)
			end
			tInsert(out, mapped)
			i = specialPos + 2
		end
	end
end

local function decodeNumber(str, pos)
	local _, stop, numStr = sFind(str, "^(-?%d+%.?%d*[eE]?[%+%-]?%d*)", pos)
	if not numStr then
		return nil, pos, "invalid number"
	end
	local num = tonumber(numStr)
	if not num then
		return nil, pos, "invalid number"
	end
	return num, stop + 1
end

local function decodeArray(str, pos)
	local arr = {}
	local i = skipWhitespace(str, pos + 1)
	if sSub(str, i, i) == "]" then
		return arr, i + 1
	end
	local n = 0
	while true do
		local value, nextPos, err = decodeValue(str, i)
		if err then
			return nil, nextPos, err
		end
		n = n + 1
		arr[n] = value
		i = skipWhitespace(str, nextPos)
		local c = sSub(str, i, i)
		if c == "," then
			i = skipWhitespace(str, i + 1)
		elseif c == "]" then
			return arr, i + 1
		else
			return nil, i, "expected ',' or ']' in array"
		end
	end
end

local function decodeObject(str, pos)
	local obj = {}
	local i = skipWhitespace(str, pos + 1)
	if sSub(str, i, i) == "}" then
		return obj, i + 1
	end
	while true do
		if sSub(str, i, i) ~= '"' then
			return nil, i, "expected string key in object"
		end
		local key, afterKey, err = decodeString(str, i)
		if err then
			return nil, afterKey, err
		end
		i = skipWhitespace(str, afterKey)
		if sSub(str, i, i) ~= ":" then
			return nil, i, "expected ':' after object key"
		end
		i = skipWhitespace(str, i + 1)
		local value, nextPos
		value, nextPos, err = decodeValue(str, i)
		if err then
			return nil, nextPos, err
		end
		obj[key] = value
		i = skipWhitespace(str, nextPos)
		local c = sSub(str, i, i)
		if c == "," then
			i = skipWhitespace(str, i + 1)
		elseif c == "}" then
			return obj, i + 1
		else
			return nil, i, "expected ',' or '}' in object"
		end
	end
end

decodeValue = function(str, pos)
	pos = skipWhitespace(str, pos)
	local c = sSub(str, pos, pos)
	if c == '"' then
		return decodeString(str, pos)
	elseif c == "{" then
		return decodeObject(str, pos)
	elseif c == "[" then
		return decodeArray(str, pos)
	elseif c == "t" and sSub(str, pos, pos + 3) == "true" then
		return true, pos + 4
	elseif c == "f" and sSub(str, pos, pos + 4) == "false" then
		return false, pos + 5
	elseif c == "n" and sSub(str, pos, pos + 3) == "null" then
		-- JSON null decodes to Lua nil. Since assigning nil into a table key
		-- is a no-op, a "null" field simply won't appear in the decoded
		-- table - equivalent to it being absent, which is fine for our use.
		return nil, pos + 4
	elseif c == "-" or (sByte(c) and sByte(c) >= 48 and sByte(c) <= 57) then
		return decodeNumber(str, pos)
	else
		return nil, pos, "unexpected character '" .. tostring(c) .. "'"
	end
end

-- Json.decode(str) -> table|string|number|boolean|nil, errorMessage
-- On success returns the decoded value and nil. On failure returns nil and an
-- error message describing roughly where decoding failed.
function Json.decode(str)
	if type(str) ~= "string" or str == "" then
		return nil, "empty input"
	end
	local value, pos, err = decodeValue(str, 1)
	if err then
		local line = 1
		for _ in sSub(str, 1, pos):gmatch("\n") do
			line = line + 1
		end
		return nil, string.format("%s (near line %d)", err, line)
	end
	return value, nil
end

return Json
