--- Highlights terminal CSI ANSI color codes.
-- @module terminal
local nvim = require 'nvim'

local function array_to_rgb_hex(r,g,b)
	return ("#%02X%02X%02X"):format(r,g,b)
end

local cterm_colors = {
	[0] =
	"#000000", "#AA0000", "#00AA00", "#AA5500", "#0000AA", "#AA00AA", "#00AAAA", "#AAAAAA",
	"#555555", "#FF5555", "#55FF55", "#FFFF55", "#5555FF", "#FF55FF", "#55FFFF", "#FFFFFF"
}

local termguicolors = nvim.o.termguicolors
local function resolve_cterm_rgb(cterm)
	if termguicolors then
		return nvim.g["terminal_color_"..cterm] or cterm_colors[cterm]
	end
	return cterm_colors[cterm]
end

--- Parses a list of codes into an object of cterm/gui attributes
-- @tparam {string|int,...} attrs the list of codes numbers like 0 from ^[[0m
-- @tparam[opt={}] {[string]=string} attributes mutable table to output results into
-- @treturn {[string]=string} a table of cterm*/gui* attributes
local function resolve_attributes(attrs, attributes)
	attributes = attributes or {}
	for _, v in ipairs(attrs) do
		v = tonumber(v)
		--- @todo The color codes implemented is not complete
		if not v then
			-- TODO print warning here? It might be spammy.
			-- nvim.err_writeln("Invalid mode encountered")
		elseif v >= 30 and v <= 37 then
			-- Foreground color
			local ctermfg = v-30
			attributes.ctermfg = ctermfg
			attributes.guifg = resolve_cterm_rgb(ctermfg)
		elseif v >= 40 and v <= 47 then
			-- Background color
			local ctermbg = v-40
			attributes.ctermbg = ctermbg
			attributes.guibg = resolve_cterm_rgb(ctermbg)
		elseif v >= 90 and v <= 97 then
			-- Bright colors. Foreground
			local ctermfg = v-90+8
			attributes.ctermfg = ctermfg
			attributes.guifg = resolve_cterm_rgb(ctermfg)
		elseif v >= 100 and v <= 107 then
			-- Bright colors. Background
			local ctermbg = v-100+8
			attributes.ctermbg = ctermbg
			attributes.guibg = resolve_cterm_rgb(ctermbg)
		elseif v == 22 then
			attributes.cterm = 'NONE'
			attributes.gui = 'NONE'
		elseif v == 39 then
			-- Reset to normal color for foreground
			attributes.ctermfg = 'fg'
			attributes.guifg = 'fg'
		elseif v == 49 then
			-- Reset to normal color for background
			attributes.ctermbg = 'bg'
			attributes.guibg = 'bg'
		elseif v == 1 then
			attributes.cterm = 'bold'
			attributes.gui = 'bold'
		elseif v == 0 then
			-- RESET
			attributes = {}
		end
	end
	return attributes
end

local function format_attributes(attributes)
	local result = {}
	for k, v in pairs(attributes) do
		table.insert(result, k.."="..v)
	end
	return result
end

local function make_highlight_name(attributes)
	local keys = {}
	for k in pairs(attributes) do table.insert(keys, k) end
	table.sort(keys)
	local result = {"tcode"}
	for _, k in ipairs(keys) do
		local value = tostring(attributes[k]):gsub("^#", "")
		table.insert(result, k.."_"..value)
	end
	return table.concat(result, "_")
end

--- Highlight a region in a buffer from the attributes specified
local function highlight_from_attributes(buf, ns, current_attributes,
		 region_line_start, region_byte_start,
		 region_line_end, region_byte_end)
	local highlightName
	-- Ref: https://stackoverflow.com/questions/1252539/most-efficient-way-to-determine-if-a-lua-table-is-empty-contains-no-entries
	if next(current_attributes) == nil then
		highlightName = "Normal"
	else
		highlightName = make_highlight_name(current_attributes)
		if nvim.fn.hlID(highlightName) == 0 then
			nvim.ex.highlight(highlightName, unpack(format_attributes(current_attributes)))
		end
	end
	-- nvim.echo(((vim.inspect{highlightName, {region_line_start, region_byte_start}, {region_line_end, region_byte_end}, current_attributes}):gsub("\n", "")))
	if region_line_start == region_line_end then
		nvim.buf_add_highlight(buf, ns, highlightName, region_line_start, region_byte_start, region_byte_end)
	else
		nvim.buf_add_highlight(buf, ns, highlightName, region_line_start, region_byte_start, -1)
		for linenum = region_line_start + 1, region_line_end - 1 do
			nvim.buf_add_highlight(buf, ns, highlightName, linenum, 0, -1)
		end
		nvim.buf_add_highlight(buf, ns, highlightName, region_line_end, 0, region_byte_end)
	end
end

-- Parse a color code
-- Either an RGB code or an incremental list of other CSI codes.
local function parse_color_code(code, current_attributes)
	if code:match("^[34]8[:;]5[:;]") then
		local kind, sep1, sep2, n = code:match("^([34])8([:;])5([:;])(%d+)$")
		-- TODO do this better
		assert(sep1 == sep2)
		current_attributes[kind == "3" and "ctermfg" or "ctermbg"] = tonumber(n)
	elseif code:match("^[34]8[:;]2[:;]") then
		local kind, sep1, sep2, r, sep3, g, sep4, b = code:match("^([34])8([:;])2([:;])(%d+)([:;])(%d+)([:;])(%d+)$")
		-- TODO do this better
		assert(sep1 == sep2 and sep1 == sep3 and sep1 == sep4)
		-- TODO confirm that r,g,b are in the correct format.
		current_attributes[kind == "3" and "guifg" or "guibg"] = "#"..r..g..b
	else
		local parts = vim.split(code, ";", true)
		current_attributes = resolve_attributes(parts, current_attributes)
	end
	return current_attributes
end

-- Algorithm overview:
-- Maintain an attributes object which contains the currently applicable
-- style to apply based on the incremental definitions from CSI codes.
--
-- 1. Start with a bare attributes object which represents a Normal style.
-- 2. Scan for the next CSI color code.
-- 3. Apply a highlight on the region between the last CSI code and this new
-- one. based on the current attributes.
-- 4. Update the current attributes with those defined by the new CSI code.
-- 5. Repeat from 2
--
-- TODO it's possible to skip processing the new code if the attributes hasn't
-- changed.
--
-- line_start: integer. should be 0-indexed
-- lines: array[string]. the lines to highlight from the buffer.
-- ns: integer. the namespace id. Create it with vim.api.create_namespace
-- buf: integer. buffer id.
local function highlight_buffer(buf, ns, lines, line_start)
	local current_region_start, current_attributes = nil, nil
	for current_linenum, line in ipairs(lines) do
		current_linenum = current_linenum - 1 + line_start
		-- Scan for potential color codes.
		for match_start, code, match_end in line:gmatch("()%[([%d;:]+)m()") do
			-- Highlight any current region.
			if current_region_start then
				highlight_from_attributes(buf, ns, current_attributes,
						current_region_start[1], current_region_start[2],
						current_linenum, match_start)
			end
			current_region_start = {current_linenum, match_start}
			-- Update attributes from the new escape code.
			current_attributes = parse_color_code(code, current_attributes)
		end
	end
	if current_region_start then
		highlight_from_attributes(buf, ns, current_attributes,
				current_region_start[1], current_region_start[2],
				line_start + #lines, -1)
	end
end

-- buf = 0 implies the current buffer.
local function attach_to_buffer(buf)
	local ns = nvim.create_namespace 'terminal_highlight'
	do
		nvim.buf_clear_namespace(buf, ns, 0, -1)
		local lines = nvim.buf_get_lines(buf, 0, -1, true)
		highlight_buffer(buf, ns, lines, 0)
	end
	-- send_buffer: true doesn't actually do anything in Lua (yet)
	nvim.buf_attach(buf, false, {
		on_lines = function(event_type, buf, changed_tick, firstline, lastline, new_lastline)
			-- TODO I don't think there's a way around this. Codes are affected by
			-- everything before and affect things after. You could do more
			-- intelligence analysis by only parsing up until the last affected
			-- values, but that's complicated.
			firstline = 0
			new_lastline = -1
			nvim.buf_clear_namespace(buf, ns, firstline, new_lastline)
			local lines = nvim.buf_get_lines(buf, firstline, new_lastline, true)
			highlight_buffer(buf, ns, lines, firstline)
		end;
	})
end

return {
	highlight_buffer = highlight_buffer;
	attach_to_buffer = attach_to_buffer;
}

--[[ Example]]
--[=[
local buf = 1
local ns = nvim.create_namespace("terminal_highlight")
nvim.buf_clear_namespace(buf, ns, 0, -1)
local lines = nvim.buf_get_lines(buf, 1, -1, false)
require'terminal'.highlight_buffer(buf, ns, lines, 0)
--]=]
