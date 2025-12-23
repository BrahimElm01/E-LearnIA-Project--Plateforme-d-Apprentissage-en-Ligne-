-- Script pour rendre course_id nullable dans la table quizzes
-- À exécuter dans MySQL pour permettre les quizzes standalone

USE elearnia_db;

-- Étape 1: Trouver le nom de la contrainte de clé étrangère
-- Exécutez cette requête pour voir les contraintes:
SELECT CONSTRAINT_NAME 
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'elearnia_db' 
  AND TABLE_NAME = 'quizzes' 
  AND COLUMN_NAME = 'course_id'
  AND CONSTRAINT_NAME != 'PRIMARY';

-- Étape 2: Supprimer la contrainte de clé étrangère (remplacez 'NOM_DE_LA_CONTRAINTE' par le nom trouvé ci-dessus)
-- Exemple avec des noms communs:
SET @constraint_name = (
    SELECT CONSTRAINT_NAME 
    FROM information_schema.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'elearnia_db' 
      AND TABLE_NAME = 'quizzes' 
      AND COLUMN_NAME = 'course_id'
      AND CONSTRAINT_NAME != 'PRIMARY'
    LIMIT 1
);

SET @sql = CONCAT('ALTER TABLE quizzes DROP FOREIGN KEY ', @constraint_name);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Étape 3: Modifier la colonne pour permettre NULL
ALTER TABLE quizzes MODIFY COLUMN course_id BIGINT NULL;

-- Étape 4: Recréer la contrainte de clé étrangère (elle acceptera NULL pour les quizzes standalone)
ALTER TABLE quizzes 
ADD CONSTRAINT FK_quizzes_course 
FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE;









