# flutterhelp.nvim
A neovim plugin to help with basic flutter development. For advanced usages, see [flutter-tools](https://github.com/nvim-flutter/flutter-tools.nvim).

# Configuration
```lua
require('flutterhelp').setup({
    -- [optional]
    -- path to store the log file, log will be in log_dir/fhelp.log
    -- you can also set environment variable FLUTTERHELP_LOG_DIR,
    -- in which case log will be in $FLUTTERHELP_LOG_DIR/fhelp.log
    -- defaults to vim.fn.stdpath('data') .. "/flutterhelp/"
    log_dir = "/path/to/log/dir/",

    -- [optional]
    -- pattern to match when writing to file for triggering flutter reload
    -- defaults to "*.dart"
    pattern = {
        "*.dart",
        "*.yaml",
    }

    -- [optional]
    -- set to true to detect all file writes
    -- defaults to false
    detectAll = false
})
```

# Usage
- Enter your project directory and run `:FlutterRunApp`. This could take a while. Wait patiently until the 'App started' message and make sure app is already running to proceed.
- Run `:FlutterReload` to reload the app after making changes to the code. Notice by default this is run everytime a file with the pattern is written to.
- Run `:FlutterRestartApp` to restart the app.
- Run `:FlutterStopApp` to stop the app.
- Run `:FlutterHelpPurge` to purge the log.
- Run `:FlutterInspect` to inspect plugins' internal variables.

# Trouble Shooting
## Stuck at "App starting..."
Try manually closing the devices' app and run `:FlutterRunApp` again.
You can also check the log for more details(`$ echo $FLUTTERHELP_LOG_DIR`).

# TODO
- [ ] Listing devices and choose which one to run
