-- ============================================
-- CORRECTION: Colonne description - TEXT vers LONGTEXT
-- ============================================
-- 
-- Hibernate avec @Lob attend LONGTEXT (CLOB) mais la base a TEXT
-- Ce script modifie la colonne de TEXT à LONGTEXT
--
-- COPIEZ ET EXÉCUTEZ CE SCRIPT DANS VOTRE BASE DE DONNÉES MYSQL/MariaDB
-- ============================================

USE elearnia_db;

-- Modifier la colonne description de TEXT à LONGTEXT
ALTER TABLE lessons MODIFY COLUMN description LONGTEXT;

-- Vérification
DESCRIBE lessons;








