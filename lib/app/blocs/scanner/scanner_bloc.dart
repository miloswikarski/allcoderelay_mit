import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/scan_result.dart';
import '../../services/database_service.dart';
import '../settings/settings_bloc.dart';

// Events
abstract class ScannerEvent {}

class ScanCode extends ScannerEvent {
  final String code;
  ScanCode(this.code);
}

class RetryWebhook extends ScannerEvent {
  final ScanResult scan;
  RetryWebhook(this.scan);
}

class LoadScans extends ScannerEvent {}

class UpdateScan extends ScannerEvent {
  final ScanResult scan;
  UpdateScan(this.scan);
}

class DeleteScan extends ScannerEvent {
  final int id;
  DeleteScan(this.id);
}

class DeleteAllScans extends ScannerEvent {}

// States
abstract class ScannerState {}

class ScannerInitial extends ScannerState {}

class ScannerLoading extends ScannerState {}

class ScannerSuccess extends ScannerState {
  final List<ScanResult> scans;
  ScannerSuccess(this.scans);
}

class ScannerError extends ScannerState {
  final String message;
  ScannerError(this.message);
}

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final DatabaseService _db = DatabaseService.instance;
  final SettingsBloc _settingsBloc;

  ScannerBloc({required SettingsBloc settingsBloc})
    : _settingsBloc = settingsBloc,
      super(ScannerInitial()) {
    on<ScanCode>(_onScanCode);
    on<RetryWebhook>(_onRetryWebhook);
    on<LoadScans>(_onLoadScans);
    on<UpdateScan>(_onUpdateScan);
    on<DeleteScan>(_onDeleteScan);
    on<DeleteAllScans>(_onDeleteAllScans);
  }

  Future<void> _onScanCode(ScanCode event, Emitter<ScannerState> emit) async {
    emit(ScannerLoading());
    try {
      final webhookUrl = _settingsBloc.state.webhookUrl;
      final webhookHeaders = Map<String, String>.from(
        _settingsBloc.state.webhookHeaders,
      );

      // Add the Firebase token if it's not already in the headers
      // if (!webhookHeaders.containsKey('X-Firebase-Token')) {
      //   final token = "MyFBToken";
      //   if (token != null && token.isNotEmpty) {
      //     webhookHeaders['X-Firebase-Token'] = token;
      //   }
      // }

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: webhookHeaders,
        body: jsonEncode({'code': event.code}),
      );

      if (response.statusCode == 200) {
        // Handle response - some webhooks (like Home Assistant) return 200 without JSON
        String codeValue = '';
        String code = event.code;

        // Try to parse JSON if response body is not empty
        if (response.bodyBytes.isNotEmpty) {
          try {
            final responseData = jsonDecode(utf8.decode(response.bodyBytes));
            if (responseData is Map) {
              code = responseData['code'] ?? event.code;
              codeValue = responseData['codevalue'] ?? '';
            }
          } catch (jsonError) {
            // If JSON parsing fails, just use the scanned code with empty codeValue
            // This is fine for webhooks that don't return JSON (like Home Assistant)
          }
        }

        final scan = ScanResult(
          code: code,
          codeValue: codeValue,
          timestamp: DateTime.now(),
          webhookError: null,
        );
        await _db.create(scan);
        final scans = await _db.getAllScans();
        emit(ScannerSuccess(scans));
      } else {
        // Server error, save locally like network error
        emit(ScannerError('Server error: ${response.statusCode}'));
        final scan = ScanResult(
          code: event.code,
          codeValue: '',
          timestamp: DateTime.now(),
          webhookError: 'Server error: ${response.statusCode}',
          lastWebhookAttempt: DateTime.now(),
        );
        await _db.create(scan);
        final scans = await _db.getAllScans();
        await Future.delayed(const Duration(seconds: 2));
        emit(ScannerSuccess(scans));
      }
    } catch (e) {
      // network error, save locally
      emit(ScannerError(e.toString()));
      final scan = ScanResult(
        code: event.code,
        codeValue: '',
        timestamp: DateTime.now(),
        webhookError: e.toString(),
        lastWebhookAttempt: DateTime.now(),
      );
      await _db.create(scan);
      final scans = await _db.getAllScans();
      await Future.delayed(const Duration(seconds: 2));
      emit(ScannerSuccess(scans));
    }
  }

  Future<void> _onRetryWebhook(
    RetryWebhook event,
    Emitter<ScannerState> emit,
  ) async {
    debugPrint('🔄 [RetryWebhook] Starting webhook retry for code: ${event.scan.code}');
    try {
      final webhookUrl = _settingsBloc.state.webhookUrl;
      final webhookHeaders = Map<String, String>.from(
        _settingsBloc.state.webhookHeaders,
      );

      debugPrint('🔄 [RetryWebhook] Sending POST to: $webhookUrl');
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: webhookHeaders,
        body: jsonEncode({'code': event.scan.code}),
      );

      debugPrint('🔄 [RetryWebhook] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Webhook successful, clear the error
        debugPrint('✓ [RetryWebhook] Success! Clearing error');
        String codeValue = event.scan.codeValue;

        // Try to parse JSON if response body is not empty
        if (response.bodyBytes.isNotEmpty) {
          try {
            final responseData = jsonDecode(utf8.decode(response.bodyBytes));
            if (responseData is Map) {
              codeValue = responseData['codevalue'] ?? event.scan.codeValue;
            }
          } catch (jsonError) {
            // Keep existing codeValue
          }
        }

        final updatedScan = event.scan.copyWith(
          codeValue: codeValue,
          clearWebhookError: true,
        );
        await _db.update(updatedScan);
        final scans = await _db.getAllScans();
        debugPrint('✓ [RetryWebhook] Emitting ScannerSuccess');
        emit(ScannerSuccess(scans));
      } else {
        // Still failing, update error
        debugPrint('✗ [RetryWebhook] Server error: ${response.statusCode}');
        final updatedScan = event.scan.copyWith(
          webhookError: 'Server error: ${response.statusCode}',
          lastWebhookAttempt: DateTime.now(),
        );
        await _db.update(updatedScan);
        final scans = await _db.getAllScans();
        debugPrint('✗ [RetryWebhook] Emitting ScannerSuccess with error');
        emit(ScannerSuccess(scans));
      }
    } catch (e) {
      // Retry failed, update error
      debugPrint('✗ [RetryWebhook] Exception: $e');
      final updatedScan = event.scan.copyWith(
        webhookError: e.toString(),
        lastWebhookAttempt: DateTime.now(),
      );
      await _db.update(updatedScan);
      final scans = await _db.getAllScans();
      debugPrint('✗ [RetryWebhook] Emitting ScannerSuccess with exception error');
      emit(ScannerSuccess(scans));
    }
  }

  Future<void> _onLoadScans(LoadScans event, Emitter<ScannerState> emit) async {
    emit(ScannerLoading());
    try {
      final scans = await _db.getAllScans();
      emit(ScannerSuccess(scans));
    } catch (e) {
      emit(ScannerError(e.toString()));
    }
  }

  Future<void> _onUpdateScan(
    UpdateScan event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      await _db.update(event.scan);
      final scans = await _db.getAllScans();
      emit(ScannerSuccess(scans));
    } catch (e) {
      emit(ScannerError(e.toString()));
    }
  }

  Future<void> _onDeleteScan(
    DeleteScan event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      await _db.delete(event.id);
      final scans = await _db.getAllScans();
      emit(ScannerSuccess(scans));
    } catch (e) {
      emit(ScannerError(e.toString()));
    }
  }

  Future<void> _onDeleteAllScans(
    DeleteAllScans event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      await _db.deleteAll();
      emit(ScannerSuccess([]));
    } catch (e) {
      emit(ScannerError(e.toString()));
    }
  }
}
