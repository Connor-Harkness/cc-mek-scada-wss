# WebSocket Control Panel

This feature allows the coordinator to forward all monitor display data to a WebSocket server, enabling remote monitoring and control panel functionality.

## Configuration

The WebSocket feature can be configured through the coordinator configurator or by manually editing the `coordinator.settings` file.

### Settings

- **WebSocketEnabled**: `true` or `false` - Enable or disable WebSocket forwarding
- **WebSocketURL**: String - The WebSocket server URL (e.g., `"ws://localhost:8080"` or `"wss://example.com/scada"`)

### Example Configuration

To enable WebSocket forwarding, add these settings to your `coordinator.settings`:

```lua
settings.set("WebSocketEnabled", true)
settings.set("WebSocketURL", "ws://localhost:8080")
settings.save("/coordinator.settings")
```

## Data Format

The coordinator sends JSON-formatted messages over the WebSocket connection. Each message includes:

- `type`: The type of data being sent
- `timestamp`: UTC timestamp in milliseconds
- `data`: The actual data payload

### Message Types

#### 1. Facility Status (`facility_status`)

Sent when facility-level data is updated. Includes:
- Overall system status
- Auto control status
- SCRAM conditions
- RTU count
- Radiation levels
- Induction matrix data
- SPS (Supercritical Phase Shifter) data
- Dynamic tank data

Example:
```json
{
  "type": "facility_status",
  "timestamp": 1234567890,
  "data": {
    "all_sys_ok": true,
    "auto_ready": true,
    "auto_active": true,
    "auto_ramping": false,
    "auto_saturated": false,
    "auto_scram": false,
    "ascram_status": {
      "matrix_fault": false,
      "matrix_fill": false,
      "crit_alarm": false,
      "radiation": false,
      "gen_fault": false
    },
    "status_lines": ["All systems normal", ""],
    "rtu_count": 5,
    "radiation": { ... },
    "induction_data": [ ... ],
    "sps_data": [ ... ],
    "tank_data": [ ... ]
  }
}
```

#### 2. All Units Status (`all_units_status`)

Sent when unit data is updated. Includes an array of unit data for each reactor unit:

Example:
```json
{
  "type": "all_units_status",
  "timestamp": 1234567890,
  "data": [
    {
      "unit_id": 1,
      "connected": true,
      "reactor_data": { ... },
      "boiler_data_tbl": [ ... ],
      "turbine_data_tbl": [ ... ],
      "tank_data_tbl": [ ... ],
      "radiation": { ... },
      "waste_product": 1,
      "waste_stats": [0.5, 0.1, 0.0],
      "status_lines": ["Reactor active", "Burn rate: 10.0 mB/t"]
    }
  ]
}
```

## Connection Management

The WebSocket client automatically:
- Attempts to connect on coordinator startup (if enabled)
- Reconnects automatically every 5 seconds if disconnected
- Handles connection failures gracefully without affecting coordinator operation

## WebSocket Server Requirements

Your WebSocket server should:
1. Accept WebSocket connections on the configured URL
2. Handle JSON messages
3. Be accessible from the ComputerCraft computer
4. Support the WebSocket protocol (RFC 6455)

## Example WebSocket Server

Here's a minimal Node.js WebSocket server example:

```javascript
const WebSocket = require('ws');
const server = new WebSocket.Server({ port: 8080 });

server.on('connection', (ws) => {
  console.log('Coordinator connected');
  
  ws.on('message', (message) => {
    const data = JSON.parse(message);
    console.log(`Received ${data.type}:`, data.data);
    
    // Process the data and update your web control panel
  });
  
  ws.on('close', () => {
    console.log('Coordinator disconnected');
  });
});

console.log('WebSocket server running on ws://localhost:8080');
```

## Security Considerations

- Use `wss://` (WebSocket Secure) for production deployments
- Implement authentication on your WebSocket server
- Restrict WebSocket server access with firewall rules
- Consider rate limiting to prevent abuse

## Troubleshooting

### WebSocket won't connect
- Verify the WebSocket URL is correct
- Check that HTTP is enabled in ComputerCraft config
- Ensure the WebSocket server is running and accessible
- Check coordinator logs for connection errors

### Data not being sent
- Verify `WebSocketEnabled` is set to `true`
- Check that the coordinator is connected to the supervisor
- Look for errors in the coordinator log file

### Connection keeps dropping
- Check network stability
- Verify the WebSocket server is handling connections properly
- Increase the reconnect interval if needed (modify `websocket.lua`)

## Implementation Details

The WebSocket integration is implemented in:
- `scada-common/websocket.lua` - WebSocket client module
- `coordinator/iocontrol.lua` - Data forwarding hooks
- `coordinator/threads.lua` - Connection management
- `coordinator/coordinator.lua` - Configuration loading

Data is forwarded whenever the coordinator receives status updates from the supervisor, ensuring the WebSocket server receives real-time updates.
