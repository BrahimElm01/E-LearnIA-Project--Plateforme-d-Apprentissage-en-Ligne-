import 'package:flutter/material.dart';
import '../config/api_config.dart';

/// Widget pour afficher une image réseau avec gestion d'erreur robuste
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  /// Normalise l'URL de l'image en remplaçant l'ancienne IP par l'IP configurée
  /// pour éviter les erreurs de connexion timeout
  static String? normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    
    // Extraire l'URL de base depuis la configuration
    final baseUrl = ApiConfig.baseUrl;
    
    // Remplacer toute IP locale (192.168.x.x ou 10.x.x.x ou 172.x.x.x) par l'IP configurée
    // Cela permet de corriger les URLs qui utilisent une ancienne IP
    final normalized = url.replaceAll(
      RegExp(r'http://(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+|172\.\d+\.\d+\.\d+|localhost|127\.0\.0\.1):\d+/'),
      '$baseUrl/',
    );
    
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Si pas d'URL, afficher le widget d'erreur
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget(theme);
    }

    // Normaliser l'URL pour remplacer l'ancienne IP par localhost
    final normalizedUrl = normalizeImageUrl(imageUrl!);
    
    // Si l'URL normalisée est null, afficher le widget d'erreur
    if (normalizedUrl == null || normalizedUrl.isEmpty) {
      return _buildErrorWidget(theme);
    }

    // Vérifier si c'est une URL placeholder qui pourrait échouer
    final isPlaceholderUrl = normalizedUrl.contains('via.placeholder.com') ||
                             normalizedUrl.contains('placeholder.com');

    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      child: Image.network(
        normalizedUrl, // Maintenant garanti non-null
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Logger l'erreur pour le débogage
          debugPrint('Erreur chargement image: $error');
          debugPrint('URL originale: $imageUrl');
          debugPrint('URL normalisée: $normalizedUrl');
          
          // Si c'est une erreur 400 (Bad Request), le fichier n'existe probablement pas
          // ou il y a un problème de validation. On affiche simplement le widget d'erreur.
          // Ne pas essayer de recharger car cela pourrait causer une boucle infinie.
          
          return _buildErrorWidget(theme);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          );
        },
        // Si c'est une URL placeholder, ne pas essayer de la charger
        // et afficher directement le widget d'erreur
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (isPlaceholderUrl && frame == null) {
            return _buildErrorWidget(theme);
          }
          return child;
        },
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme) {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              size: (height != null && height! < 100) ? 32 : 48,
              color: theme.colorScheme.secondary,
            ),
            if (height != null && height! > 100) ...[
              const SizedBox(height: 8),
              Text(
                'Image non disponible',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}









