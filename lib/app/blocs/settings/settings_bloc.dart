import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Enums
enum PreferredScanMode { both, barcodeOnly, nfcOnly }

// Events
abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

class UpdateWebhookUrl extends SettingsEvent {
  final String url;
  UpdateWebhookUrl(this.url);
}

class UpdateWebhookUrlFromQr extends SettingsEvent {
  final String code;
  UpdateWebhookUrlFromQr(this.code);
}

class ToggleDarkMode extends SettingsEvent {}

class ToggleContinuousScanning extends SettingsEvent {}

class UpdateScanDelay extends SettingsEvent {
  final double delay;
  UpdateScanDelay(this.delay);
}

class ToggleBeep extends SettingsEvent {}

class UpdateWebhookTitle extends SettingsEvent {
  final String title;
  UpdateWebhookTitle(this.title);
}

class UpdateWebhookHeaders extends SettingsEvent {
  final Map<String, String> headers;
  UpdateWebhookHeaders(this.headers);
}

class AddWebhookHeader extends SettingsEvent {
  final String key;
  final String value;
  AddWebhookHeader(this.key, this.value);
}

class RemoveWebhookHeader extends SettingsEvent {
  final String key;
  RemoveWebhookHeader(this.key);
}

class ToggleClipboard extends SettingsEvent {}

class UpdatePreferredScanMode extends SettingsEvent {
  final PreferredScanMode mode;
  UpdatePreferredScanMode(this.mode);
}

// State
class SettingsState {
  final String webhookUrl;
  final String webhookTitle;
  final Map<String, String> webhookHeaders;
  final bool isDarkMode;
  final bool isLoading;
  final bool isContinuousScanning;
  final double scanDelay;
  final bool beepEnabled;
  final bool copyToClipboard;
  final PreferredScanMode preferredScanMode;

  SettingsState({
    this.webhookUrl = 'https://n8n.grapph.com/webhook/allcoderelay',
    this.webhookTitle = 'Default Webhook',
    this.webhookHeaders = const {'Content-Type': 'application/json'},
    this.isDarkMode = false,
    this.isLoading = false,
    this.isContinuousScanning = false,
    this.scanDelay = 2.0,
    this.beepEnabled = true,
    this.copyToClipboard = false,
    this.preferredScanMode = PreferredScanMode.both,
  });

  SettingsState copyWith({
    String? webhookUrl,
    String? webhookTitle,
    Map<String, String>? webhookHeaders,
    bool? isDarkMode,
    bool? isLoading,
    bool? isContinuousScanning,
    double? scanDelay,
    bool? beepEnabled,
    bool? copyToClipboard,
    PreferredScanMode? preferredScanMode,
  }) {
    return SettingsState(
      webhookUrl: webhookUrl ?? this.webhookUrl,
      webhookTitle: webhookTitle ?? this.webhookTitle,
      webhookHeaders: webhookHeaders ?? this.webhookHeaders,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isLoading: isLoading ?? this.isLoading,
      isContinuousScanning: isContinuousScanning ?? this.isContinuousScanning,
      scanDelay: scanDelay ?? this.scanDelay,
      beepEnabled: beepEnabled ?? this.beepEnabled,
      copyToClipboard: copyToClipboard ?? this.copyToClipboard,
      preferredScanMode: preferredScanMode ?? this.preferredScanMode,
    );
  }
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final _storage = const FlutterSecureStorage();

