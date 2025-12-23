-- Script SQL SIMPLE pour corriger l'erreur course_id cannot be null
-- Exécutez ce script dans MySQL Workbench ou via la ligne de commande

USE elearnia_db;

-- Étape 1: Trouver le nom de la contrainte
SELECT CONSTRAINT_NAME 
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_SCHEMA = 'elearnia_db' 
  AND TABLE_NAME = 'quizzes' 
  AND COLUMN_NAME = 'course_id'
  AND CONSTRAINT_NAME != 'PRIMARY';

-- Étape 2: Copiez le nom de la contrainte trouvé ci-dessus et exécutez:
-- ALTER TABLE quizzes DROP FOREIGN KEY [NOM_DE_LA_CONTRAINTE];

-- OU exécutez directement ces commandes (si les noms de contraintes sont standards):
ALTER TABLE quizzes DROP FOREIGN KEY IF EXISTS quizzes_ibfk_1;
ALTER TABLE quizzes DROP FOREIGN KEY IF EXISTS FKpxdnhxeppxx606nhyjtjyharp;
ALTER TABLE quizzes DROP FOREIGN KEY IF EXISTS fk_quizzes_course;

-- Étape 3: Modifier la colonne pour permettre NULL
ALTER TABLE quizzes MODIFY COLUMN course_id BIGINT NULL;

-- Étape 4: Recréer la contrainte (elle acceptera NULL pour les quizzes standalone)
ALTER TABLE quizzes 
ADD CONSTRAINT FK_quizzes_course 
FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE;









