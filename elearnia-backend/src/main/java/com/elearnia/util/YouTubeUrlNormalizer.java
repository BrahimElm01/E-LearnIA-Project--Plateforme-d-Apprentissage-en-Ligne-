package com.elearnia.util;

import java.util.regex.Pattern;
import java.util.regex.Matcher;

/**
 * Utilitaire pour normaliser les URLs YouTube
 * Garde les URLs YouTube normales (watch ou youtu.be) sans conversion en embed
 */
public class YouTubeUrlNormalizer {
    
    /**
     * Normalise une URL YouTube en gardant le format original
     * @param youtubeUrl L'URL YouTube à normaliser (peut être n'importe quel format)
     * @return URL YouTube normale (watch ou youtu.be) ou l'URL originale si ce n'est pas une URL YouTube valide
     */
    public static String normalize(String youtubeUrl) {
        if (youtubeUrl == null || youtubeUrl.trim().isEmpty()) {
            return youtubeUrl;
        }
        
        String cleanUrl = youtubeUrl.trim();
        
        // Si c'est déjà une URL embed, extraire l'ID et convertir en URL watch normale
        if (cleanUrl.contains("youtube-nocookie.com/embed/") || cleanUrl.contains("youtube.com/embed/")) {
            String videoId = extractVideoId(cleanUrl);
            if (videoId != null) {
                return "https://www.youtube.com/watch?v=" + videoId;
            }
        }
        
        // Si c'est déjà une URL watch ou youtu.be, la garder telle quelle
        if (cleanUrl.contains("youtube.com/watch") || cleanUrl.contains("youtu.be/")) {
            return cleanUrl;
        }
        
        // Si c'est juste un ID, créer une URL watch
        if (cleanUrl.matches("^[a-zA-Z0-9_-]{11}$")) {
            return "https://www.youtube.com/watch?v=" + cleanUrl;
        }
        
        // Retourner l'URL originale
        return cleanUrl;
    }
    
    /**
     * Extrait l'ID de la vidéo depuis n'importe quel format d'URL YouTube
     */
    private static String extractVideoId(String url) {
        // Pattern pour extraire l'ID depuis différents formats
        java.util.regex.Pattern[] patterns = {
            java.util.regex.Pattern.compile("(?:youtube-nocookie\\.com|youtube\\.com)/embed/([a-zA-Z0-9_-]{11})"),
            java.util.regex.Pattern.compile("youtu\\.be/([a-zA-Z0-9_-]{11})"),
            java.util.regex.Pattern.compile("(?:youtube\\.com|m\\.youtube\\.com)/watch\\?.*[?&]v=([a-zA-Z0-9_-]{11})"),
            java.util.regex.Pattern.compile("youtube\\.com/v/([a-zA-Z0-9_-]{11})"),
            java.util.regex.Pattern.compile("youtube\\.com/shorts/([a-zA-Z0-9_-]{11})")
        };
        
        for (java.util.regex.Pattern pattern : patterns) {
            java.util.regex.Matcher matcher = pattern.matcher(url);
            if (matcher.find()) {
                String videoId = matcher.group(1);
                if (videoId != null && videoId.length() == 11 && videoId.matches("[a-zA-Z0-9_-]+")) {
                    return videoId;
                }
            }
        }
        
        return null;
    }
    
    /**
     * Vérifie si une URL est une URL YouTube
     */
    public static boolean isYouTubeUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return false;
        }
        String cleanUrl = url.trim().toLowerCase();
        return cleanUrl.contains("youtube.com") || 
               cleanUrl.contains("youtu.be") || 
               cleanUrl.contains("youtube-nocookie.com");
    }
}




