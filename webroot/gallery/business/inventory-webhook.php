<?php
/**
 * AllCodeRelay Inventory Management Webhook
 * 
 * This webhook handles barcode scanning for inventory management.
 * Features:
 * - Product lookup by barcode
 * - Stock level checking
 * - Inventory updates
 * - Low stock alerts
 * 
 * Database: MySQL/MariaDB
 * 
 * Setup Instructions:
 * 1. Create database and tables (see setup.sql)
 * 2. Update database credentials below
 * 3. Configure AllCodeRelay to use this webhook URL
 * 4. Start scanning product barcodes!
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Database configuration
$db_config = [
    'host' => 'localhost',
    'dbname' => 'inventory_db',
    'username' => 'inventory_user',
    'password' => 'your_password_here'
];

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

// Get the JSON input
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['code'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid input']);
    exit();
}

$barcode = trim($data['code']);

try {
    // Connect to database
    $pdo = new PDO(
        "mysql:host={$db_config['host']};dbname={$db_config['dbname']};charset=utf8mb4",
        $db_config['username'],
        $db_config['password'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );

    // Look up product by barcode
    $stmt = $pdo->prepare("
        SELECT p.*, c.name as category_name 
        FROM products p 
        LEFT JOIN categories c ON p.category_id = c.id 
        WHERE p.barcode = ?
    ");
    $stmt->execute([$barcode]);
    $product = $stmt->fetch();

    if (!$product) {
        // Product not found - suggest adding it
        $response = [
            'code' => $barcode,
            'codevalue' => "⚠️ Product not found!\n\nBarcode: {$barcode}\n\nWould you like to add this product to inventory?"
        ];
    } else {
        // Product found - show details and stock info
        $stock_status = getStockStatus($product['stock_quantity'], $product['min_stock_level']);
        $last_updated = date('M j, Y', strtotime($product['updated_at']));
        
        $response = [
            'code' => $barcode,
            'codevalue' => "📦 {$product['name']}\n\n" .
                         "Category: {$product['category_name']}\n" .
                         "Stock: {$product['stock_quantity']} units {$stock_status}\n" .
                         "Price: $" . number_format($product['price'], 2) . "\n" .
                         "Location: {$product['location']}\n" .
                         "Updated: {$last_updated}"
        ];

        // Log the scan
        logScan($pdo, $product['id'], $barcode);
        
        // Check for low stock alert
        if ($product['stock_quantity'] <= $product['min_stock_level']) {
            sendLowStockAlert($product);
        }
    }

    echo json_encode($response);

} catch (PDOException $e) {
    error_log("Database error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'code' => $barcode,
        'codevalue' => "❌ Database error occurred. Please try again."
    ]);
} catch (Exception $e) {
    error_log("General error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'code' => $barcode,
        'codevalue' => "❌ An error occurred. Please try again."
    ]);
}

function getStockStatus($current_stock, $min_stock) {
    if ($current_stock <= 0) {
        return "🔴 OUT OF STOCK";
    } elseif ($current_stock <= $min_stock) {
        return "🟡 LOW STOCK";
    } else {
        return "🟢";
    }
}

function logScan($pdo, $product_id, $barcode) {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO scan_logs (product_id, barcode, scanned_at, ip_address) 
            VALUES (?, ?, NOW(), ?)
        ");
        $stmt->execute([$product_id, $barcode, $_SERVER['REMOTE_ADDR'] ?? 'unknown']);
    } catch (Exception $e) {
        error_log("Failed to log scan: " . $e->getMessage());
    }
}

function sendLowStockAlert($product) {
    // Here you could integrate with email, Slack, SMS, etc.
    // For now, we'll just log it
    error_log("LOW STOCK ALERT: {$product['name']} (ID: {$product['id']}) - Only {$product['stock_quantity']} units remaining");
    
    // Example: Send email alert (uncomment and configure)
    /*
    $to = 'inventory@yourcompany.com';
    $subject = 'Low Stock Alert: ' . $product['name'];
    $message = "Product: {$product['name']}\nCurrent Stock: {$product['stock_quantity']}\nMinimum Level: {$product['min_stock_level']}";
    mail($to, $subject, $message);
    */
}
?>
