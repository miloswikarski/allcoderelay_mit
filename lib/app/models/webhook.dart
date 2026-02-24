class Webhook {
  final int? id;
  final String title;
  final String url;
  final Map<String, String> headers;
  final int timestamp;

  Webhook({
    this.id,
    required this.title,
    required this.url,
    required this.headers,
    required this.timestamp,
  });

  Webhook copyWith({
    int? id,
    String? title,
    String? url,
    Map<String, String>? headers,
    int? timestamp,
  }) {
    return Webhook(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'headers': _headersToJson(headers),
      'timestamp': timestamp,
    };
  }

  factory Webhook.fromMap(Map<String, dynamic> map) {
    return Webhook(
      id: map['id'] as int?,
      title: map['title'] as String,
      url: map['url'] as String,
      headers: map['headers'] != null
          ? _jsonToHeaders(map['headers'] as String)
          : {'Content-Type': 'application/json'},
      timestamp: map['timestamp'] as int,
    );
  }

  static String _headersToJson(Map<String, String> headers) {
    final jsonHeaders = <String, String>{};
    headers.forEach((key, value) {
      jsonHeaders[key] = value;
    });
    return jsonHeaders.entries
        .map((e) => '${_escape(e.key)}:${_escape(e.value)}')
        .join(',');
  }

  static Map<String, String> _jsonToHeaders(String json) {
    final headers = <String, String>{};
    if (json.isEmpty) return headers;

    final parts = json.split(',');
    for (final part in parts) {
      final colonIndex = part.indexOf(':');
      if (colonIndex > 0) {
        final key = _unescape(part.substring(0, colonIndex));
        final value = _unescape(part.substring(colonIndex + 1));
        headers[key] = value;
      }
    }
    return headers;
  }

  static String _escape(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(':', '\\:');
  }

  static String _unescape(String s) {
    return s
        .replaceAll('\\,', ',')
        .replaceAll('\\:', ':')
        .replaceAll('\\\\', '\\');
  }
}
