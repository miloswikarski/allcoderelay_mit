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
        if (response.body.isNotEmpty) {
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
      );
      await _db.create(scan);
      final scans = await _db.getAllScans();
      await Future.delayed(const Duration(seconds: 2));
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
