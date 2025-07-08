/**
 * AllCodeRelay Smart Home Automation Webhook
 * 
 * This Node.js webhook enables QR code-based control of smart home devices.
 * Features:
 * - Control lights, switches, and smart devices
 * - Scene activation
 * - MQTT integration for IoT devices
 * - Home Assistant integration
 * - Security and access control
 * 
 * Setup Instructions:
 * 1. Install dependencies: npm install express mqtt axios dotenv
 * 2. Configure environment variables (see .env.example)
 * 3. Set up MQTT broker or Home Assistant
 * 4. Generate QR codes for your devices/scenes
 * 5. Start the server: node smart-home-webhook.js
 */

const express = require('express');
const mqtt = require('mqtt');
const axios = require('axios');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// MQTT client setup
let mqttClient = null;
if (process.env.MQTT_BROKER_URL) {
    mqttClient = mqtt.connect(process.env.MQTT_BROKER_URL, {
        username: process.env.MQTT_USERNAME,
        password: process.env.MQTT_PASSWORD
    });

    mqttClient.on('connect', () => {
        console.log('Connected to MQTT broker');
    });

    mqttClient.on('error', (error) => {
        console.error('MQTT connection error:', error);
    });
}

// Device configurations
const devices = {
    // Lights
    'LIGHT_LIVING_ROOM': {
        type: 'light',
        name: 'Living Room Light',
        mqtt_topic: 'home/living_room/light',
        ha_entity: 'light.living_room',
        icon: '💡'
    },
    'LIGHT_BEDROOM': {
        type: 'light',
        name: 'Bedroom Light',
        mqtt_topic: 'home/bedroom/light',
        ha_entity: 'light.bedroom',
        icon: '💡'
    },
    'LIGHT_KITCHEN': {
        type: 'light',
        name: 'Kitchen Light',
        mqtt_topic: 'home/kitchen/light',
        ha_entity: 'light.kitchen',
        icon: '💡'
    },

    // Switches and outlets
    'SWITCH_FAN': {
        type: 'switch',
        name: 'Ceiling Fan',
        mqtt_topic: 'home/living_room/fan',
        ha_entity: 'switch.ceiling_fan',
        icon: '🌀'
    },
    'OUTLET_TV': {
        type: 'switch',
        name: 'TV Outlet',
        mqtt_topic: 'home/living_room/tv_outlet',
        ha_entity: 'switch.tv_outlet',
        icon: '📺'
    },

    // Scenes
    'SCENE_MOVIE': {
        type: 'scene',
        name: 'Movie Night',
        actions: [
            { device: 'LIGHT_LIVING_ROOM', action: 'dim', value: 20 },
            { device: 'LIGHT_KITCHEN', action: 'off' },
            { device: 'OUTLET_TV', action: 'on' }
        ],
        icon: '🎬'
    },
    'SCENE_BEDTIME': {
        type: 'scene',
        name: 'Bedtime',
        actions: [
            { device: 'LIGHT_LIVING_ROOM', action: 'off' },
            { device: 'LIGHT_KITCHEN', action: 'off' },
            { device: 'LIGHT_BEDROOM', action: 'dim', value: 10 },
            { device: 'SWITCH_FAN', action: 'on' }
        ],
        icon: '🌙'
    },
    'SCENE_MORNING': {
        type: 'scene',
        name: 'Good Morning',
        actions: [
            { device: 'LIGHT_BEDROOM', action: 'on' },
            { device: 'LIGHT_KITCHEN', action: 'on' },
            { device: 'SWITCH_FAN', action: 'off' }
        ],
        icon: '☀️'
    },

    // Security
    'SECURITY_ARM': {
        type: 'security',
        name: 'Arm Security System',
        mqtt_topic: 'home/security/arm',
        ha_entity: 'alarm_control_panel.home',
        action: 'arm_away',
        icon: '🔒'
    },
    'SECURITY_DISARM': {
        type: 'security',
        name: 'Disarm Security System',
        mqtt_topic: 'home/security/disarm',
        ha_entity: 'alarm_control_panel.home',
        action: 'disarm',
        icon: '🔓'
    }
};

// Main webhook endpoint
app.post('/webhook', async (req, res) => {
    try {
        const { code } = req.body;
        
        if (!code) {
            return res.status(400).json({
                code: 'ERROR',
                codevalue: 'No code provided'
            });
        }

        console.log(`Received code: ${code}`);

        // Check if code matches a device or scene
        const device = devices[code.toUpperCase()];
        
        if (!device) {
            return res.json({
                code: code,
                codevalue: `❓ Unknown device code: ${code}\n\nPlease check your QR code or contact administrator.`
            });
        }

        let result;
        
        switch (device.type) {
            case 'light':
            case 'switch':
                result = await toggleDevice(device);
                break;
            case 'scene':
                result = await activateScene(device);
                break;
            case 'security':
                result = await controlSecurity(device);
                break;
            default:
                result = { success: false, message: 'Unknown device type' };
        }

        const response = {
            code: code,
            codevalue: `${device.icon} ${device.name}\n\n${result.message}`
        };

        res.json(response);

    } catch (error) {
        console.error('Webhook error:', error);
        res.status(500).json({
            code: req.body.code || 'ERROR',
            codevalue: '❌ An error occurred. Please try again.'
        });
    }
});

