local M = {
	log_dir = "",
	appId = "",
	id = 0,
	pid = 0,

	-- last ids of requests
	lastRestartId = 0,
	lastStopId = 0,
	lastReloadId = 0,
}

local default_log_dir = vim.fn.stdpath("data") .. "/flutterhelp/"
local logfile = "fhelp.log"
local function log(message, std)
	std = std or false
	if std then
		print(message)
	end
	os.execute("mkdir -p " .. M.log_dir)
    -- open log in append mode
    local log_file = io.open(M.log_dir .. logfile, "a")
    if log_file then
        -- time prefix
        local log_time = os.date("%Y-%m-%d %H:%M:%S")
        -- write with a newline
        log_file:write("[" .. log_time .. "]" .. message .. "\n")
		-- close the file
        log_file:close()
    else
        print("Error: Could not open log file!")
		print("Log file path: " .. M.log_dir)
    end
end

local function get_log_dir()
	local logdir = vim.fn.getenv("FLUTTERHELP_LOG_DIR")
	if logdir == nil or logdir == "" or logdir == vim.NIL then
		logdir = default_log_dir
		vim.fn.setenv("FLUTTERHELP_LOG_DIR", logdir)
	end
	return tostring(logdir)
end

function M.setup(opts)
	M.id = 0
	opts = opts or {}
	M.log_dir = opts.log_dir or get_log_dir()
	vim.api.nvim_create_user_command("FlutterInspect", "lua require('flutterhelp').inspect()", {})
	vim.api.nvim_create_user_command("FlutterRunApp", "lua require('flutterhelp').runApp()", {})
	vim.api.nvim_create_user_command("FlutterStopApp", "lua require('flutterhelp').stopApp()", {})
	vim.api.nvim_create_user_command("FlutterRestartApp", "lua require('flutterhelp').restartApp()", {})
	vim.api.nvim_create_user_command("FlutterReload", "lua require('flutterhelp').reload()", {})
	vim.api.nvim_create_user_command("FlutterHelpPurge", "lua require('flutterhelp').purge()", {})
end

function M.purge()
	vim.fn.delete(M.log_dir, "rf")
end

function M.inspect()
	log("inspecting:")
	log("log_dir:" .. M.log_dir, true)
	log("appId:" .. M.appId, true)
	log("id:" .. M.id, true)
	log("pid:" .. M.pid, true)
end

function M.handle_response(output)
	if output.id ~= nil then
		if output.id == M.lastRestartId then
			log("Restarted app: " .. output.result.appId, true)
			M.appId = output.result.appId
		else if output.id == M.lastStopId then
			log("Stopped app: " .. output.result.appId, true)
			M.appId = ""
		else if output.id == M.lastReloadId then
			log("Reloaded app: " .. output.result.appId, true)
			M.appId = output.result.appId
		end end end
	end
end

function M.handle_output(err, data)
	if err then
		log(err, true)
		return
	end

	local status, output = pcall(vim.json.decode, data)
	-- pure text
	if not status then
		log(data)
		return
	end

	if output[1] == nil then
		log("Output is nil")
		return
	end
	output = output[1]

	-- check if output is a response
	if output.event == nil then
		M.handle_response(output)
		return
	end

	-- handle events
	log("event:" .. output.event)
	if output.event == "app.start" then
		M.appId = output.params.appId
		log("App started: " .. output.params.appId, true)
		return
	end
end

function M.runApp()
	M.uv = vim.uv
	M.stdin = M.uv.new_pipe(false)
	M.stdout = M.uv.new_pipe(false)
	M.stderr = M.uv.new_pipe(false)
	M.handle, M.pid = M.uv.spawn("flutter", {
		args = {"run", "--machine"},
		stdio = {M.stdin, M.stdout, M.stderr},
	}, function(code, signal)
		print("Exited with code", code, signal)
		M.stdin:close()
		M.stdout:close()
		M.stderr:close()
		M.handle:close()
	end)

	M.uv.read_start(M.stdout, M.handle_output)
	M.uv.read_start(M.stderr, M.handle_output)

end

-- commands
function M.runCommand(command)
	local json = vim.json.encode(command)
	M.uv.write(M.stdin, '[' .. json .. ']\n')
end

function M.sendMethod(method, params)
	M.id = M.id + 1
	if method == "app.restart" then
		M.lastRestartId = M.id
	else if method == "app.stop" then
		M.lastStopId = M.id
	else if method == "app.reload" then
		M.lastReloadId = M.id
	end end end
	local command = {
		id = M.id,
		method = method,
		params = params
	}
	M.runCommand(command)
end

function M.restartApp(opts)
	local appId = M.appId
	assert(appId ~= "", "appId is required!")
	assert(appId ~= nil, "appId is required!")

	local fullRestart = opts.fullRestart or true
	local reason = opts.reason or "manual"
	local pause = opts.pause or false
	local debounce = opts.debounce or false

	M.sendMethod("app.restart", {
		appId = appId,
		fullRestart = fullRestart,
		reason = reason,
		pause = pause,
		debounce = debounce
	})
end

function M.stopApp()
	local appId = M.appId
	assert(appId ~= "", "appId is required!")
	assert(appId ~= nil, "appId is required!")

	M.sendMethod("app.stop", {
		appId = appId
	})
end

-- calls restart with fullRestart = false
function M.reload()
	M.appRestart({
		fullRestart = false,
		reason = "hot-reload"
	})
end

return M
