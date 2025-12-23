/// Configuration partagée pour l'URL de base de l'API
class ApiConfig {
  static const String baseUrl = 'http://192.168.100.109:8080';
  
  /// Extrait l'URL de base (sans le chemin) depuis une URL complète
  static String getBaseUrlFromFullUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}:${uri.port}';
    } catch (e) {
      return baseUrl;
    }
  }
}



