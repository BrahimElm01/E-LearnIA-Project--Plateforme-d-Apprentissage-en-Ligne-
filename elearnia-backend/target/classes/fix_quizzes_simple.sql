-- Script SIMPLE pour rendre course_id nullable dans la table quizzes
-- À exécuter dans MySQL Workbench ou via la ligne de commande MySQL

USE elearnia_db;

-- Méthode 1: Si vous connaissez le nom de la contrainte
-- ALTER TABLE quizzes DROP FOREIGN KEY quizzes_ibfk_1;
-- ALTER TABLE quizzes MODIFY COLUMN course_id BIGINT NULL;
-- ALTER TABLE quizzes ADD CONSTRAINT FK_quizzes_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE;

-- Méthode 2: Script automatique (trouve et supprime la contrainte automatiquement)
SET @constraint_name = (
    SELECT CONSTRAINT_NAME 
    FROM information_schema.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = DATABASE() 
      AND TABLE_NAME = 'quizzes' 
      AND COLUMN_NAME = 'course_id'
      AND CONSTRAINT_NAME != 'PRIMARY'
    LIMIT 1
);

-- Supprimer la contrainte si elle existe
SET @sql = IF(@constraint_name IS NOT NULL, 
    CONCAT('ALTER TABLE quizzes DROP FOREIGN KEY ', @constraint_name), 
    'SELECT "No foreign key constraint found"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Modifier la colonne pour permettre NULL
ALTER TABLE quizzes MODIFY COLUMN course_id BIGINT NULL;

-- Recréer la contrainte (elle acceptera NULL)
ALTER TABLE quizzes 
ADD CONSTRAINT FK_quizzes_course 
FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE;









