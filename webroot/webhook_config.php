<?php
// Simple web page to generate QR codes for AllCodeRelay app configuration


// Initialize or load saved configurations
session_start();
if (!isset($_SESSION['saved_configs'])) {
    $_SESSION['saved_configs'] = [];
}

// Check if form was submitted
$qrCodeData = '';
$showQR = false;

// Handle URL parameters for direct QR code generation
if (
    $_SERVER['REQUEST_METHOD'] === 'GET' &&
    (isset($_GET['webhook_url']) || isset($_GET['url']))
) {

    // Support both webhook_url and url as parameter names
    $webhookUrl = isset($_GET['webhook_url']) ?
        filter_var($_GET['webhook_url'], FILTER_SANITIZE_URL) :
        filter_var($_GET['url'], FILTER_SANITIZE_URL);

    $webhookTitle = isset($_GET['webhook_title']) || isset($_GET['title']) ?
        filter_var(isset($_GET['webhook_title']) ? $_GET['webhook_title'] : $_GET['title'], FILTER_SANITIZE_STRING) :
        '';

    // Process headers from URL if present
    $headers = [];
    if (isset($_GET['headers']) && !empty($_GET['headers'])) {
        try {
            $headersJson = $_GET['headers'];
            $decodedHeaders = json_decode($headersJson, true);
            if (is_array($decodedHeaders)) {
                $headers = $decodedHeaders;
            }
        } catch (Exception $e) {
            // Ignore invalid headers
        }
    }

    // Build the QR code data
    if (!empty($webhookUrl)) {
        $qrData = "allcoderelay://setwebhookurl?url=" . urlencode($webhookUrl);

        if (!empty($webhookTitle)) {
            $qrData .= "&title=" . urlencode($webhookTitle);
        }

        if (!empty($headers)) {
            $qrData .= "&headers=" . urlencode(json_encode($headers));
        }

        $qrCodeData = $qrData;
        $showQR = true;

        // Pre-fill the form with these values
        $loadedConfig = [
            'url' => $webhookUrl,
            'title' => $webhookTitle,
            'headers' => $headers
        ];
    }
}

// Handle save configuration
if (isset($_POST['save_config']) && !empty($_POST['config_name'])) {
    $configName = filter_input(INPUT_POST, 'config_name', FILTER_SANITIZE_STRING);
    $webhookUrl = filter_input(INPUT_POST, 'webhook_url', FILTER_SANITIZE_URL);
    $webhookTitle = filter_input(INPUT_POST, 'webhook_title', FILTER_SANITIZE_STRING);

    // Process headers
    $headers = [];
    if (!empty($_POST['header_keys']) && !empty($_POST['header_values'])) {
        $keys = $_POST['header_keys'];
        $values = $_POST['header_values'];

        for ($i = 0; $i < count($keys); $i++) {
            if (!empty($keys[$i]) && !empty($values[$i])) {
                $headers[$keys[$i]] = $values[$i];
            }
        }
    }

    // Save configuration
    $_SESSION['saved_configs'][$configName] = [
        'url' => $webhookUrl,
        'title' => $webhookTitle,
        'headers' => $headers,
        'timestamp' => time()
    ];
}

// Handle delete configuration
if (isset($_GET['delete_config']) && !empty($_GET['delete_config'])) {
    $configToDelete = $_GET['delete_config'];
    if (isset($_SESSION['saved_configs'][$configToDelete])) {
        unset($_SESSION['saved_configs'][$configToDelete]);
    }
    // Redirect to remove the GET parameter
    header('Location: ' . strtok($_SERVER['REQUEST_URI'], '?'));
    exit;
}

