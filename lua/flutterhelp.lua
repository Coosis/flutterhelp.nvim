local M = {}

function M.setup(opts)
	opts = opts or {}
	vim.api.nvim_create_user_command("StartFlutterDaemon", "lua require('flutterhelp').startDaemon()", {})
	vim.api.nvim_create_user_command("StopFlutterDaemon", "lua require('flutterhelp').stopDaemon()", {})
end

function M.handle_output(err, data)
	if err then
		print("Error", err)
		return
	end
	print(data)
end

function M.startDaemon()
	M.uv = vim.uv
	M.stdin = uv.new_pipe(false)
	M.stdout = uv.new_pipe(false)
	M.stderr = uv.new_pipe(false)
	M.handle, M.pid = M.uv.spawn("flutter", {
		args = {"daemon"},
		stdio = {M.stdin, M.stdout, M.stderr},
	}, function(code, signal)
		print("Daemon exited with code", code, signal)
		M.stdin:close()
		M.stdout:close()
		M.stderr:close()
		M.handle:close()
	end)

	M.uv.read_start(M.stdout, M.handle_output)
	M.uv.read_start(M.stderr, M.handle_output)

end

function M.stopDaemon()
	M.stdin:write("q")
	M.stdin:close()
	M.stdout:close()
	M.stderr:close()
end

function M.runCommand(command)
	local json = vim.json.encode(command)
	M.uv.write(M.stdin, '[' .. json .. ']\n')
end

return M
