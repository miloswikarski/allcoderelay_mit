<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AllCodeRelay - Universal Code Scanner with Webhook Integration</title>

    <!-- SEO Meta Tags -->
    <meta name="description" content="AllCodeRelay is a powerful universal code scanner app with webhook integration. Scan QR codes, barcodes, and NFC tags and relay data to your systems.">
    <meta name="keywords" content="code scanner, QR code, barcode, NFC, webhook, integration, mobile app">
    <meta name="author" content="Grapph">

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://grapph.com/allcoderelay/">
    <meta property="og:title" content="AllCodeRelay - Universal Code Scanner with Webhook Integration">
    <meta property="og:description" content="Scan QR codes, barcodes, and NFC tags and relay data to your systems with this powerful mobile app.">
    <meta property="og:image" content="https://grapph.com/allcoderelay/images/acr.jpg">

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image">
    <meta property="twitter:url" content="https://grapph.com/allcoderelay/">
    <meta property="twitter:title" content="AllCodeRelay - Universal Code Scanner with Webhook Integration">
    <meta property="twitter:description" content="Scan QR codes, barcodes, and NFC tags and relay data to your systems with this powerful mobile app.">
    <meta property="twitter:image" content="https://grapph.com/allcoderelay/images/acr.jpg">

    <!-- Favicon -->
    <link rel="icon" href="favicon.ico">
    <link rel="apple-touch-icon" href="icon.png">

    <!-- Styles -->
    <style>
        .store-badges {
            display: flex;
            align-items: center;
            gap: 18px;
            margin-bottom: 18px;
            margin-top: 8px;
        }

        .store-badges a {
            display: inline-block;
            line-height: 0;
        }

        .store-badges img {
            height: 60px;
            width: auto;
            max-width: 220px;
            box-sizing: border-box;
            vertical-align: middle;
            border-radius: 6px;
            box-shadow: 0 2px 8px rgba(44, 62, 80, 0.08);
            padding: 0;
        }

        @media (max-width: 600px) {
            .store-badges {
                flex-direction: column;
                gap: 12px;
            }

            .store-badges img {
                height: 48px;
                max-width: 90vw;
            }
        }

        :root {
            --primary-color: #3498db;
            --secondary-color: #2c3e50;
            --accent-color: #e74c3c;
            --light-color: #ecf0f1;
            --dark-color: #34495e;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            color: #333;
            background-color: #f9f9f9;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
        }

        header {
            background-color: var(--secondary-color);
            color: white;
            padding: 1rem 0;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }

        .header-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .logo {
            font-size: 1.8rem;
            font-weight: bold;
        }

        .hero {
            background: linear-gradient(135deg, var(--secondary-color), var(--primary-color));
            color: white;
            padding: 4rem 0;
            text-align: center;
        }

        .hero-content {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: center;
            gap: 2rem;
        }

        .hero-text {
            flex: 1;
            min-width: 300px;
            max-width: 600px;
            text-align: left;
        }

        .hero-image {
            flex: 1;
            min-width: 300px;
            max-width: 400px;
        }

        .hero h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
        }

        .hero p {
            font-size: 1.2rem;
            margin: 0 0 2rem;
        }

        .mobile-store-badge {
            max-width: 120px;
            margin-right: 10px;
        }

        .cta-button {
            display: inline-block;
            background-color: var(--accent-color);
            color: white;
            padding: 12px 30px;
            border-radius: 30px;
            text-decoration: none;
            font-weight: bold;
            transition: background-color 0.3s;
            margin: 10px 0;
        }

        .cta-button:hover {
            background-color: #c0392b;
        }

        .features {
            padding: 4rem 0;
            background-color: white;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-top: 2rem;
        }

        .feature-card {
            background-color: var(--light-color);
            border-radius: 8px;
            padding: 1.5rem;
            box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
            transition: transform 0.3s;
        }

        .feature-card:hover {
            transform: translateY(-5px);
        }

        .feature-card h3 {
            color: var(--secondary-color);
            margin-top: 0;
        }

        .webhook-section {
            background-color: var(--light-color);
            padding: 4rem 0;
        }

        .webhook-content {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 2rem;
        }

        .webhook-text {
            flex: 1;
            min-width: 300px;
        }

        .webhook-image {
            flex: 1;
            min-width: 300px;
            text-align: center;
        }

        .code-block {
            background-color: var(--dark-color);
            color: white;
            padding: 1rem;
            border-radius: 5px;
            overflow-x: auto;
            font-family: monospace;
        }

        footer {
            background-color: var(--secondary-color);
            color: white;
            padding: 2rem 0;
            text-align: center;
        }

        .footer-links a {
            color: var(--light-color);
            margin: 0 10px;
            text-decoration: none;
        }

        .footer-links a:hover {
            text-decoration: underline;
        }

        @media (max-width: 768px) {
            .header-content {
                flex-direction: column;
                text-align: center;
            }

            .hero-content {
                flex-direction: column-reverse;
                text-align: center;
            }

            .hero-text {
                text-align: center;
            }

            .hero h1 {
                font-size: 2rem;
            }

            .hero p {
                font-size: 1rem;
            }
        }
    </style>
