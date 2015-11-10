--idle.lua

---[[
-- Uncomment to attempt to use lsleep
-- https://github.com/andrewstarks/lsleep
--see local success, lsleep = pcall(require, 'lsleep')
--]]

local function unix_idle  (t)
	local ret = os.execute('sleep '..t) 
	if _VERSION =='Lua 5.1' and ret ~= 0
	or _VERSION ~='Lua 5.1' and ret ~= true then
		os.exit() 
	end
end

local function windows_idle  (t)
	os.execute( ('ping 1.1.1.1 -n 1 -w %d > nul'):format(t * 1000) )
end

-- We have default functions for Windows and Linux
-- You can replace with your own function. If none useful is available, you can use an empty
-- function (i.e. "function() end"), which will result in busy wating.
-- Notice that the selector-* libs replace the idle function with a socket based sleep.
return os.getenv('OS') and os.getenv('OS'):match("^Windows-.") and windows_idle or unix_idle
