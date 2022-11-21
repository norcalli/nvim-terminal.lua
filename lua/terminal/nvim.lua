-- Equivalent to `echo vim.inspect(...)`
local function nvim_print(...)
	if select("#", ...) == 1 then
		vim.api.nvim_out_write(vim.inspect((...)))
	else
		vim.api.nvim_out_write(vim.inspect {...})
	end
	vim.api.nvim_out_write("\n")
end

--- Equivalent to `echo` EX command
local function nvim_echo(...)
	for i = 1, select("#", ...) do
		local part = select(i, ...)
		vim.api.nvim_out_write(tostring(part))
		-- vim.api.nvim_out_write("\n")
		vim.api.nvim_out_write(" ")
	end
	vim.api.nvim_out_write("\n")
end

-- `nvim.$method(...)` redirects to `nvim.api.nvim_$method(...)`
-- TODO `nvim.ex.$command(...)` is approximately `:$command {...}.join(" ")`
-- `nvim.print(...)` is approximately `echo vim.inspect(...)`
-- `nvim.echo(...)` is approximately `echo table.concat({...}, '\n')`
-- Both methods cache the inital lookup in the metatable, but there is a small overhead regardless.
return setmetatable({
	print = nvim_print;
	echo = nvim_echo;
	ex = setmetatable({}, {
		__index = function(self, k)
			local mt = getmetatable(self)
			local x = mt[k]
			if x ~= nil then
				return x
			end
			local command = k:gsub("_$", "!")
			local f = function(...)
				return vim.api.nvim_command(table.concat(vim.tbl_flatten {command, ...}, " "))
			end
			mt[k] = f
			return f
		end
	});
}, {
	__index = function(self, k)
		local mt = getmetatable(self)
		local x = mt[k]
		if x ~= nil then
			return x
		end
		local f = vim.api['nvim_'..k]
		mt[k] = f
		return f
	end
})

