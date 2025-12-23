package com.elearnia.controller;

import com.elearnia.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/files")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FileUploadController {

    private final AuthService authService;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    @Value("${app.upload.videos.dir:uploads/videos}")
    private String videosUploadDir;

    @Value("${app.server.base-url:http://localhost:8080}")
    private String serverBaseUrl;

    @PostMapping({"/upload-image", "/upload"})
    public ResponseEntity<Map<String, String>> uploadImage(
            @RequestHeader("Authorization") String bearer,
            @RequestParam("file") MultipartFile file
    ) {
        // Vérifier l'authentification
        try {
            String token = bearer.replace("Bearer ", "").trim();
            authService.getCurrentUserFromToken(token);
        } catch (Exception e) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Non autorisé"
            );
        }

        // Vérifier que c'est une image
        String contentType = file.getContentType();
        String originalFilename = file.getOriginalFilename();
        
        // Vérifier le Content-Type
        boolean isImageByContentType = contentType != null && contentType.startsWith("image/");
        
        // Vérifier aussi l'extension du fichier comme fallback
        boolean isImageByExtension = false;
        if (originalFilename != null) {
            String lowerFilename = originalFilename.toLowerCase();
            isImageByExtension = lowerFilename.endsWith(".jpg") || 
                                lowerFilename.endsWith(".jpeg") || 
                                lowerFilename.endsWith(".png") || 
                                lowerFilename.endsWith(".gif") || 
                                lowerFilename.endsWith(".webp") ||
                                lowerFilename.endsWith(".bmp");
        }
        
        if (!isImageByContentType && !isImageByExtension) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le fichier doit être une image (jpg, jpeg, png, gif, webp, bmp)"
            );
        }

        try {
            // Créer le dossier d'upload s'il n'existe pas
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // Générer un nom de fichier unique
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String filename = UUID.randomUUID().toString() + extension;

            // Sauvegarder le fichier
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Construire l'URL en utilisant la configuration de base URL
            String fileUrl = String.format("%s/api/files/images/%s", serverBaseUrl, filename);

            Map<String, String> response = new HashMap<>();
            response.put("url", fileUrl);
            response.put("filename", filename);

            return ResponseEntity.ok(response);
        } catch (IOException e) {
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Erreur lors de l'upload: " + e.getMessage()
            );
        }
    }

    @RequestMapping(value = "/images/{filename:.+}", method = RequestMethod.OPTIONS)
    public ResponseEntity<Void> handleImageOptions() {
        return ResponseEntity.ok()
                .header("Access-Control-Allow-Origin", "*")
                .header("Access-Control-Allow-Methods", "GET, OPTIONS")
                .header("Access-Control-Allow-Headers", "*")
                .build();
    }

    @GetMapping("/images/{filename:.+}")
    @CrossOrigin(origins = "*", methods = {RequestMethod.GET, RequestMethod.OPTIONS})
    public ResponseEntity<byte[]> getImage(@PathVariable String filename) {
        try {
            // Logger pour débogage
            System.out.println("Tentative de chargement d'image: " + filename);
            
            // Nettoyer le nom de fichier pour éviter les attaques de path traversal
            // Permettre les tirets dans les UUIDs (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
            // Permettre aussi les points pour les extensions
            // Spring décode automatiquement les path variables, donc pas besoin de décoder manuellement
            String safeFilename = filename.trim();
            
            // Vérifier que le fichier ne contient pas de path traversal
            if (safeFilename.contains("..") || safeFilename.contains("/") || safeFilename.contains("\\")) {
                System.err.println("Path traversal détecté dans le nom de fichier: " + filename + " (safe: " + safeFilename + ")");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(("Path traversal détecté").getBytes());
            }
            
            // Vérifier que le nom de fichier ne contient que des caractères autorisés
            // UUID format: lettres, chiffres, tirets, points, underscores
            // Vérifier d'abord si ça ressemble à un UUID avec extension (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.ext)
            // Pattern plus permissif pour accepter les UUIDs avec différentes casse et extensions
            boolean looksLikeValidFilename = safeFilename.matches("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}\\.[a-zA-Z0-9]+$") ||
                                             safeFilename.matches("^[a-zA-Z0-9._\\-]+$");
            
            if (!looksLikeValidFilename) {
                System.err.println("=== VALIDATION ÉCHOUÉE ===");
                System.err.println("Nom de fichier original: " + filename);
                System.err.println("Nom de fichier nettoyé: " + safeFilename);
                System.err.println("Longueur: " + safeFilename.length());
                
                // Afficher chaque caractère pour débogage
                StringBuilder charDetails = new StringBuilder();
                for (int i = 0; i < Math.min(safeFilename.length(), 100); i++) {
                    char c = safeFilename.charAt(i);
                    charDetails.append("Char[").append(i).append("]: '").append(c).append("' (code: ").append((int)c).append(")\n");
                }
                System.err.println(charDetails.toString());
                
                // Au lieu de retourner 400 immédiatement, vérifier d'abord si le fichier existe
                // Cela permet de gérer les cas où la validation est trop stricte mais le fichier existe
                Path uploadPathCheck = Paths.get(uploadDir);
                if (!Files.exists(uploadPathCheck)) {
                    try {
                        Files.createDirectories(uploadPathCheck);
                    } catch (IOException e) {
                        // Ignorer l'erreur pour l'instant
                    }
                }
                Path filePath = uploadPathCheck.resolve(safeFilename).normalize();
                if (Files.exists(filePath) && Files.isRegularFile(filePath)) {
                    System.out.println("Fichier existe malgré la validation échouée, on continue");
                    // Continuer le traitement normal
                } else {
                    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                            .header("Content-Type", "text/plain")
                            .body(("Caractères invalides dans le nom de fichier: " + safeFilename).getBytes());
                }
            }
            
            System.out.println("Nom de fichier validé: " + safeFilename);
            
            // S'assurer que le répertoire d'upload existe
            Path uploadPath = Paths.get(uploadDir);
            System.out.println("Répertoire d'upload configuré: " + uploadPath.toAbsolutePath());
            
            if (!Files.exists(uploadPath)) {
                try {
                    Files.createDirectories(uploadPath);
                    System.out.println("Répertoire d'upload créé: " + uploadPath.toAbsolutePath());
                } catch (IOException e) {
                    System.err.println("Impossible de créer le répertoire d'upload: " + e.getMessage());
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                            .body(("Erreur serveur: impossible de créer le répertoire").getBytes());
                }
            }
            
            Path filePath = uploadPath.resolve(safeFilename).normalize();
            Path normalizedUploadPath = uploadPath.toAbsolutePath().normalize();
            Path normalizedFilePath = filePath.toAbsolutePath().normalize();
            
            System.out.println("Chemin du fichier recherché: " + normalizedFilePath);
            System.out.println("Répertoire d'upload normalisé: " + normalizedUploadPath);
            
            // Vérifier que le fichier est bien dans le répertoire uploads (sécurité)
            if (!normalizedFilePath.startsWith(normalizedUploadPath)) {
                System.err.println("Tentative d'accès hors du répertoire autorisé. Fichier: " + normalizedFilePath + ", Upload: " + normalizedUploadPath);
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                        .body(("Accès refusé: chemin invalide").getBytes());
            }
            
            // Vérifier que le fichier existe et est un fichier régulier
            if (!Files.exists(normalizedFilePath)) {
                System.err.println("Fichier introuvable: " + normalizedFilePath);
                System.err.println("Liste des fichiers dans " + normalizedUploadPath + ":");
                try {
                    Files.list(normalizedUploadPath).forEach(p -> System.err.println("  - " + p.getFileName()));
                } catch (IOException e) {
                    System.err.println("  Impossible de lister les fichiers: " + e.getMessage());
                }
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(("Fichier introuvable: " + safeFilename).getBytes());
            }
            
            if (!Files.isRegularFile(normalizedFilePath)) {
                System.err.println("Le chemin n'est pas un fichier régulier: " + normalizedFilePath);
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }

            byte[] imageBytes = Files.readAllBytes(normalizedFilePath);
            
            // Déterminer le Content-Type basé sur l'extension
            String contentType = "image/jpeg"; // par défaut
            String lowerFilename = safeFilename.toLowerCase();
            if (lowerFilename.endsWith(".png")) {
                contentType = "image/png";
            } else if (lowerFilename.endsWith(".gif")) {
                contentType = "image/gif";
            } else if (lowerFilename.endsWith(".webp")) {
                contentType = "image/webp";
            } else if (lowerFilename.endsWith(".bmp")) {
                contentType = "image/bmp";
            } else if (lowerFilename.endsWith(".jpg") || lowerFilename.endsWith(".jpeg")) {
                contentType = "image/jpeg";
            } else {
                // Essayer de détecter le type MIME
                try {
                    String detectedType = Files.probeContentType(normalizedFilePath);
                    if (detectedType != null && detectedType.startsWith("image/")) {
                        contentType = detectedType;
                    }
                } catch (Exception e) {
                    // Ignorer l'erreur de détection MIME, utiliser le type par défaut
                }
            }

            return ResponseEntity.ok()
                    .header("Content-Type", contentType)
                    .header("Cache-Control", "public, max-age=31536000")
                    .header("Access-Control-Allow-Origin", "*")
                    .header("Access-Control-Allow-Methods", "GET, OPTIONS")
                    .header("Access-Control-Allow-Headers", "*")
                    .header("Access-Control-Expose-Headers", "*")
                    .body(imageBytes);
        } catch (IOException e) {
            System.err.println("Erreur IO lors de la lecture du fichier: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        } catch (Exception e) {
            System.err.println("Erreur lors de la lecture du fichier: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PostMapping("/upload-video")
    public ResponseEntity<Map<String, String>> uploadVideo(
            @RequestHeader("Authorization") String bearer,
            @RequestParam("file") MultipartFile file
    ) {
        // Vérifier l'authentification
        try {
            String token = bearer.replace("Bearer ", "").trim();
            authService.getCurrentUserFromToken(token);
        } catch (Exception e) {
            System.err.println("Erreur d'authentification lors de l'upload vidéo: " + e.getMessage());
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Non autorisé"
            );
        }

        // Vérifier que le fichier n'est pas vide
        if (file.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le fichier est vide"
            );
        }

        // Vérifier la taille du fichier (max 500 MB)
        long maxSize = 500 * 1024 * 1024; // 500 MB
        if (file.getSize() > maxSize) {
            System.err.println("Fichier trop volumineux: " + file.getSize() + " bytes (max: " + maxSize + ")");
            throw new ResponseStatusException(
                    HttpStatus.PAYLOAD_TOO_LARGE,
                    "Le fichier est trop volumineux. Taille maximale: 500 MB"
            );
        }

        // Vérifier que c'est une vidéo
        String contentType = file.getContentType();
        String originalFilename = file.getOriginalFilename();
        
        System.out.println("Upload vidéo - Nom: " + originalFilename + ", Taille: " + file.getSize() + " bytes, Type: " + contentType);
        
        // Vérifier le Content-Type
        boolean isVideoByContentType = contentType != null && contentType.startsWith("video/");
        
        // Vérifier aussi l'extension du fichier comme fallback
        boolean isVideoByExtension = false;
        if (originalFilename != null) {
            String lowerFilename = originalFilename.toLowerCase();
            isVideoByExtension = lowerFilename.endsWith(".mp4") || 
                                lowerFilename.endsWith(".webm") || 
                                lowerFilename.endsWith(".ogg") || 
                                lowerFilename.endsWith(".mov") ||
                                lowerFilename.endsWith(".avi") ||
                                lowerFilename.endsWith(".mkv");
        }
        
        if (!isVideoByContentType && !isVideoByExtension) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Le fichier doit être une vidéo (mp4, webm, ogg, mov, avi, mkv)"
            );
        }

        try {
            // Créer le dossier d'upload pour les vidéos s'il n'existe pas
            Path videosUploadPath = Paths.get(videosUploadDir);
            if (!Files.exists(videosUploadPath)) {
                Files.createDirectories(videosUploadPath);
                System.out.println("Répertoire vidéos créé: " + videosUploadPath.toAbsolutePath());
            }

            // Générer un nom de fichier unique
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String filename = UUID.randomUUID().toString() + extension;

            // Sauvegarder le fichier
            Path filePath = videosUploadPath.resolve(filename);
            System.out.println("Début de l'écriture du fichier: " + filePath.toAbsolutePath());
            
            // Utiliser Files.copy avec un buffer pour les gros fichiers
            long bytesCopied = Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            System.out.println("Fichier écrit avec succès: " + bytesCopied + " bytes");

            // Construire l'URL en utilisant la configuration de base URL
            String fileUrl = String.format("%s/api/files/videos/%s", serverBaseUrl, filename);

            Map<String, String> response = new HashMap<>();
            response.put("url", fileUrl);
            response.put("filename", filename);

            System.out.println("Upload vidéo réussi: " + fileUrl);
            return ResponseEntity.ok(response);
        } catch (IOException e) {
            System.err.println("Erreur IO lors de l'upload vidéo: " + e.getMessage());
            e.printStackTrace();
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Erreur lors de l'upload: " + e.getMessage()
            );
        } catch (Exception e) {
            System.err.println("Erreur inattendue lors de l'upload vidéo: " + e.getMessage());
            e.printStackTrace();
            throw new ResponseStatusException(
                    HttpStatus.INTERNAL_SERVER_ERROR,
                    "Erreur lors de l'upload: " + e.getMessage()
            );
        }
    }

    @GetMapping("/videos/{filename:.+}")
    @CrossOrigin(origins = "*", methods = {RequestMethod.GET, RequestMethod.OPTIONS})
    public ResponseEntity<byte[]> getVideo(@PathVariable String filename) {
        try {
            System.out.println("Tentative de chargement de vidéo: " + filename);
            
            String safeFilename = filename.trim();
            
            // Vérifier que le fichier ne contient pas de path traversal
            if (safeFilename.contains("..") || safeFilename.contains("/") || safeFilename.contains("\\")) {
                System.err.println("Path traversal détecté dans le nom de fichier: " + filename);
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }
            
            // Vérifier que le nom de fichier ne contient que des caractères autorisés
            boolean looksLikeValidFilename = safeFilename.matches("^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}\\.[a-zA-Z0-9]+$") ||
                                             safeFilename.matches("^[a-zA-Z0-9._\\-]+$");
            
            if (!looksLikeValidFilename) {
                System.err.println("Caractères invalides dans le nom de fichier: " + filename);
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }
            
            // S'assurer que le répertoire d'upload existe
            Path videosUploadPath = Paths.get(videosUploadDir);
            System.out.println("Répertoire d'upload vidéos configuré: " + videosUploadPath.toAbsolutePath());
            
            if (!Files.exists(videosUploadPath)) {
                try {
                    Files.createDirectories(videosUploadPath);
                } catch (IOException e) {
                    System.err.println("Impossible de créer le répertoire d'upload: " + e.getMessage());
                    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
                }
            }
            
            Path filePath = videosUploadPath.resolve(safeFilename).normalize();
            Path normalizedUploadPath = videosUploadPath.toAbsolutePath().normalize();
            Path normalizedFilePath = filePath.toAbsolutePath().normalize();
            
            // Vérifier que le fichier est bien dans le répertoire autorisé
            if (!normalizedFilePath.startsWith(normalizedUploadPath)) {
                System.err.println("Tentative d'accès hors du répertoire autorisé");
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
            
            // Vérifier que le fichier existe
            if (!Files.exists(normalizedFilePath)) {
                System.err.println("Fichier vidéo introuvable: " + normalizedFilePath);
                return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
            }
            
            if (!Files.isRegularFile(normalizedFilePath)) {
                System.err.println("Le chemin n'est pas un fichier régulier");
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }

            byte[] videoBytes = Files.readAllBytes(normalizedFilePath);
            
            // Déterminer le Content-Type basé sur l'extension
            String contentType = "video/mp4"; // par défaut
            String lowerFilename = safeFilename.toLowerCase();
            if (lowerFilename.endsWith(".webm")) {
                contentType = "video/webm";
            } else if (lowerFilename.endsWith(".ogg")) {
                contentType = "video/ogg";
            } else if (lowerFilename.endsWith(".mov")) {
                contentType = "video/quicktime";
            } else if (lowerFilename.endsWith(".avi")) {
                contentType = "video/x-msvideo";
            } else if (lowerFilename.endsWith(".mkv")) {
                contentType = "video/x-matroska";
            } else if (lowerFilename.endsWith(".mp4")) {
                contentType = "video/mp4";
            } else {
                // Essayer de détecter le type MIME
                try {
                    String detectedType = Files.probeContentType(normalizedFilePath);
                    if (detectedType != null && detectedType.startsWith("video/")) {
                        contentType = detectedType;
                    }
                } catch (Exception e) {
                    // Ignorer l'erreur de détection MIME
                }
            }

            return ResponseEntity.ok()
                    .header("Content-Type", contentType)
                    .header("Cache-Control", "public, max-age=31536000")
                    .header("Access-Control-Allow-Origin", "*")
                    .header("Access-Control-Allow-Methods", "GET, OPTIONS")
                    .header("Access-Control-Allow-Headers", "*")
                    .header("Access-Control-Expose-Headers", "*")
                    .header("Accept-Ranges", "bytes")
                    .body(videoBytes);
        } catch (IOException e) {
            System.err.println("Erreur IO lors de la lecture de la vidéo: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        } catch (Exception e) {
            System.err.println("Erreur lors de la lecture de la vidéo: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}