// Handle load configuration
$loadedConfig = null;
if (isset($_GET['load_config']) && !empty($_GET['load_config'])) {
    $configToLoad = $_GET['load_config'];
    if (isset($_SESSION['saved_configs'][$configToLoad])) {
        $loadedConfig = $_SESSION['saved_configs'][$configToLoad];
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !isset($_POST['save_config'])) {
    // Get form data
    $webhookUrl = filter_input(INPUT_POST, 'webhook_url', FILTER_SANITIZE_URL);
    $webhookTitle = filter_input(INPUT_POST, 'webhook_title', FILTER_SANITIZE_STRING);

    // Process headers
    $headers = [];
    if (!empty($_POST['header_keys']) && !empty($_POST['header_values'])) {
        $keys = $_POST['header_keys'];
        $values = $_POST['header_values'];

        for ($i = 0; $i < count($keys); $i++) {
            if (!empty($keys[$i]) && !empty($values[$i])) {
                $headers[$keys[$i]] = $values[$i];
            }
        }
    }

    // Build the QR code data
    if (!empty($webhookUrl)) {
        $qrData = "allcoderelay://setwebhookurl?url=" . urlencode($webhookUrl);

        if (!empty($webhookTitle)) {
            $qrData .= "&title=" . urlencode($webhookTitle);
        }

        if (!empty($headers)) {
            $qrData .= "&headers=" . urlencode(json_encode($headers));
        }

        $qrCodeData = $qrData;
        $showQR = true;

        // Keep the form values by setting loadedConfig
        $loadedConfig = [
            'url' => $webhookUrl,
            'title' => $webhookTitle,
            'headers' => $headers
        ];
    }
}
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AllCodeRelay Configuration</title>
<!-- Bootstrap CSS -->
<link rel="stylesheet" href="assets/bootstrap.min.css">

<!-- Bootstrap Icons -->
<link rel="stylesheet" href="assets/bootstrap-icons.css">

<!-- Your own stylesheet, if any -->
<!-- <link rel="stylesheet" href="style.css"> -->

    <style>
        body {
            padding-top: 20px;
            padding-bottom: 40px;
        }

        .header {
            margin-bottom: 30px;
        }

        .qr-container {
            text-align: center;
            margin: 30px 0;
        }

        #qrcode {
            display: inline-block;
            max-width: 100%;
            overflow: hidden;
        }

        #qrcode img {
            max-width: 100%;
            height: auto;
        }

        .config-list {
            max-height: 400px;
            overflow-y: auto;
        }

        .config-item {
            cursor: pointer;
        }

        .config-item:hover {
            background-color: #f8f9fa;
        }

        .timestamp {
            font-size: 0.8em;
            color: #6c757d;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header text-center">
            <h1><a href="https://grapph.com/allcoderelay/" target="_blank" rel="noopener noreferrer" style="text-decoration: none;" class="text-dark">AllCodeRelay</a> Configuration</h1>
            <p class="lead">Generate a QR code to configure your AllCodeRelay app</p>
        </div>

        <div class="row">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-body">
                        <form method="post" id="configForm">
                            <div class="mb-3">
                                <label for="webhook_url" class="form-label">Webhook URL (required)</label>
                                <input type="url" class="form-control" id="webhook_url" name="webhook_url" required
                                    placeholder="https://example.com/webhook" value="<?php echo $loadedConfig ? htmlspecialchars($loadedConfig['url']) : ''; ?>">
                            </div>

                            <div class="mb-3">
                                <label for="webhook_title" class="form-label">Webhook Title</label>
                                <input type="text" class="form-control" id="webhook_title" name="webhook_title"
                                    placeholder="My Webhook" value="<?php echo $loadedConfig ? htmlspecialchars($loadedConfig['title']) : ''; ?>">
                            </div>

                            <div class="mb-3">
                                <label class="form-label">Custom Headers</label>
                                <div id="headers-container">
                                    <?php if ($loadedConfig && !empty($loadedConfig['headers'])): ?>
                                        <?php foreach ($loadedConfig['headers'] as $key => $value): ?>
                                            <div class="row mb-2">
                                                <div class="col-5">
                                                    <input type="text" class="form-control" name="header_keys[]" placeholder="Key" value="<?php echo htmlspecialchars($key); ?>">
                                                </div>
                                                <div class="col-5">
                                                    <input type="text" class="form-control" name="header_values[]" placeholder="Value" value="<?php echo htmlspecialchars($value); ?>">
                                                </div>
                                                <div class="col-2">
                                                    <button type="button" class="btn btn-danger remove-header">Remove</button>
                                                </div>
                                            </div>
                                        <?php endforeach; ?>
                                    <?php else: ?>
                                        <div class="row mb-2">
                                            <div class="col-5">
                                                <input type="text" class="form-control" name="header_keys[]" placeholder="Key">
                                            </div>
                                            <div class="col-5">
                                                <input type="text" class="form-control" name="header_values[]" placeholder="Value">
                                            </div>
                                            <div class="col-2">
                                                <button type="button" class="btn btn-danger remove-header">Remove</button>
                                            </div>
                                        </div>
                                    <?php endif; ?>
                                </div>
                                <button type="button" class="btn btn-secondary" id="add-header">Add Header</button>
                            </div>

                            <div class="row">
                                <div class="col-md-6">
                                    <button type="submit" class="btn btn-primary w-100">Generate QR Code</button>
                                </div>
                                <div class="col-md-6">
                                    <div class="input-group">
                                        <input type="text" class="form-control" name="config_name" placeholder="Configuration name">
                                        <button type="submit" name="save_config" value="1" class="btn btn-success">Save</button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>

                <?php if ($showQR): ?>
                    <div class="qr-container mt-4">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">Scan this QR code with AllCodeRelay</h5>
                                <div id="qrcode"></div>
                                <div class="mt-3">
                                    <small class="text-muted">QR Code Data:</small>
                                    <pre class="mt-2"><?php echo htmlspecialchars($qrCodeData); ?></pre>

                                    <div class="mt-3">
                                        <button id="copyLinkBtn" class="btn btn-outline-primary btn-sm">
                                            <i class="bi bi-link-45deg"></i> Copy Shareable Link
                                        </button>
                                        <span id="copySuccess" class="text-success ms-2" style="display: none;">
                                            <i class="bi bi-check-circle"></i> Link copied!
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                <?php endif; ?>
            </div>

            <div class="col-md-4">
                <div class="card">
                    <div class="card-header">
                        <h5 class="mb-0">Saved Configurations</h5>
                    </div>
                    <div class="card-body config-list">
                        <?php if (empty($_SESSION['saved_configs'])): ?>
                            <p class="text-muted">No saved configurations yet.</p>
                        <?php else: ?>
                            <div class="list-group">
                                <?php foreach ($_SESSION['saved_configs'] as $name => $config): ?>
                                    <div class="list-group-item list-group-item-action config-item">
                                        <div class="d-flex w-100 justify-content-between">
                                            <h6 class="mb-1"><?php echo htmlspecialchars($name); ?></h6>
                                            <div>
                                                <a href="?load_config=<?php echo urlencode($name); ?>" class="btn btn-sm btn-outline-primary" title="Load"><i class="bi bi-arrow-clockwise"></i></a>
                                                <a href="?delete_config=<?php echo urlencode($name); ?>" class="btn btn-sm btn-outline-danger" title="Delete" onclick="return confirm('Are you sure you want to delete this configuration?');"><i class="bi bi-trash"></i></a>
                                            </div>
                                        </div>
                                        <p class="mb-1"><?php echo htmlspecialchars($config['url']); ?></p>
                                        <?php if (!empty($config['title'])): ?>
                                            <small><?php echo htmlspecialchars($config['title']); ?></small><br>
                                        <?php endif; ?>
                                        <small class="timestamp">
                                            <?php echo date('Y-m-d H:i', $config['timestamp']); ?>
                                        </small>
                                        <?php if (!empty($config['headers'])): ?>
                                            <div class="mt-1">
                                                <small class="text-muted">Headers: <?php echo count($config['headers']); ?></small>
                                            </div>
                                        <?php endif; ?>
                                    </div>
                                <?php endforeach; ?>
                            </div>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>

<!-- Bootstrap JS -->
<script src="assets/bootstrap.bundle.min.js" defer></script>

<!-- QRCode JS -->
<script src="assets/qrcode.min.js" defer></script>


    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Add header button
            document.getElementById('add-header').addEventListener('click', function() {
                const container = document.getElementById('headers-container');
                const row = document.createElement('div');
                row.className = 'row mb-2';
                row.innerHTML = `
                    <div class="col-5">
                        <input type="text" class="form-control" name="header_keys[]" placeholder="Key">
                    </div>
                    <div class="col-5">
                        <input type="text" class="form-control" name="header_values[]" placeholder="Value">
                    </div>
                    <div class="col-2">
                        <button type="button" class="btn btn-danger remove-header">Remove</button>
                    </div>
                `;
                container.appendChild(row);
            });

            // Remove header button
            document.addEventListener('click', function(e) {
                if (e.target.classList.contains('remove-header')) {
                    e.target.closest('.row').remove();
                }
            });

            <?php if ($showQR): ?>
                // Generate QR code
                new QRCode(document.getElementById("qrcode"), {
                    text: "<?php echo $qrCodeData; ?>",
                    width: 1024,
                    height: 1024,
                    colorDark: "#000000",
                    colorLight: "#ffffff",
                    correctLevel: QRCode.CorrectLevel.H
                });

                // Copy link functionality
                document.getElementById('copyLinkBtn').addEventListener('click', function() {
                    // Create the shareable URL
                    const currentUrl = new URL(window.location.href);
                    const baseUrl = currentUrl.origin + currentUrl.pathname;

                    // Get current form values
                    const webhookUrl = document.getElementById('webhook_url').value;
                    const webhookTitle = document.getElementById('webhook_title').value;

                    // Build headers object from form
                    const headers = {};
                    const headerKeys = document.querySelectorAll('input[name="header_keys[]"]');
                    const headerValues = document.querySelectorAll('input[name="header_values[]"]');

                    for (let i = 0; i < headerKeys.length; i++) {
                        if (headerKeys[i].value && headerValues[i].value) {
                            headers[headerKeys[i].value] = headerValues[i].value;
                        }
                    }

                    // Build the URL with parameters
                    let shareableUrl = `${baseUrl}?webhook_url=${encodeURIComponent(webhookUrl)}`;

                    if (webhookTitle) {
                        shareableUrl += `&webhook_title=${encodeURIComponent(webhookTitle)}`;
                    }

                    if (Object.keys(headers).length > 0) {
                        shareableUrl += `&headers=${encodeURIComponent(JSON.stringify(headers))}`;
                    }

                    // Copy to clipboard
                    navigator.clipboard.writeText(shareableUrl).then(function() {
                        const successMsg = document.getElementById('copySuccess');
                        successMsg.style.display = 'inline';
                        setTimeout(function() {
                            successMsg.style.display = 'none';
                        }, 3000);
                    });
                });
            <?php endif; ?>
        });
    </script>
    <br>
    <br>
    <br>
    <h3 class="text-center">
        <a href=readme.html>Readme / Documentation</a>
    </h3>
</body>

</html>
