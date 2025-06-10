import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'routes/routes.dart';
import 'theme/theme.dart';
import 'blocs/settings/settings_bloc.dart';
import 'blocs/scanner/scanner_bloc.dart';
import 'blocs/nfc/nfc_bloc.dart';
import 'services/deeplink_service.dart';
import 'dart:convert';

class AllCodeRelayApp extends StatefulWidget {
  const AllCodeRelayApp({super.key});

  @override
  State<AllCodeRelayApp> createState() => _AllCodeRelayAppState();
}

class _AllCodeRelayAppState extends State<AllCodeRelayApp> {
  late DeepLinkService _deepLinkService;
  final SettingsBloc _settingsBloc = SettingsBloc();

  @override
  void initState() {
    super.initState();
    _deepLinkService = DeepLinkService(
      onDeepLinkReceived: (params) => _handleDeepLink(params, _settingsBloc),
    );
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    await _deepLinkService.initUniLinks();
  }

  void _handleDeepLink(Map<String, String> params, SettingsBloc settingsBloc) {
    if (params.containsKey('url')) {
      final url = params['url']!;
      final title = params['title'] ?? 'Webhook from DeepLink';

      // Update webhook URL and title
      settingsBloc.add(UpdateWebhookUrl(url));
      settingsBloc.add(UpdateWebhookTitle(title));

      // Update headers if provided
      if (params.containsKey('headers')) {
        try {
          final headersJson = params['headers']!;
          final Map<String, dynamic> parsedHeaders = jsonDecode(headersJson);
          final headers = parsedHeaders.map(
            (key, value) => MapEntry(key, value.toString()),
          );
          settingsBloc.add(UpdateWebhookHeaders(headers));
        } catch (e) {
          debugPrint('Error parsing headers from deep link: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    _settingsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: _settingsBloc),
        BlocProvider(
          create: (context) => ScannerBloc(settingsBloc: _settingsBloc),
        ),
        BlocProvider(create: (context) => NfcBloc()),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        bloc: _settingsBloc,
        builder: (context, state) {
          return MaterialApp.router(
            title: 'AllCodeRelay',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
