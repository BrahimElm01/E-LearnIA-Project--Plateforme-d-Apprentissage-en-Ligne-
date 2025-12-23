-- Script SQL pour modifier la colonne description de la table lessons
-- À exécuter manuellement dans votre base de données MySQL
-- 
-- Ce script change la colonne description de VARCHAR(2000) à TEXT
-- pour permettre de stocker du contenu long (texte, code, tableaux) pour les leçons

USE elearnia_db;

ALTER TABLE lessons MODIFY COLUMN description TEXT;

-- Vérification
DESCRIBE lessons;








