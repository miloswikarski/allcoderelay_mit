# 🏷️ Asset Tracking Webhook

A comprehensive PHP webhook for tracking corporate assets and equipment through QR code scanning with AllCodeRelay.

## Features

- ✅ **Asset Registration**: Complete asset database with detailed information
- ✅ **Check-in/Check-out**: Track who has what equipment and when
- ✅ **Location Tracking**: Monitor asset locations across buildings and rooms
- ✅ **Maintenance Scheduling**: Track maintenance due dates and alerts
- ✅ **Asset History**: Complete audit trail of all asset activities
- ✅ **Status Management**: Available, checked out, maintenance, retired states
- ✅ **Condition Tracking**: Monitor asset condition ratings
- ✅ **Portable Database**: Uses SQLite for easy deployment

## Quick Start

### 1. Setup

```bash
# Ensure PHP SQLite extension is enabled
php -m | grep sqlite

# Upload asset-tracking-webhook.php to your web server
# The database will be created automatically on first run
```

### 2. Configure AllCodeRelay

Use the [configuration tool](../../webhook_config.php) to generate a QR code with your webhook URL:
`http://your-server/path/to/asset-tracking-webhook.php`

### 3. Start Scanning

Scan asset QR codes to get instant information about:
- Asset details and specifications
- Current location and status
- Check-out information
- Maintenance schedules

## Usage Examples

### Available Asset

When scanning an available asset:

```
🏷️ Dell Latitude 7420

📋 ID: LAPTOP001
🏢 Category: Computers
📍 Location: IT Department
📊 Status: Available 🟢

⏰ Updated: Dec 15, 2024 14:30
```

### Checked Out Asset

For assets currently in use:

```
🏷️ Samsung 27" Monitor

📋 ID: MONITOR002
🏢 Category: Monitors
📍 Location: Office Floor 1
📊 Status: Checked Out 🟡
👤 Checked out to: John Smith
📅 Since: Dec 10, 2024

⏰ Updated: Dec 15, 2024 09:15
```

### Maintenance Due

For assets requiring maintenance:

```
🏷️ Cordless Drill

📋 ID: DRILL004
🏢 Category: Tools
📍 Location: Warehouse
📊 Status: In Maintenance 🔧

🔧 Maintenance due: Dec 20, 2024 (5 days)

⏰ Updated: Dec 15, 2024 11:45
```

### Unregistered Asset

For unknown asset codes:

```
⚠️ Asset Not Found!

Asset Code: UNKNOWN123

This asset is not registered in the system.
Please contact IT to register this asset.
```

## Database Schema

### Assets Table
- `asset_code` - Unique asset identifier (QR code content)
- `name` - Asset name/description
- `category_id` - Asset category
- `serial_number` - Manufacturer serial number
- `model` / `manufacturer` - Product details
- `current_location_id` - Current location
- `status` - Current status (available, checked_out, maintenance, etc.)
- `checked_out_to` - User who has the asset
- `next_maintenance` - Scheduled maintenance date

### Categories Table
- `name` - Category name (Computers, Monitors, Furniture, etc.)
- `description` - Category description

### Locations Table
- `name` - Location name
- `building` / `floor` / `room` - Physical location details

### Users Table
- `name` / `email` / `department` - User information

### Asset Logs Table
- `asset_id` - Reference to asset
- `action` - Action performed (scan, checkout, checkin, etc.)
- `timestamp` - When action occurred
- `user_id` - Who performed the action

## Asset Status Types

### 🟢 Available
- Asset is ready for use
- Can be checked out
- Located at designated spot

### 🟡 Checked Out
- Asset is assigned to a user
- Shows who has it and since when
- Tracks usage patterns

### 🔧 In Maintenance
- Asset is being serviced
- Not available for checkout
- Maintenance schedule tracking

### 🔴 Retired
- Asset is no longer in service
- Kept for historical records
- Cannot be checked out

### ❌ Lost/Missing
- Asset cannot be located
- Requires investigation
- Flagged for replacement

## Advanced Features

### Maintenance Alerts

The system automatically tracks maintenance schedules:

```php
// Automatic alerts for maintenance due within 7 days
if ($days_until_maintenance <= 7) {
    sendMaintenanceAlert($asset);
}
```

### Asset History Tracking

Every scan and action is logged:

