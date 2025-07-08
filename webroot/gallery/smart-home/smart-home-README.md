# 🏠 Smart Home Automation Webhook

Control your smart home devices by scanning QR codes with AllCodeRelay! This Node.js webhook enables seamless integration with IoT devices, MQTT brokers, and Home Assistant.

## Features

- 🔌 **Device Control**: Toggle lights, switches, and smart outlets
- 🎬 **Scene Activation**: Trigger complex automation scenes
- 🔒 **Security Integration**: Arm/disarm security systems
- 📡 **MQTT Support**: Direct IoT device communication
- 🏠 **Home Assistant**: Full integration with HA ecosystem
- 📱 **Real-time Feedback**: Instant status updates via AllCodeRelay

## Quick Start

### 1. Installation

```bash
# Clone or download the files
cd smart-home-webhook

# Install dependencies
npm install

# Copy environment configuration
cp .env.example .env
```

### 2. Configuration

Edit `.env` file with your settings:

```env
PORT=3000
MQTT_BROKER_URL=mqtt://your-broker:1883
MQTT_USERNAME=your_username
MQTT_PASSWORD=your_password
HA_URL=http://your-home-assistant:8123
HA_TOKEN=your_ha_token
```

### 3. Start the Server

```bash
# Production
npm start

# Development (with auto-reload)
npm run dev
```

### 4. Generate QR Codes

Create QR codes for your devices using these codes:

- `LIGHT_LIVING_ROOM` - Living room light
- `SCENE_MOVIE` - Movie night scene
- `SECURITY_ARM` - Arm security system

Use the [AllCodeRelay configuration tool](../../webhook_config.php) to generate QR codes.

## Device Codes

### Lights
- `LIGHT_LIVING_ROOM` - 💡 Living Room Light
- `LIGHT_BEDROOM` - 💡 Bedroom Light  
- `LIGHT_KITCHEN` - 💡 Kitchen Light

### Switches & Outlets
- `SWITCH_FAN` - 🌀 Ceiling Fan
- `OUTLET_TV` - 📺 TV Outlet

### Scenes
- `SCENE_MOVIE` - 🎬 Movie Night
- `SCENE_BEDTIME` - 🌙 Bedtime
- `SCENE_MORNING` - ☀️ Good Morning

### Security
- `SECURITY_ARM` - 🔒 Arm Security System
- `SECURITY_DISARM` - 🔓 Disarm Security System

## Usage Examples

### Scanning a Light Control QR Code

When you scan `LIGHT_LIVING_ROOM`:

```
💡 Living Room Light

🟢 Living Room Light turned ON
```

### Activating a Scene

When you scan `SCENE_MOVIE`:

```
🎬 Movie Night

✅ Scene activated!

Living Room Light: dim
Kitchen Light: off
TV Outlet: on
```

## Integration Guides

### MQTT Integration

Configure your MQTT broker in `.env`:

```env
MQTT_BROKER_URL=mqtt://192.168.1.100:1883
MQTT_USERNAME=homeassistant
MQTT_PASSWORD=your_password
```

The webhook publishes to topics like:
- `home/living_room/light` - Light control
- `home/security/arm` - Security system

### Home Assistant Integration

1. **Get Long-Lived Access Token**:
   - Go to Profile → Security → Long-Lived Access Tokens
   - Create new token and copy it

2. **Configure in .env**:
   ```env
   HA_URL=http://192.168.1.100:8123
   HA_TOKEN=your_long_lived_token
   ```

3. **Entity Mapping**: The webhook maps to HA entities:
   - `light.living_room`
   - `switch.ceiling_fan`
   - `alarm_control_panel.home`

### Custom Device Configuration

Add new devices in `smart-home-webhook.js`:

```javascript
const devices = {
    'CUSTOM_DEVICE': {
        type: 'switch',
        name: 'My Custom Device',
        mqtt_topic: 'home/custom/device',
        ha_entity: 'switch.custom_device',
        icon: '⚡'
    }
};
```

## API Endpoints

### Webhook Endpoint
- **POST** `/webhook` - Main AllCodeRelay webhook
- **Body**: `{"code": "DEVICE_CODE"}`

### Utility Endpoints
- **GET** `/health` - Health check and status
- **GET** `/devices` - List all configured devices

### Example Health Check Response

```json
{
  "status": "ok",
  "mqtt_connected": true,
  "timestamp": "2024-12-15T10:30:00.000Z"
}
```

## Advanced Features

### Custom Scenes

Create complex automation scenes:

```javascript
'SCENE_PARTY': {
    type: 'scene',
    name: 'Party Mode',
    actions: [
        { device: 'LIGHT_LIVING_ROOM', action: 'dim', value: 60 },
        { device: 'LIGHT_KITCHEN', action: 'on' },
        { device: 'SWITCH_FAN', action: 'on' },
        { device: 'OUTLET_SPEAKERS', action: 'on' }
    ],
    icon: '🎉'
}
```

### Security Features

- **Access Control**: Add authentication middleware
- **Rate Limiting**: Prevent abuse
- **Audit Logging**: Track all device operations

### Notifications

Extend the webhook to send notifications:

```javascript
// Add to device control functions
if (result.success) {
    await sendSlackNotification(`${device.name} controlled via QR scan`);
}
```

## Troubleshooting

### Common Issues

1. **MQTT Connection Failed**
   - Check broker URL and credentials
   - Verify network connectivity
   - Check firewall settings

2. **Home Assistant API Errors**
   - Verify HA URL is accessible
   - Check long-lived access token
   - Ensure entities exist in HA

3. **Device Not Responding**
   - Check device configuration
   - Verify MQTT topics match your setup
   - Test device control manually

### Debug Mode

Enable detailed logging:

```bash
LOG_LEVEL=debug npm start
```

### Testing Without Hardware

The webhook works without actual devices - it will log commands and return success messages for testing.

## Security Considerations

1. **Network Security**: Use HTTPS in production
2. **Authentication**: Add webhook authentication
3. **Access Control**: Limit device access by user/location
4. **Audit Trail**: Log all device operations

## Deployment

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### PM2 Process Manager

```bash
npm install -g pm2
pm2 start smart-home-webhook.js --name "smart-home-webhook"
pm2 startup
pm2 save
```

## License

This example is provided as-is for educational and commercial use.
