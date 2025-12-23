-- ============================================
-- Script SQL pour corriger l'erreur de description trop longue
-- ============================================
-- 
-- PROBLÈME: La colonne 'description' dans la table 'lessons' est limitée à 2000 caractères
-- SOLUTION: Modifier la colonne pour utiliser TEXT (jusqu'à 65 535 caractères)
--
-- INSTRUCTIONS:
-- 1. Ouvrez votre client MySQL (MySQL Workbench, phpMyAdmin, ou ligne de commande)
-- 2. Connectez-vous à la base de données 'elearnia_db'
-- 3. Exécutez ce script
-- 4. Redémarrez votre application Spring Boot
-- ============================================

USE elearnia_db;

-- Modifier la colonne description de VARCHAR(2000) à TEXT
ALTER TABLE lessons MODIFY COLUMN description TEXT;

-- Vérification: Afficher la structure de la table pour confirmer
DESCRIBE lessons;

-- Si vous voulez voir la taille actuelle de la colonne:
-- SELECT COLUMN_NAME, COLUMN_TYPE, CHARACTER_MAXIMUM_LENGTH 
-- FROM INFORMATION_SCHEMA.COLUMNS 
-- WHERE TABLE_SCHEMA = 'elearnia_db' AND TABLE_NAME = 'lessons' AND COLUMN_NAME = 'description';
