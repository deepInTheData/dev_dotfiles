local dap = require("dap")
local dapui = require ("dapui")
-- local dap_utils = require("dap-utils")
-- dap_utils.setup()
-- dap.set_log_level('TRACE')


-- -- Ruby
local function check_ruby_dap()
    local handle = io.popen("gem list ruby-lsp -i 2>&1")
    local result = handle:read("*a")
    if not handle then
        vim.api.nvim_err_writeln("Failed to check ruby-lsp gem.")
        return false
    end    
    handle:close()
    if result:match("false") then
        vim.api.nvim_echo({{"Warning: ruby-lsp gem is not installed. Please install it using 'gem install ruby-lsp'.", "WarningMsg"}}, true, {})
    end
    require('dap-ruby').setup()
    return true
end


-- Python
local function check_python_dap()
    local venv_path = os.getenv('VIRTUAL_ENV')
    local default_python_path = "/opt/homebrew/bin/python3"
    local python_path = venv_path and venv_path .. '/bin/python' or default_python_path

    -- local handle = io.popen(python_path .. " -m debugpy --version 2>&1")
    -- if not handle then
    --     vim.api.nvim_err_writeln("Failed to check debugpy installation.")
    --     return false
    -- end    
    -- local result = handle:read("*a")
    -- handle:close()
    -- if result:match("No module named debugpy") then
    --   vim.api.nvim_echo({{"Warning: debugpy is not installed. Install it using 'pip install debugpy' to debug.", "WarningMsg"}}, true, {})
    --   return false
    -- end

    -- local handle2 = io.popen("jedi-language-server --version 2>&1")
    -- if not handle2 then        
    --     vim.api.nvim_err_writeln("Failed to check jedi-language-server installation.")
    --     return false
    -- end    
    -- local result2 = handle2:read("*a")
    -- handle2:close()
    -- if result2:match("command not found") then
    --     vim.api.nvim_echo({{"Warning: jedi-language-server is not installed. Install it using 'pip install jedi-language-server'.", "WarningMsg"}}, true, {})
    -- end

    require('dap-python').setup(python_path)
    require('dap-python').test_runner = 'pytest'
    dap.configurations.python = {
        {
          -- The first three options are required by nvim-dap
          type = 'python'; -- the type here established the link to the adapter definition: `dap.adapters.python`
          request = 'launch';
          name = "Launch file";
          console = "internalConsole";
          -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
      
          program = "${file}"; -- This configuration will launch the current file if used.
          pythonPath = function()
            -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
            -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
            -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
            local cwd = vim.fn.getcwd()
            if vim.fn.executable(python_path) == 1 then
              return python_path
            else
              return default_python_path
            end
          end;
        },
    }
    return true
end

-- Check python and ruby deps on runtime - slows down load speed if we do it for every file type
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python", "ruby" }, -- , "javascript", "typescript", "c", "cpp", "java"
    callback = function()
        local file_type = vim.bo.filetype
        if file_type == "python" then
            local success = check_python_dap()
            if not success then
                vim.api.nvim_echo({{"Failed to setup Python DAP", "WarningMsg"}}, true, {})
                return
            end
        elseif file_type == "ruby" then
            local success = check_ruby_dap()
            if not success then
                vim.api.nvim_echo("Failed to setup Ruby DAP configuration.")
                return
            end
        end

        return
    end
})


-- C / C++
-- $(brew --prefix llvm)/bin
-- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#ccrust-via-lldb-vscode
-- Install via brew install lldb
dap.adapters.lldb = {
    type = 'executable',
    command = '/opt/homebrew/opt/llvm/bin/lldb-dap', 
    name = 'lldb'
}

-- TODO: Setup GDB debugger
-- Example cross platform remote debugging if needed.
-- brew install arm-none-eabi-gdb aarch64-elf-gdb
dap.adapters.gdb = {
    id = 'gdb',
    type = 'executable',
    command = 'gdb',
    args = { '--quiet', '--interpreter=dap' },
}
-- From https://blog.cryptomilk.org/2024/01/02/neovim-dap-and-gdb-14-1/
dap.configurations.gdb = {
    {
        name = 'Run executable (GDB)',
        type = 'gdb',
        request = 'launch',
        program = function()
            local path = vim.fn.input({
                prompt = 'Path to executable: ',
                default = vim.fn.getcwd() .. '/',
                completion = 'file',
            })
            return (path and path ~= '') and path or dap.ABORT
        end,
    },
    {
        name = 'Run executable with arguments (GDB)',
        type = 'gdb',
        request = 'launch',
        program = function()
            local path = vim.fn.input({
                prompt = 'Path to executable: ',
                default = vim.fn.getcwd() .. '/',
                completion = 'file',
            })

            return (path and path ~= '') and path or dap.ABORT
        end,
        args = function()
            local args_str = vim.fn.input({
                prompt = 'Arguments: ',
            })
            return vim.split(args_str, ' +')
        end,
    },
    {
        name = 'Attach to process (GDB)',
        type = 'gdb',
        request = 'attach',
        processId = function()
            return tonumber(vim.fn.input("Enter GDB process ID: "))
        end
    },
}

