import 'dart:convert';

class ScanResult {
  final int? id;
  final String code;
  String codeValue;
  final DateTime timestamp;

  ScanResult({
    this.id,
    required this.code,
    required this.codeValue,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'code_value':
          codeValue, // utf8.encode(codeValue).toString(), // Encode to UTF-8
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    // Decode the stored UTF-8 bytes
    String decodedValue;
    try {
      final String storedValue = map['code_value'];
      if (storedValue.startsWith('[') && storedValue.endsWith(']')) {
        // Convert string representation of byte array back to List<int>
        final bytes =
            storedValue
                .substring(1, storedValue.length - 1)
                .split(',')
                .map((s) => int.parse(s.trim()))
                .toList();
        decodedValue = utf8.decode(bytes, allowMalformed: true);
      } else {
        decodedValue = storedValue;
      }
    } catch (e) {
      decodedValue = map['code_value'];
    }

    return ScanResult(
      id: map['id'],
      code: map['code'],
      codeValue: decodedValue,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  ScanResult copyWith({
    int? id,
    String? code,
    String? codeValue,
    DateTime? timestamp,
  }) {
    return ScanResult(
      id: id ?? this.id,
      code: code ?? this.code,
      codeValue: codeValue ?? this.codeValue,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