</head>

<body>
    <header>
        <div class="container header-content">
            <div class="logo">AllCodeRelay</div>
            <nav>
                <a href="#features" class="cta-button">Features</a>
                <a href="#webhook" class="cta-button">Webhook Integration</a>
                <a href="gallery/" class="cta-button">Webhook Gallery</a>
            </nav>
        </div>
    </header>

    <section class="hero">
        <div class="container">
            <div class="hero-content">
                <div class="hero-text">
                    <h1>Universal Code Scanner with Webhook Integration</h1>
                    <p>Scan QR codes, barcodes, or NFC tags and relay the data to your configured webhook endpoints. Perfect for inventory management, event check-ins, access control, and more.</p>
                    <div class="store-badges">
                        <a href="http://play.google.com/store/apps/details?id=com.grapph.allcoderelay">
                            <img src="images/GetItOnGooglePlay_Badge_Web_color_English.png" alt="Get it on Google Play" class="mobile-store-badge">
                        </a>
                        <a href="mailto:allcoderelay@grapph.com?subject=Pre-order%20AllCodeRelay%20for%20iOS&body=I%20am%20interested%20in%20pre-ordering%20AllCodeRelay%20for%20iOS.">
                            <img src="images/Pre-order_on_the_App_Store_Badge_US-UK_RGB_blk_121217.svg" alt="Pre-order on the App Store" class="mobile-store-badge">
                        </a>
                    </div>
                </div>
                <div class="hero-image">
                    <img src="images/acr.jpg" alt="AllCodeRelay App" style="max-width: 100%; height: auto; border-radius: 10px; box-shadow: 0 5px 15px rgba(0,0,0,0.2);">
                </div>
            </div>
        </div>
    </section>

    <section id="features" class="features">
        <div class="container">
            <h2>Key Features</h2>
            <div class="features-grid">
                <div class="feature-card">
                    <h3>QR Code & Barcode Scanning</h3>
                    <p>Quickly scan all standard QR codes and barcodes with high accuracy and speed.</p>
                </div>
                <div class="feature-card">
                    <h3>NFC Tag Reading</h3>
                    <p>Read NFC tags and relay their data to your systems instantly.</p>
                </div>
                <div class="feature-card">
                    <h3>Webhook Integration</h3>
                    <p>Send scanned data directly to your configured webhook endpoints via HTTP POST requests.</p>
                </div>
                <div class="feature-card">
                    <h3>Secure Storage</h3>
                    <p>All webhook URLs and credentials are securely stored on your device.</p>
                </div>
                <div class="feature-card">
                    <h3>Customizable Settings</h3>
                    <p>Configure the app to match your specific workflow and requirements.</p>
                </div>
                <div class="feature-card">
                    <h3>Enterprise Ready</h3>
                    <p>Built for scale with enterprise integration options available.</p>
                </div>
            </div>
        </div>
    </section>

    <section id="webhook" class="webhook-section">
        <div class="container">
            <h2>Powerful Webhook Integration</h2>
            <div class="webhook-content">
                <div class="webhook-text">
                    <p>AllCodeRelay sends scanned data to your configured webhook endpoint via HTTP POST requests. This allows for seamless integration with your existing systems.</p>
                    <h3>POST Request Format</h3>
                    <div class="code-block">
                        {<br>
                        &nbsp;&nbsp;"code": "SCANNED_CODE_VALUE"<br>
                        }
                    </div>
                    <h3>Expected Response</h3>
                    <div class="code-block">
                        {<br>
                        &nbsp;&nbsp;"code": "SCANNED_CODE_TYPE",<br>
                        &nbsp;&nbsp;"codevalue": "PROCESSED_VALUE"<br>
                        }
                    </div>
                    <p>Use our <a href="webhook_config.php">webhook configuration tool</a> to easily generate QR codes for app configuration.</p>
                    <p><strong>🚀 Explore our <a href="gallery/" style="color: var(--accent-color); text-decoration: none; font-weight: bold;">Webhook Gallery</a></strong> - Discover ready-to-use webhook examples for inventory management, event check-ins, smart home automation, expense tracking, and more!</p>
                </div>
                <div class="webhook-image">
                    <img src="images/webhook-diagram.png" alt="Webhook Integration Diagram" style="max-width: 100%; height: auto; border-radius: 8px; box-shadow: 0 3px 10px rgba(0,0,0,0.1);">
                </div>
            </div>
        </div>
    </section>

    <footer>
        <div class="container">
            <p>&copy; <?php echo date('Y'); ?> AllCodeRelay</p>
            <div class="footer-links">
                <a href="privacy_policy.html">Privacy Policy</a>
                <a href="https://github.com/miloswikarski/allcoderelay_mit">Source Code</a>
                <a href="https://github.com/miloswikarski/allcoderelay_mit/issues">Report a Bug</a>
                <a href="https://github.com/miloswikarski/allcoderelay_mit/blob/main/README.md">Documentation</a>
                <a href="mailto:allcoderelay@grapph.com">Contact Us</a>
            </div>
        </div>
    </footer>
</body>

</html>