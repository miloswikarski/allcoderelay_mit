<?php
/**
 * AllCodeRelay Asset Tracking Webhook
 * 
 * This webhook handles asset tracking for corporate environments.
 * Features:
 * - Asset registration and lookup
 * - Check-in/check-out tracking
 * - Location management
 * - Maintenance scheduling
 * - Asset history logging
 * 
 * Database: SQLite (portable and easy setup)
 * 
 * Setup Instructions:
 * 1. Ensure PHP SQLite extension is enabled
 * 2. Run this script once to initialize database
 * 3. Configure AllCodeRelay to use this webhook URL
 * 4. Start scanning asset tags!
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Database configuration
$db_path = __DIR__ . '/assets.db';

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

// Initialize database if it doesn't exist
if (!file_exists($db_path)) {
    initializeDatabase($db_path);
}

// Get the JSON input
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if (!$data || !isset($data['code'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid input']);
    exit();
}

$asset_code = trim($data['code']);

try {
    // Connect to database
    $pdo = new PDO("sqlite:$db_path");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Look up asset by code
    $stmt = $pdo->prepare("
        SELECT a.*, c.name as category_name, l.name as location_name,
               u.name as checked_out_to_name
        FROM assets a 
        LEFT JOIN categories c ON a.category_id = c.id 
        LEFT JOIN locations l ON a.current_location_id = l.id
        LEFT JOIN users u ON a.checked_out_to = u.id
        WHERE a.asset_code = ?
    ");
    $stmt->execute([$asset_code]);
    $asset = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$asset) {
        // Asset not found - suggest registration
        $response = [
            'code' => $asset_code,
            'codevalue' => "⚠️ Asset Not Found!\n\nAsset Code: {$asset_code}\n\nThis asset is not registered in the system.\nPlease contact IT to register this asset."
        ];
    } else {
        // Asset found - show details and status
        $status_info = getAssetStatus($asset);
        $last_updated = date('M j, Y H:i', strtotime($asset['updated_at']));
        
        $response_text = "🏷️ {$asset['name']}\n\n" .
                        "📋 ID: {$asset['asset_code']}\n" .
                        "🏢 Category: {$asset['category_name']}\n" .
                        "📍 Location: {$asset['location_name']}\n" .
                        "📊 Status: {$status_info['status']} {$status_info['icon']}\n";

        if ($asset['checked_out_to']) {
            $response_text .= "👤 Checked out to: {$asset['checked_out_to_name']}\n";
            $checkout_date = date('M j, Y', strtotime($asset['checkout_date']));
            $response_text .= "📅 Since: {$checkout_date}\n";
        }

        if ($asset['next_maintenance']) {
            $maintenance_date = date('M j, Y', strtotime($asset['next_maintenance']));
            $days_until = ceil((strtotime($asset['next_maintenance']) - time()) / 86400);
            if ($days_until <= 7) {
                $response_text .= "\n🔧 Maintenance due: {$maintenance_date} ({$days_until} days)";
            }
        }

        $response_text .= "\n\n⏰ Updated: {$last_updated}";

        $response = [
            'code' => $asset_code,
            'codevalue' => $response_text
        ];

        // Log the scan
        logAssetScan($pdo, $asset['id'], $asset_code);
        
        // Check for maintenance alerts
        checkMaintenanceAlerts($asset);
    }

    echo json_encode($response);

} catch (PDOException $e) {
    error_log("Database error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'code' => $asset_code,
        'codevalue' => "❌ Database error occurred.\n\nPlease try again or contact IT support."
    ]);
} catch (Exception $e) {
    error_log("General error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'code' => $asset_code,
        'codevalue' => "❌ An error occurred.\n\nPlease try again or contact IT support."
    ]);
}

function initializeDatabase($db_path) {
    $pdo = new PDO("sqlite:$db_path");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Create tables
    $pdo->exec("
        CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");

    $pdo->exec("
        CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            building TEXT,
            floor TEXT,
            room TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");

    $pdo->exec("
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT UNIQUE,
            department TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ");

    $pdo->exec("
        CREATE TABLE assets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_code TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            description TEXT,
            category_id INTEGER,
            serial_number TEXT,
            model TEXT,
            manufacturer TEXT,
            purchase_date DATE,
            purchase_price DECIMAL(10,2),
            warranty_expiry DATE,
            current_location_id INTEGER,
            status TEXT DEFAULT 'available',
            condition_rating INTEGER DEFAULT 5,
            checked_out_to INTEGER,
            checkout_date DATETIME,
            next_maintenance DATE,
            notes TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (category_id) REFERENCES categories(id),
            FOREIGN KEY (current_location_id) REFERENCES locations(id),
            FOREIGN KEY (checked_out_to) REFERENCES users(id)
        )
    ");

    $pdo->exec("
        CREATE TABLE asset_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            asset_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            details TEXT,
            user_id INTEGER,
            location_id INTEGER,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            ip_address TEXT,
            FOREIGN KEY (asset_id) REFERENCES assets(id),
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (location_id) REFERENCES locations(id)
        )
    ");

    // Insert sample data
    insertSampleData($pdo);
}

function insertSampleData($pdo) {
    // Categories
    $categories = [
        ['Computers', 'Desktop computers, laptops, tablets'],
        ['Monitors', 'Computer monitors and displays'],
        ['Furniture', 'Office furniture and equipment'],
        ['Tools', 'Maintenance and technical tools'],
        ['Vehicles', 'Company vehicles and equipment']
    ];

    foreach ($categories as $cat) {
        $pdo->prepare("INSERT INTO categories (name, description) VALUES (?, ?)")
            ->execute($cat);
    }

    // Locations
    $locations = [
        ['Office Floor 1', 'Main office first floor', 'Building A', '1', ''],
        ['Office Floor 2', 'Main office second floor', 'Building A', '2', ''],
        ['Warehouse', 'Storage and shipping area', 'Building B', '1', ''],
        ['IT Department', 'IT support and server room', 'Building A', '2', 'Room 201'],
        ['Conference Room A', 'Main conference room', 'Building A', '1', 'Room 105']
    ];

    foreach ($locations as $loc) {
        $pdo->prepare("INSERT INTO locations (name, description, building, floor, room) VALUES (?, ?, ?, ?, ?)")
            ->execute($loc);
    }

    // Users
    $users = [
        ['John Smith', 'john.smith@company.com', 'IT'],
        ['Sarah Johnson', 'sarah.j@company.com', 'Marketing'],
        ['Mike Chen', 'mike.chen@company.com', 'Engineering'],
        ['Emily Davis', 'emily.davis@company.com', 'HR'],
        ['David Wilson', 'david.w@company.com', 'Finance']
    ];

    foreach ($users as $user) {
        $pdo->prepare("INSERT INTO users (name, email, department) VALUES (?, ?, ?)")
            ->execute($user);
    }

    // Sample assets
    $assets = [
        ['LAPTOP001', 'Dell Latitude 7420', 'Business laptop', 1, 'DL7420001', 'Latitude 7420', 'Dell', '2023-01-15', 1299.99, '2026-01-15', 4, 'checked_out', 5, 1, date('Y-m-d H:i:s'), '2024-03-15'],
        ['MONITOR002', 'Samsung 27" Monitor', '27-inch 4K monitor', 2, 'SM27001', 'U28E590D', 'Samsung', '2023-02-20', 299.99, '2026-02-20', 1, 'available', 5, null, null, null],
        ['DESK003', 'Standing Desk', 'Height adjustable desk', 3, 'SD001', 'StandDesk Pro', 'ErgoTech', '2023-03-10', 599.99, null, 2, 'available', 4, null, null, null],
        ['DRILL004', 'Cordless Drill', 'Professional cordless drill', 4, 'CD18V001', 'DCD771C2', 'DeWalt', '2023-04-05', 129.99, '2025-04-05', 3, 'maintenance', 3, null, null, '2024-12-20'],
        ['VAN005', 'Delivery Van', 'Company delivery vehicle', 5, 'FORD2023001', 'Transit 250', 'Ford', '2023-05-01', 35000.00, '2026-05-01', 3, 'available', 4, null, null, '2024-12-25']
    ];

    foreach ($assets as $asset) {
        $pdo->prepare("
            INSERT INTO assets (asset_code, name, description, category_id, serial_number, model, manufacturer, 
                              purchase_date, purchase_price, warranty_expiry, current_location_id, status, 
                              condition_rating, checked_out_to, checkout_date, next_maintenance) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ")->execute($asset);
    }
}

function getAssetStatus($asset) {
    switch ($asset['status']) {
        case 'available':
            return ['status' => 'Available', 'icon' => '🟢'];
        case 'checked_out':
            return ['status' => 'Checked Out', 'icon' => '🟡'];
        case 'maintenance':
            return ['status' => 'In Maintenance', 'icon' => '🔧'];
        case 'retired':
            return ['status' => 'Retired', 'icon' => '🔴'];
        case 'lost':
            return ['status' => 'Lost/Missing', 'icon' => '❌'];
        default:
            return ['status' => 'Unknown', 'icon' => '❓'];
    }
}

function logAssetScan($pdo, $asset_id, $asset_code) {
    try {
        $stmt = $pdo->prepare("
            INSERT INTO asset_logs (asset_id, action, details, timestamp, ip_address) 
            VALUES (?, 'scan', ?, datetime('now'), ?)
        ");
        $stmt->execute([$asset_id, "Asset scanned: $asset_code", $_SERVER['REMOTE_ADDR'] ?? 'unknown']);
    } catch (Exception $e) {
        error_log("Failed to log asset scan: " . $e->getMessage());
    }
}

function checkMaintenanceAlerts($asset) {
    if ($asset['next_maintenance']) {
        $days_until = ceil((strtotime($asset['next_maintenance']) - time()) / 86400);
        if ($days_until <= 7 && $days_until >= 0) {
            error_log("MAINTENANCE ALERT: {$asset['name']} (ID: {$asset['asset_code']}) - Maintenance due in {$days_until} days");
        }
    }
}
?>
