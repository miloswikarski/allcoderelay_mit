# AllCodeRelay Webhook Gallery

Welcome to the AllCodeRelay Webhook Gallery! This collection showcases various webhook implementations that demonstrate the versatility of the AllCodeRelay app for different use cases.

## What is AllCodeRelay?

AllCodeRelay is a universal code scanner app that can scan barcodes, QR codes, Data Matrix, Aztec codes, and read NFC tags. When a code is scanned, the app sends the data to a configured webhook endpoint, allowing for powerful automation and integration possibilities.

## How Webhooks Work

When AllCodeRelay scans a code, it sends a POST request to your webhook URL with this format:

```json
{
  "code": "SCANNED_CODE_VALUE"
}
```

Your webhook should respond with:

```json
{
  "code": "CODE_TYPE",
  "codevalue": "PROCESSED_RESPONSE"
}
```

## Gallery Categories

### 🏢 Business & Enterprise
- **Inventory Management** - Track products and stock levels
- **Asset Tracking** - Monitor corporate equipment and resources
- **Event Check-in** - Manage attendee registration and access

### 🏠 Smart Home & IoT
- **Home Automation** - Control lights, devices, and systems
- **Smart Restaurant Menu** - Interactive dining experiences

### 💰 Finance & Productivity
- **Expense Tracking** - Automatic receipt processing
- **Contact Sharing** - Quick contact exchange

### 🔧 Technical Examples
- **n8n Workflows** - Visual automation examples
- **PHP Implementations** - Server-side processing
- **Node.js Services** - Modern JavaScript solutions
- **Python Flask Apps** - Lightweight web services

## Getting Started

1. Choose a webhook example from the gallery
2. Follow the setup instructions for your chosen implementation
3. Configure AllCodeRelay to use your webhook URL
4. Start scanning codes and see the magic happen!

## Configuration

Use the [AllCodeRelay Configuration Tool](../webhook_config.php) to generate QR codes for easy app setup.

## Contributing

Feel free to contribute your own webhook examples to this gallery! Each example should include:
- Complete source code
- Setup instructions
- Example use cases
- Required dependencies
