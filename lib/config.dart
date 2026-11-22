import 'package:flutter/foundation.dart';

const String _apiUrlDefinida = String.fromEnvironment('API_URL');

String get apiUrl {
  if (_apiUrlDefinida.isNotEmpty) return _apiUrlDefinida;
  if (kIsWeb && Uri.base.path.startsWith('/app')) return '${Uri.base.origin}/api';
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8081/api';
  }
  return 'http://localhost:8081/api';
}

String? urlImagem(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  return apiUrl.replaceFirst(RegExp(r'/api/?$'), '') + url;
}