// Toggle device (light/switch)
async function toggleDevice(device) {
    try {
        // Get current state first (if possible)
        let currentState = await getCurrentState(device);
        let newState = currentState === 'on' ? 'off' : 'on';
        
        // Send MQTT command
        if (mqttClient && device.mqtt_topic) {
            mqttClient.publish(device.mqtt_topic, newState);
        }

        // Send Home Assistant command
        if (process.env.HA_URL && device.ha_entity) {
            await sendHomeAssistantCommand(device.ha_entity, newState);
        }

        const stateEmoji = newState === 'on' ? '🟢' : '⚫';
        return {
            success: true,
            message: `${stateEmoji} ${device.name} turned ${newState.toUpperCase()}`
        };

    } catch (error) {
        console.error('Device toggle error:', error);
        return {
            success: false,
            message: `❌ Failed to control ${device.name}`
        };
    }
}

// Activate scene
async function activateScene(scene) {
    try {
        let results = [];
        
        for (const action of scene.actions) {
            const targetDevice = devices[action.device];
            if (targetDevice) {
                let command = action.action;
                if (action.action === 'dim' && action.value) {
                    command = `dim:${action.value}`;
                }

                // Send MQTT command
                if (mqttClient && targetDevice.mqtt_topic) {
                    mqttClient.publish(targetDevice.mqtt_topic, command);
                }

                // Send Home Assistant command
                if (process.env.HA_URL && targetDevice.ha_entity) {
                    await sendHomeAssistantCommand(targetDevice.ha_entity, command);
                }

                results.push(`${targetDevice.name}: ${action.action}`);
            }
        }

        return {
            success: true,
            message: `✅ Scene activated!\n\n${results.join('\n')}`
        };

    } catch (error) {
        console.error('Scene activation error:', error);
        return {
            success: false,
            message: `❌ Failed to activate ${scene.name}`
        };
    }
}

// Control security system
async function controlSecurity(device) {
    try {
        // Send MQTT command
        if (mqttClient && device.mqtt_topic) {
            mqttClient.publish(device.mqtt_topic, device.action);
        }

        // Send Home Assistant command
        if (process.env.HA_URL && device.ha_entity) {
            await sendHomeAssistantCommand(device.ha_entity, device.action);
        }

        const actionText = device.action === 'arm_away' ? 'ARMED' : 'DISARMED';
        return {
            success: true,
            message: `✅ Security system ${actionText}`
        };

    } catch (error) {
        console.error('Security control error:', error);
        return {
            success: false,
            message: `❌ Failed to control security system`
        };
    }
}

// Get current device state (placeholder - implement based on your system)
async function getCurrentState(device) {
    // This would typically query your smart home system
    // For now, we'll assume devices are off by default
    return 'off';
}

// Send command to Home Assistant
async function sendHomeAssistantCommand(entity, command) {
    if (!process.env.HA_URL || !process.env.HA_TOKEN) {
        return;
    }

    try {
        const [domain, entityName] = entity.split('.');
        let service, data;

        if (command === 'on') {
            service = `${domain}/turn_on`;
            data = { entity_id: entity };
        } else if (command === 'off') {
            service = `${domain}/turn_off`;
            data = { entity_id: entity };
        } else if (command.startsWith('dim:')) {
            const brightness = parseInt(command.split(':')[1]);
            service = `${domain}/turn_on`;
            data = { entity_id: entity, brightness_pct: brightness };
        }

        await axios.post(`${process.env.HA_URL}/api/services/${service}`, data, {
            headers: {
                'Authorization': `Bearer ${process.env.HA_TOKEN}`,
                'Content-Type': 'application/json'
            }
        });

    } catch (error) {
        console.error('Home Assistant API error:', error.message);
    }
}

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        mqtt_connected: mqttClient ? mqttClient.connected : false,
        timestamp: new Date().toISOString()
    });
});

// Device list endpoint
app.get('/devices', (req, res) => {
    const deviceList = Object.entries(devices).map(([code, device]) => ({
        code,
        name: device.name,
        type: device.type,
        icon: device.icon
    }));
    
    res.json(deviceList);
});

// Start server
app.listen(port, () => {
    console.log(`Smart Home Webhook server running on port ${port}`);
    console.log(`Webhook URL: http://localhost:${port}/webhook`);
    console.log(`Health check: http://localhost:${port}/health`);
    console.log(`Device list: http://localhost:${port}/devices`);
});

module.exports = app;
