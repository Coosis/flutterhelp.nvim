local M = {}

local function write_log(message)
    -- Open the file in append mode ('a' stands for append)
    local log_file = io.open("/Users/vlad/Documents/lua/flutterhelp/log", "a")
    if log_file then
        -- Get the current time to prefix the log entry
        local log_time = os.date("%Y-%m-%d %H:%M:%S")
        -- Write the log message with a newline at the end
        log_file:write("[" .. log_time .. "] " .. message .. "\n")
        -- Close the file
        log_file:close()
    else
        -- Print error message if the file could not be opened
        print("Error: Could not open log file!")
    end
end

function M.setup(opts)
	opts = opts or {}
	M.id = 0
	vim.api.nvim_create_user_command("FlutterRunApp", "lua require('flutterhelp').runApp()", {})
	vim.api.nvim_create_user_command("FlutterStopApp", "lua require('flutterhelp').stopApp()", {})
	vim.api.nvim_create_user_command("FlutterReload", "lua require('flutterhelp').reload()", {})
end

function M.handle_output(err, data)
	if err then
		print("Error", err)
		return
	end
	write_log(data)
	local output = vim.json.decode(data)
	if output.event == nil then
		print("Output", output)
		return
	end

	if output.event == "app.start" then
		M.appId = output.params.appId
		print("App started", output.params.appId)
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

function M.stopApp()
	M.stdin:write("q")
	M.stdin:close()
	M.stdout:close()
	M.stderr:close()
end

-- commands
function M.runCommand(command)
	local json = vim.json.encode(command)
	M.uv.write(M.stdin, '[' .. json .. ']\n')
end

function M.appRestart(opts)
	M.id = M.id + 1
	local appId = M.appId
	assert(appId ~= "", "appId is required!")
	assert(appId ~= nil, "appId is required!")

	local fullRestart = opts.fullRestart or true
	local reason = opts.reason or "manual"
	local pause = opts.pause or false
	local debounce = opts.debounce or false

	local command = {
		id = M.id,
		method = "app.restart",
		params = {
			appId = appId,
			fullRestart = fullRestart,
			reason = reason,
			pause = pause,
			debounce = debounce
		}
	}
	M.runCommand(command)
end

function M.reload()
	M.appRestart({
		fullRestart = false,
		reason = "hot-reload"
	})
end

return M