  SettingsBloc() : super(SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateWebhookUrl>(_onUpdateWebhookUrl);
    on<UpdateWebhookUrlFromQr>(_onUpdateWebhookUrlFromQr);
    on<UpdateWebhookTitle>(_onUpdateWebhookTitle);
    on<UpdateWebhookHeaders>(_onUpdateWebhookHeaders);
    on<AddWebhookHeader>(_onAddWebhookHeader);
    on<RemoveWebhookHeader>(_onRemoveWebhookHeader);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ToggleContinuousScanning>(_onToggleContinuousScanning);
    on<UpdateScanDelay>(_onUpdateScanDelay);
    on<ToggleBeep>(_onToggleBeep);
    on<ToggleClipboard>(_onToggleClipboard);
    on<UpdatePreferredScanMode>(_onUpdatePreferredScanMode);

    // Load settings when bloc is created
    add(LoadSettings());
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final url = await _storage.read(key: 'webhook_url');
      final title = await _storage.read(key: 'webhook_title');
      final headersJson = await _storage.read(key: 'webhook_headers');
      final isDarkMode = await _storage.read(key: 'dark_mode');
      final isContinuousScanning = await _storage.read(
        key: 'continuous_scanning',
      );
      final scanDelay = await _storage.read(key: 'scan_delay');
      final beepEnabled = await _storage.read(key: 'beep_enabled');
      final copyToClipboard = await _storage.read(key: 'copy_to_clipboard');
      final preferredScanModeStr = await _storage.read(
        key: 'preferred_scan_mode',
      );

      // Parse headers from JSON
      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (headersJson != null) {
        try {
          final Map<String, dynamic> parsedHeaders = jsonDecode(headersJson);
          headers = parsedHeaders.map(
            (key, value) => MapEntry(key, value.toString()),
          );
        } catch (e) {
          // Use default headers if parsing fails
        }
      }

      // Parse preferred scan mode
      PreferredScanMode preferredScanMode = PreferredScanMode.both;
      if (preferredScanModeStr != null) {
        switch (preferredScanModeStr) {
          case 'both':
            preferredScanMode = PreferredScanMode.both;
            break;
          case 'barcodeOnly':
            preferredScanMode = PreferredScanMode.barcodeOnly;
            break;
          case 'nfcOnly':
            preferredScanMode = PreferredScanMode.nfcOnly;
            break;
        }
      }

      emit(
        state.copyWith(
          webhookUrl: url ?? state.webhookUrl,
          webhookTitle: title ?? state.webhookTitle,
          webhookHeaders: headers,
          isDarkMode: isDarkMode == 'true',
          isContinuousScanning: isContinuousScanning == 'true',
          scanDelay: scanDelay != null
              ? double.parse(scanDelay)
              : state.scanDelay,
          beepEnabled: beepEnabled == null ? true : beepEnabled == 'true',
          copyToClipboard: copyToClipboard == 'true',
          preferredScanMode: preferredScanMode,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onUpdateWebhookUrl(
    UpdateWebhookUrl event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.write(key: 'webhook_url', value: event.url);
      emit(state.copyWith(webhookUrl: event.url));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onUpdateWebhookUrlFromQr(
    UpdateWebhookUrlFromQr event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final uri = Uri.parse(event.code);
      if (uri.scheme == 'allcoderelay' &&
          uri.host == 'setwebhookurl' &&
          uri.queryParameters.containsKey('url')) {
        final newUrl = uri.queryParameters['url']!;
        await _storage.write(key: 'webhook_url', value: newUrl);

        // Update title if provided in QR code
        if (uri.queryParameters.containsKey('title')) {
          final newTitle = uri.queryParameters['title']!;
          await _storage.write(key: 'webhook_title', value: newTitle);

          // Update state with both URL and title
          emit(state.copyWith(webhookUrl: newUrl, webhookTitle: newTitle));
        } else {
          // Update only URL
          emit(state.copyWith(webhookUrl: newUrl));
        }

        // Update headers if provided in QR code
        if (uri.queryParameters.containsKey('headers')) {
          try {
            final headersJson = uri.queryParameters['headers']!;
            final Map<String, dynamic> parsedHeaders = jsonDecode(headersJson);
            final headers = parsedHeaders.map(
              (key, value) => MapEntry(key, value.toString()),
            );

            final headersJsonToStore = jsonEncode(headers);
            await _storage.write(
              key: 'webhook_headers',
              value: headersJsonToStore,
            );

            // Update state with headers
            emit(state.copyWith(webhookHeaders: headers));
          } catch (e) {
            // Ignore header parsing errors
          }
        }
      }
    } catch (e) {
      // Handle error - invalid URL format
    }
  }

  Future<void> _onToggleDarkMode(
    ToggleDarkMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final newDarkMode = !state.isDarkMode;
      await _storage.write(key: 'dark_mode', value: newDarkMode.toString());
      emit(state.copyWith(isDarkMode: newDarkMode));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onToggleContinuousScanning(
    ToggleContinuousScanning event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final newValue = !state.isContinuousScanning;
      await _storage.write(
        key: 'continuous_scanning',
        value: newValue.toString(),
      );
      emit(state.copyWith(isContinuousScanning: newValue));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onUpdateScanDelay(
    UpdateScanDelay event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.write(key: 'scan_delay', value: event.delay.toString());
      emit(state.copyWith(scanDelay: event.delay));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onToggleBeep(
    ToggleBeep event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final newValue = !state.beepEnabled;
      await _storage.write(key: 'beep_enabled', value: newValue.toString());
      emit(state.copyWith(beepEnabled: newValue));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onUpdateWebhookTitle(
    UpdateWebhookTitle event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.write(key: 'webhook_title', value: event.title);
      emit(state.copyWith(webhookTitle: event.title));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onUpdateWebhookHeaders(
    UpdateWebhookHeaders event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final headersJson = jsonEncode(event.headers);
      await _storage.write(key: 'webhook_headers', value: headersJson);
      emit(state.copyWith(webhookHeaders: event.headers));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onAddWebhookHeader(
    AddWebhookHeader event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final updatedHeaders = Map<String, String>.from(state.webhookHeaders);
      updatedHeaders[event.key] = event.value;

      final headersJson = jsonEncode(updatedHeaders);
      await _storage.write(key: 'webhook_headers', value: headersJson);

      emit(state.copyWith(webhookHeaders: updatedHeaders));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onRemoveWebhookHeader(
    RemoveWebhookHeader event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final updatedHeaders = Map<String, String>.from(state.webhookHeaders);
      updatedHeaders.remove(event.key);

      final headersJson = jsonEncode(updatedHeaders);
      await _storage.write(key: 'webhook_headers', value: headersJson);

      emit(state.copyWith(webhookHeaders: updatedHeaders));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onToggleClipboard(
    ToggleClipboard event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await _storage.write(
        key: 'copy_to_clipboard',
        value: (!state.copyToClipboard).toString(),
      );
      emit(state.copyWith(copyToClipboard: !state.copyToClipboard));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _onUpdatePreferredScanMode(
    UpdatePreferredScanMode event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      String modeStr;
      switch (event.mode) {
        case PreferredScanMode.both:
          modeStr = 'both';
          break;
        case PreferredScanMode.barcodeOnly:
          modeStr = 'barcodeOnly';
          break;
        case PreferredScanMode.nfcOnly:
          modeStr = 'nfcOnly';
          break;
      }
      await _storage.write(key: 'preferred_scan_mode', value: modeStr);
      emit(state.copyWith(preferredScanMode: event.mode));
    } catch (e) {
      // Handle error
    }
  }
}
