-- ============================================
-- CORRECTION URGENTE: Colonne description trop petite
-- ============================================
-- 
-- Ce script corrige l'erreur "Data too long for column 'description'"
-- en modifiant la colonne de VARCHAR(2000) à TEXT
--
-- COPIEZ ET EXÉCUTEZ CE SCRIPT DANS VOTRE BASE DE DONNÉES MYSQL
-- ============================================

USE elearnia_db;

ALTER TABLE lessons MODIFY COLUMN description TEXT;

-- Vérification
DESCRIBE lessons;








