--look for packages one folder up.
-- package.path = package.path .. ";;;./?/init.lua"


local lumen = require "lumen"
local sched = require "lumen.sched"

DEFAULT_INTEVAL = 0.02  -- 1/40 = 0.025  1/50=0.02  1/60 = 0.017
local _NULL = {}

local log = function(fmt, ...)
	print(string.format(fmt, ...))
end


local log_hex = function(prefix, data, start, endi)
	local rs = ''
	start = start or 1
	endi = endi or data:len()
	for i = start, endi do
		rs = rs..string.format("%02x", tonumber(string.byte(data, i, i)))
	end
	print(prefix..rs)
end

function set_log(f)
	log = f
end

function iter_int(index, max)
	max = max or 65535
	if index < 65535 then
		return index + 1, index
	end
	return 1, index
end

sleep = sched.sleep
function step()
	sched.step()
end

function loop()
	sched.loop()
end

CoTask = {}
CoTask.__index = CoTask

function CoTask:new(f)
	local task = setmetatable({_t=sched.run(f),}, CoTask)
	return task
end

function CoTask:current()
	return coroutine.running()
end

function CoTask:join()
	if self._t.status~='dead' then
		sched.wait({self._t.EVENT_FINISH})
	end
end

function CoTask:kill()
	self._t:kill()
end

CoEvent = {}
CoEvent.__index = CoEvent
local _ev_index = 0

function CoEvent:new()
	_ev_index = iter_int(_ev_index)
	local e = {_ev={'_event_' .. _ev_index, }, value=_NULL,}
	setmetatable(e, CoEvent)
	-- self.__index = self
	return e
end

function CoEvent:_signal()
	sched.signal(self._ev[1])
end

function CoEvent:set(value)
	self.value = value
	self:_signal()
end

function CoEvent:get()
	if self.value == _NULL then
		sched.wait(self._ev)
	end
	if self.value == _NULL then return nil end  -- may be clear()
	return self.value
end

function CoEvent:clear()
	self.value = _NULL
	self:_signal()
end


function run(f)
	task = CoTask:new(f)
	return task
end


--[[socket]]
local selector = nil
local function _init_selector()
	if selector == nil then
		selector = require "lumen.tasks.selector":init({service="luasocket"})
	end
end

function new_tcp_client(address, port, timeout, handler)
	_init_selector()
	if handler == nil then handler = 'stream' end
	local tcp, status = selector.new_tcp_client(address, port, nil, nil, nil, handler, timeout)
	if status == nil then return tcp end
	log('*************tcp client error:%s', status)
	return nil
end

--[[socket end]]
local _inited = false

function init_console()
	if _inited then return end
	_inited = true
	log('--------console_init--------')
end

local _sched_task = nil
function init_cc(inteval)
	if _inited then return end
	_inited = true
	if _sched_task ~= nil then return end
	log('--------colua.init_cc------')
	local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
	if inteval == nil then inteval = DEFAULT_INTEVAL end
	_sched_task = scheduler.scheduleGlobal(step, inteval, false)
end


--[[test]]
CoTest = {}

function CoTest:cc_test()
	init_cc()
	require("framework.init")
	require("framework.shortcodes")
	require("framework.cc.init")
	run(function ()
		local _text = nil
		local display_text = function (title)
			if title == nil then 
				return 
			end
			if _text ~= nil then _text:hide() end
			log('*****:%s', title)
			_text = cc.ui.UILabel.new({text = "-- " .. title .. " --", size = 24, color = display.COLOR_BLACK})
				:align(display.CENTER, display.cx, display.top - 40)
				:addTo(display.getRunningScene())
		end
		CoTest:socket_test(display_text)
	end)
end

function CoTest:console_test()
	init_console()
	run(function ()
		CoTest:event_test()
		CoTest:socket_test()
	end)
	loop()
end

function CoTest:event_test()
	local e1 = CoEvent:new()
	local e2 = CoEvent:new()
	local t1 = run(function ()
		e2:set('task1')
		log('task1 wait event')
		local v = e1:get()
		log('task1 get:%s', v)
		sleep(1)
		log('task1 end')
	end)
	local t2 = run(function ()
		sleep(1)
		log('task2 set event')
		e1:set('task2')
		v = e2:get()
		log('task2 get:%s', v)
		log('task2 end')
	end)
	t1:join()
	t2:join()
end

function CoTest:socket_test(display)
	if display == nil then 
		display = function ( ... ) log(...) end 
	end
	local t = run(function ( )
		log('begin socket_test')
		client = new_tcp_client('www.163.com', 80)
		client:send('http 1.0\n\n\n')
		while true do
			d = client.stream:read_line()
			display(d)
			sleep(0.5)
			if d == nil then break end
		end
	end)
	t:join()
end


--[[test]]


-- CoTest:console_test()