dap.configurations.cpp = {
    {
        name = "Launch file",
        type = "lldb",
        request = "launch",
        program = function()
            -- require('dap.utils').pick_file
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file') 
        end,
        cwd = '${workspaceFolder}',
        console = "integratedTerminal",
        stopOnEntry = true,
        args = {},
    },
    -- {
    --     -- untested here
    --     name = 'Attach to gdbserver :1234',
    --     type = 'lldb',
    --     request = 'launch',
    --     MIMode = 'gdb',
    --     miDebuggerServerAddress = 'localhost:1234',
    --     miDebuggerPath = '/usr/bin/gdb',
    --     cwd = '${workspaceFolder}',
    --     console = "integratedTerminal",
    --     program = function()
    --     return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    --     end,
    -- },
}
-- For other languages such as C, you can use the same configuration
dap.configurations.c = dap.configurations.cpp


-- Javascript
-- Good walkthrough: https://miguelcrespo.co/posts/debugging-javascript-applications-with-neovim/
--
-- Should be installed with mxsdev/nvim-dap-vscode-js otherwise, install manually via:
-- git clone https://github.com/microsoft/vscode-js-debug ~/debugtools/vscode-js-debug --depth=1
local dap_vscode_js = require("dap-vscode-js")
dap_vscode_js.setup({
    node_path = "node",
    debugger_path = os.getenv("HOME") .. "/.local/share/nvim/lazy/vscode-js-debug",
    adapters = { 
        "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost", 
        "node", "chrome" -- vscode uses this. useful if porting over.
    }, 
})
  
local exts = {
    "javascript",
    "typescript",
    "javascriptreact",
    "typescriptreact",
    -- using pwa-chrome
    -- "vue",
    -- "svelte",
}

for i, ext in ipairs(exts) do
    dap.configurations[ext] = {
        -- Debug single node.js files
        {
            type = "pwa-node",
            request = "launch",
            name = "Launch Current File (pwa-node)",
            cwd = vim.fn.getcwd(),
            args = { "${file}" },
            sourceMaps = true,
            protocol = "inspector",
        },
        -- Debug node processes like ExpressJS applications
        {
            type = "pwa-node",
            request = "attach",
            name = "Attach Program (pwa-node, select pid)",
            cwd = vim.fn.getcwd(),
            -- processId = require('dap.utils').pick_process,
            processId = function() 
                local handle = io.popen("ps a | grep 'node' | grep -v 'grep' | awk '{print $1 \" - \" $5, $6, $7, $8}' 2>&1")
                local result = handle:read("*a")        
                vim.api.nvim_echo({{result, "WarningMsg"}}, true, {})
                return tonumber(vim.fn.input("Enter process ID: "))
            end,
            skipFiles = { "<node_internals>/**" },        
        },        
        -- Single node.js Typescript files
        {
            type = "pwa-node",
            request = "launch",
            name = "Launch Current File (pwa-node w ts-node)",
            cwd = vim.fn.getcwd(),
            -- runtimeArgs = { "--loader", "ts-node/commonJS" },
            runtimeArgs = { "--loader", "ts-node/esm" }, 
            runtimeExecutable = "node",
            args = { "${file}" },
            sourceMaps = true,
            protocol = "inspector",
            skipFiles = { "<node_internals>/**", "node_modules/**" },
            resolveSourceMapLocations = {
                "${workspaceFolder}/**",
                "!**/node_modules/**",
            },
        },
        -- JEST
        {
            type = "pwa-node",
            request = "launch",
            name = "Launch Test Current File (pwa-node with jest)",
            -- cwd = "${workspaceFolder}",
            -- runtimeArgs = { "${workspaceFolder}/node_modules/.bin/jest" },
            cwd = vim.fn.getcwd(),
            runtimeArgs = {
                "./node_modules/jest/bin/jest.js",
                "--runInBand",
            },        
            runtimeExecutable = "node",
            args = { "${file}", "--coverage", "false" },
            rootPath = "${workspaceFolder}",
            sourceMaps = true,
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
            skipFiles = { "<node_internals>/**", "node_modules/**" },
        },    
        -- MOCHA
        {
            type = "pwa-node",
            request = "launch",
            name = "Debug Mocha Tests",
            -- trace = true, -- include debugger info
            runtimeExecutable = "node",
            runtimeArgs = {
                "./node_modules/mocha/bin/mocha.js",
            },
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
        },
        -- Chrome
        {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome",
            -- url = "http://localhost:3000",
            url = function()
                local host = "http://localhost:"
                local port = vim.fn.input("Select port:",  3000)
                return host .. port
            end,            
            webRoot = "${workspaceFolder}",
            -- userDataDir: where to save chrome profile 
            userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir"
        },        
        -- {
        --     type = "pwa-chrome",
        --     request = "attach",
        --     name = "Attach Chrome",
        --     program = "${file}",
        --     cwd = vim.fn.getcwd(),
        --     sourceMaps = true,
        --     port = function()
        --         return vim.fn.input("Select port: ", 9222)
        --     end,
        --     webRoot = "${workspaceFolder}",
        -- },
    }
end

dapui.setup({
    icons = {},
}) -- use default

dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
end
    dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
end
    dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
end
require("nvim-dap-virtual-text").setup({
    commented = true
})
