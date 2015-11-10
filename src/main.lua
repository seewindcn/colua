
function __G__TRACKBACK__(errorMessage)
	local l = print
    l("----------------------------------------")
    l("LUA ERROR: " .. tostring(errorMessage) .. "\n")
    l(debug.traceback("", 2))
    l("----------------------------------------")
end

package.path = package.path .. ";src/"
cc.FileUtils:getInstance():setPopupNotify(false)
require("app.MyApp").new():run()
