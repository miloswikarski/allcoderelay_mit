import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version =
              snapshot.hasData
                  ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                  : 'Loading...';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // logo
                      const Image(
                        image: AssetImage('assets/images/logo.png'),
                        width: 64,
                      ),
                      const SizedBox(height: 16),
                      // app name
                      const Text(
                        'AllCodeRelay',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // version
                      const SizedBox(height: 8),
                      Text(
                        'Version $version',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Features'),
                      subtitle: Text(
                        '• QR Code and Barcode scanning\n'
                        '• NFC tag reading\n'
                        '• Webhook integration',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Documentation'),
                      subtitle: const Text('View online documentation'),
                      onTap: () {
                        final docUri = Uri.parse(
                          'https://grapph.com/allcoderelay/readme.html',
                        );
                        launchUrl(docUri, mode: LaunchMode.platformDefault);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      title: Text('Enterprise Integration'),
                      subtitle: Text(
                        'AllCodeRelay can be integrated with your existing systems. '
                        'Contact us for custom integration solutions and enterprise support.',
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Contact Us'),
                      subtitle: const Text('allcoderelay@grapph.com'),
                      onTap: () {
                        final emailUri = Uri(
                          scheme: 'mailto',
                          path: 'allcoderelay@grapph.com',
                          queryParameters: {
                            'subject': 'AllCodeRelay Integration Inquiry',
                          },
                        );
                        launchUrl(emailUri);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  '© ${DateTime.now().year} AllCodeRelay',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
