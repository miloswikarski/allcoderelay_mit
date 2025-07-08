# 📦 Inventory Management Webhook

A comprehensive PHP webhook for managing inventory through barcode scanning with AllCodeRelay.

## Features

- ✅ **Product Lookup**: Instantly find products by scanning barcodes
- ✅ **Stock Monitoring**: Real-time stock level checking with visual indicators
- ✅ **Low Stock Alerts**: Automatic notifications when inventory runs low
- ✅ **Scan Logging**: Track all scanning activity with timestamps
- ✅ **Category Management**: Organize products by categories
- ✅ **Stock Movement Tracking**: Monitor inventory changes over time

## Quick Start

### 1. Database Setup

```bash
# Create database and user
mysql -u root -p < setup.sql
```

### 2. Configure Webhook

Edit `inventory-webhook.php` and update the database credentials:

```php
$db_config = [
    'host' => 'localhost',
    'dbname' => 'inventory_db',
    'username' => 'inventory_user',
    'password' => 'your_actual_password'
];
```

### 3. Deploy Webhook

Upload `inventory-webhook.php` to your web server and note the URL.

### 4. Configure AllCodeRelay

Use the [configuration tool](../../webhook_config.php) to generate a QR code with your webhook URL.

## Usage Examples

### Scanning a Product Barcode

When you scan a product barcode, you'll get a response like:

```
📦 Wireless Mouse

Category: Electronics
Stock: 25 units 🟢
Price: $29.99
Location: A1-B2
Updated: Dec 15, 2024
```

### Stock Status Indicators

- 🟢 **Good Stock**: Above minimum level
- 🟡 **Low Stock**: At or below minimum level
- 🔴 **Out of Stock**: Zero quantity

### Unknown Product

For unrecognized barcodes:

```
⚠️ Product not found!

Barcode: 9876543210987

Would you like to add this product to inventory?
```

## Database Schema

### Products Table
- `barcode` - Unique product identifier
- `name` - Product name
- `stock_quantity` - Current stock level
- `min_stock_level` - Minimum stock threshold
- `price` - Selling price
- `location` - Storage location
- `category_id` - Product category

### Categories Table
- `name` - Category name
- `description` - Category description

### Scan Logs Table
- `product_id` - Scanned product
- `scanned_at` - Timestamp
- `ip_address` - Scanner IP

## Advanced Features

### Low Stock Alerts

The webhook automatically detects low stock situations and can:
- Log alerts to error log
- Send email notifications (configure in code)
- Integrate with Slack/Teams (extend the `sendLowStockAlert` function)

### Stock Movement Tracking

Track inventory changes with the `stock_movements` table:
- IN: Stock received
- OUT: Stock sold/used
- ADJUSTMENT: Manual corrections

### Reporting Queries

```sql
-- Most scanned products
SELECT p.name, COUNT(*) as scan_count
FROM scan_logs sl
JOIN products p ON sl.product_id = p.id
WHERE sl.scanned_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY p.id
ORDER BY scan_count DESC;

-- Low stock report
SELECT * FROM low_stock_products;

-- Recent scanning activity
SELECT * FROM recent_scans LIMIT 20;
```

## Customization

### Adding Custom Fields

Extend the products table:

```sql
ALTER TABLE products ADD COLUMN expiry_date DATE;
ALTER TABLE products ADD COLUMN batch_number VARCHAR(50);
```

### Integration with External Systems

The webhook can be extended to integrate with:
- ERP systems
- E-commerce platforms
- Accounting software
- Supplier APIs

### Mobile-Friendly Admin Interface

Consider adding a web interface for:
- Adding new products
- Updating stock levels
- Viewing reports
- Managing categories

## Security Considerations

1. **Database Security**: Use strong passwords and limit user permissions
2. **Input Validation**: The webhook validates all inputs
3. **Error Handling**: Sensitive information is not exposed in error messages
4. **Access Control**: Consider adding authentication for admin functions

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check credentials in `$db_config`
   - Verify MySQL service is running
   - Ensure user has proper permissions

2. **Product Not Found**
   - Verify barcode format matches database
   - Check if product exists in products table
   - Ensure barcode is properly scanned

3. **Webhook Not Responding**
   - Check web server error logs
   - Verify PHP version compatibility
   - Test webhook URL directly

### Debug Mode

Add debug logging:

```php
// Add at top of webhook file
error_reporting(E_ALL);
ini_set('display_errors', 1);
```

## License

This example is provided as-is for educational and commercial use.