```sql
-- View asset history
SELECT al.*, u.name as user_name, l.name as location_name
FROM asset_logs al
LEFT JOIN users u ON al.user_id = u.id
LEFT JOIN locations l ON al.location_id = l.id
WHERE al.asset_id = ?
ORDER BY al.timestamp DESC;
```

### Reporting Queries

Generate useful reports:

```sql
-- Assets due for maintenance
SELECT a.*, c.name as category_name
FROM assets a
JOIN categories c ON a.category_id = c.id
WHERE a.next_maintenance <= date('now', '+7 days')
AND a.status != 'retired';

-- Most scanned assets
SELECT a.name, COUNT(*) as scan_count
FROM asset_logs al
JOIN assets a ON al.asset_id = a.id
WHERE al.action = 'scan'
AND al.timestamp >= date('now', '-30 days')
GROUP BY a.id
ORDER BY scan_count DESC;

-- Assets by location
SELECT l.name as location, COUNT(*) as asset_count
FROM assets a
JOIN locations l ON a.current_location_id = l.id
WHERE a.status != 'retired'
GROUP BY l.id;
```

## Customization

### Adding Custom Fields

Extend the assets table:

```sql
ALTER TABLE assets ADD COLUMN warranty_provider TEXT;
ALTER TABLE assets ADD COLUMN insurance_policy TEXT;
ALTER TABLE assets ADD COLUMN depreciation_rate DECIMAL(5,2);
```

### Custom Asset Categories

Add new categories:

```sql
INSERT INTO categories (name, description) VALUES 
('Medical Equipment', 'Healthcare and medical devices'),
('Security', 'Security cameras and access control'),
('Kitchen', 'Kitchen and cafeteria equipment');
```

### Integration with HR Systems

Sync user data from existing systems:

```php
// Import users from CSV/API
function importUsers($userData) {
    foreach ($userData as $user) {
        $stmt = $pdo->prepare("
            INSERT OR REPLACE INTO users (name, email, department) 
            VALUES (?, ?, ?)
        ");
        $stmt->execute([$user['name'], $user['email'], $user['department']]);
    }
}
```

## Admin Functions

### Asset Registration

Add new assets to the system:

```sql
INSERT INTO assets (
    asset_code, name, description, category_id, 
    serial_number, model, manufacturer, purchase_date, 
    purchase_price, current_location_id, status
) VALUES (
    'LAPTOP002', 'MacBook Pro 16"', 'Development laptop',
    1, 'MBP16001', 'MacBook Pro', 'Apple', '2024-01-15',
    2499.99, 4, 'available'
);
```

### Bulk Operations

Update multiple assets:

```sql
-- Move all assets from one location to another
UPDATE assets 
SET current_location_id = 2, updated_at = datetime('now')
WHERE current_location_id = 1 AND status = 'available';

-- Schedule maintenance for all tools
UPDATE assets 
SET next_maintenance = date('now', '+90 days')
WHERE category_id = (SELECT id FROM categories WHERE name = 'Tools');
```

## Security Considerations

1. **File Permissions**: Ensure database file is not web-accessible
2. **Input Validation**: All inputs are sanitized and validated
3. **Access Control**: Consider adding authentication for admin functions
4. **Audit Trail**: Complete logging of all asset activities
5. **Backup Strategy**: Regular database backups recommended

## Deployment

### Production Setup

```bash
# Set proper file permissions
chmod 644 asset-tracking-webhook.php
chmod 600 assets.db

# Move database outside web root (recommended)
mv assets.db /var/data/assets.db

# Update $db_path in webhook file
$db_path = '/var/data/assets.db';
```

### Backup Strategy

```bash
# Daily backup script
#!/bin/bash
DATE=$(date +%Y%m%d)
cp /var/data/assets.db /backups/assets_$DATE.db

# Keep only last 30 days
find /backups -name "assets_*.db" -mtime +30 -delete
```

## Troubleshooting

### Common Issues

1. **Database Permission Denied**
   - Check file permissions on assets.db
   - Ensure web server can write to directory

2. **Asset Not Found**
   - Verify asset code format
   - Check if asset exists in database
   - Ensure QR code is properly scanned

3. **SQLite Extension Missing**
   - Install php-sqlite3 package
   - Enable sqlite3 extension in php.ini

### Debug Mode

Add debug logging:

```php
// Add at top of webhook file
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '/path/to/error.log');
```

## License

This example is provided as-is for educational and commercial use.
