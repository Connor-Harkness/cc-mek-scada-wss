require("/initenv").init_env()

local util = require("scada-common.util")

local println = util.println
local print_ts = util.println_ts

println("WebSocket Module Validation Test")
println("================================")
println("")

-- Test 1: Module loads
print_ts("Test 1: Loading websocket module...")
local websocket
local success, err = pcall(function()
    websocket = require("scada-common.websocket")
end)

if success then
    println("✓ Module loaded successfully")
else
    println("✗ Failed to load module: " .. tostring(err))
    return
end

-- Test 2: Module structure
print_ts("Test 2: Checking module structure...")
local required_functions = {
    "init",
    "connect",
    "disconnect",
    "send",
    "send_facility_status",
    "send_unit_status",
    "send_all_units_status",
    "send_display_state",
    "update",
    "is_connected",
    "is_enabled"
}

local all_found = true
for _, func_name in ipairs(required_functions) do
    if type(websocket[func_name]) ~= "function" then
        println("✗ Missing function: " .. func_name)
        all_found = false
    end
end

if all_found then
    println("✓ All required functions present")
else
    return
end

-- Test 3: Initialize with disabled WebSocket
print_ts("Test 3: Initialize WebSocket (disabled)...")
success, err = pcall(function()
    websocket.init("ws://test.example.com:8080", false)
end)

if success then
    println("✓ WebSocket initialized (disabled)")
    if not websocket.is_enabled() then
        println("✓ WebSocket correctly reports as disabled")
    else
        println("✗ WebSocket incorrectly reports as enabled")
    end
else
    println("✗ Failed to initialize: " .. tostring(err))
    return
end

-- Test 4: Initialize with enabled WebSocket (won't actually connect without server)
print_ts("Test 4: Initialize WebSocket (enabled)...")
success, err = pcall(function()
    websocket.init("ws://test.example.com:8080", true)
end)

if success then
    println("✓ WebSocket initialized (enabled)")
    if websocket.is_enabled() then
        println("✓ WebSocket correctly reports as enabled")
    else
        println("✗ WebSocket incorrectly reports as disabled")
    end
else
    println("✗ Failed to initialize: " .. tostring(err))
    return
end

-- Test 5: Test send methods (should handle no connection gracefully)
print_ts("Test 5: Testing send methods without connection...")
success, err = pcall(function()
    websocket.send_facility_status({test = "data"})
    websocket.send_unit_status(1, {test = "data"})
    websocket.send_all_units_status({{test = "data"}})
    websocket.send_display_state("main", {test = "data"})
end)

if success then
    println("✓ Send methods handle no connection gracefully")
else
    println("✗ Send methods failed: " .. tostring(err))
    return
end

-- Test 6: Test update method
print_ts("Test 6: Testing update method...")
success, err = pcall(function()
    websocket.update()
end)

if success then
    println("✓ Update method works")
else
    println("✗ Update method failed: " .. tostring(err))
    return
end

println("")
println("================================")
println("All tests passed! ✓")
println("")
println("Note: Actual WebSocket connectivity requires:")
println("  1. HTTP enabled in ComputerCraft config")
println("  2. A running WebSocket server")
println("  3. Network connectivity to the server")
