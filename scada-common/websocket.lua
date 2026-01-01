--
-- WebSocket Client for ComputerCraft
--

local log = require("scada-common.log")
local util = require("scada-common.util")

---@class websocket_client
local websocket = {}

-- WebSocket connection state
local ws_connection = {
    enabled = false,
    connected = false,
    url = "",
    handle = nil,
    reconnect_timer = nil,
    reconnect_interval = 5.0,  -- seconds
    last_send_time = 0,
    send_queue = {}
}

-- initialize WebSocket system
---@param ws_url string WebSocket server URL
---@param enabled boolean whether WebSocket forwarding is enabled
function websocket.init(ws_url, enabled)
    ws_connection.enabled = enabled
    ws_connection.url = ws_url
    
    if enabled then
        log.info("WS: WebSocket client initialized for " .. ws_url)
    else
        log.info("WS: WebSocket client disabled")
    end
end

-- attempt to connect to WebSocket server
---@return boolean success true if connection established
function websocket.connect()
    if not ws_connection.enabled then
        return false
    end
    
    if ws_connection.connected then
        return true
    end
    
    -- attempt HTTP WebSocket connection
    local success, handle = pcall(function()
        return http.websocket(ws_connection.url)
    end)
    
    if success and handle then
        ws_connection.handle = handle
        ws_connection.connected = true
        log.info("WS: Connected to WebSocket server at " .. ws_connection.url)
        return true
    else
        ws_connection.connected = false
        log.warning("WS: Failed to connect to WebSocket server: " .. tostring(handle))
        return false
    end
end

-- disconnect from WebSocket server
function websocket.disconnect()
    if ws_connection.handle then
        pcall(function() ws_connection.handle.close() end)
        ws_connection.handle = nil
    end
    ws_connection.connected = false
    log.info("WS: Disconnected from WebSocket server")
end

-- send data to WebSocket server
---@param data_type string type of data being sent
---@param data table data to send
---@return boolean success true if data was sent successfully
function websocket.send(data_type, data)
    if not ws_connection.enabled or not ws_connection.connected then
        return false
    end
    
    local message = {
        type = data_type,
        timestamp = os.epoch("utc"),
        data = data
    }
    
    -- serialize message to JSON
    local success, json_str = pcall(function()
        return textutils.serializeJSON(message)
    end)
    
    if not success then
        log.warning("WS: Failed to serialize message: " .. tostring(json_str))
        return false
    end
    
    -- send message
    success = pcall(function()
        ws_connection.handle.send(json_str)
    end)
    
    if not success then
        log.warning("WS: Failed to send message, connection may be lost")
        ws_connection.connected = false
        return false
    end
    
    ws_connection.last_send_time = util.time()
    return true
end

-- send facility status update
---@param facility_data table facility status data
function websocket.send_facility_status(facility_data)
    websocket.send("facility_status", facility_data)
end

-- send unit status update
---@param unit_id integer unit identifier
---@param unit_data table unit status data
function websocket.send_unit_status(unit_id, unit_data)
    websocket.send("unit_status", {
        unit_id = unit_id,
        data = unit_data
    })
end

-- send all units status update
---@param units_data table array of unit status data
function websocket.send_all_units_status(units_data)
    websocket.send("all_units_status", units_data)
end

-- send monitor display state
---@param monitor_id string monitor identifier (main, flow, or unit number)
---@param display_data table display state data
function websocket.send_display_state(monitor_id, display_data)
    websocket.send("display_state", {
        monitor_id = monitor_id,
        data = display_data
    })
end

-- periodic update handler - attempts reconnection if needed
function websocket.update()
    if not ws_connection.enabled then
        return
    end
    
    -- attempt reconnection if disconnected
    if not ws_connection.connected then
        local time_now = util.time()
        if ws_connection.reconnect_timer == nil or 
           (time_now - ws_connection.reconnect_timer) >= ws_connection.reconnect_interval then
            ws_connection.reconnect_timer = time_now
            websocket.connect()
        end
    end
    
    -- check for incoming messages (if needed)
    if ws_connection.connected and ws_connection.handle then
        local success, message = pcall(function()
            return ws_connection.handle.receive(0)  -- non-blocking receive
        end)
        
        if success and message then
            -- handle incoming messages if needed
            log.debug("WS: Received message: " .. tostring(message))
        end
    end
end

-- check if WebSocket is connected
---@return boolean connected true if connected
function websocket.is_connected()
    return ws_connection.connected
end

-- check if WebSocket is enabled
---@return boolean enabled true if enabled
function websocket.is_enabled()
    return ws_connection.enabled
end

return websocket
