import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:developer' as developer;
import 'dart:convert' show utf8;
import '../../services/nfc_platform_service.dart';

// Events
abstract class NfcEvent {}

class StartNfcScan extends NfcEvent {}

class StopNfcScan extends NfcEvent {}

class NfcTagRead extends NfcEvent {
  final String data;
  NfcTagRead(this.data);
}

// States
abstract class NfcState {}

class NfcInitial extends NfcState {}

class NfcScanning extends NfcState {}

class NfcSuccess extends NfcState {
  final String data;
  NfcSuccess(this.data);
}

class NfcError extends NfcState {
  final String message;
  NfcError(this.message);
}

class NfcBloc extends Bloc<NfcEvent, NfcState> {
  final NfcPlatformService _nfcService = NfcPlatformService();

  NfcBloc() : super(NfcInitial()) {
    on<StartNfcScan>(_onStartNfcScan);
    on<StopNfcScan>(_onStopNfcScan);
    on<NfcTagRead>(_onNfcTagRead);
  }

  String _sanitizeText(String text) {
    try {
      // Convert to single line and trim
      final singleLine = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .join(' | ');

      // Properly decode UTF-8
      final bytes = utf8.encode(singleLine);
      final decodedText = utf8.decode(bytes, allowMalformed: true);

      developer.log('Sanitized text: $decodedText', name: 'NfcBloc');
      return decodedText;
    } catch (e) {
      developer.log('Error sanitizing text: $e', name: 'NfcBloc');
      return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }

  Future<void> _onStartNfcScan(
    StartNfcScan event,
    Emitter<NfcState> emit,
  ) async {
    try {
      developer.log('Starting NFC scan...', name: 'NfcBloc');

      final isAvailable = await _nfcService.isAvailable();
      developer.log('NFC availability: $isAvailable', name: 'NfcBloc');

      if (!isAvailable) {
        emit(NfcError('NFC is not available on this device'));
        return;
      }

      emit(NfcScanning());

      await _nfcService.startSession(
        onTagRead: (String tagData) {
          final sanitizedData = _sanitizeText(tagData);
          developer.log('Sanitized data: $sanitizedData', name: 'NfcBloc');
          add(NfcTagRead(sanitizedData));
        },
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error in NFC scan: $e\n$stackTrace',
        name: 'NfcBloc',
        error: e,
        stackTrace: stackTrace,
      );
      emit(NfcError(e.toString()));
    }
  }

  Future<void> _onStopNfcScan(StopNfcScan event, Emitter<NfcState> emit) async {
    try {
      developer.log('Stopping NFC scan...', name: 'NfcBloc');
      await _nfcService.stopSession();
      emit(NfcInitial());
      developer.log('NFC scan stopped', name: 'NfcBloc');
    } catch (e, stackTrace) {
      developer.log(
        'Error stopping NFC scan: $e\n$stackTrace',
        name: 'NfcBloc',
        error: e,
        stackTrace: stackTrace,
      );
      emit(NfcError(e.toString()));
    }
  }

  void _onNfcTagRead(NfcTagRead event, Emitter<NfcState> emit) {
    developer.log(
      'Emitting NFC success with data: ${event.data}',
      name: 'NfcBloc',
    );
    emit(NfcSuccess(event.data));
  }
}
