-- Script pour rendre course_id nullable dans la table quizzes
-- Cela permet de créer des quizzes standalone (sans cours associé)
-- À exécuter dans MySQL si la table existe déjà avec course_id NOT NULL

-- Étape 1: Trouver et supprimer la contrainte de clé étrangère
-- D'abord, trouver le nom de la contrainte (exécutez cette requête pour voir les contraintes):
-- SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE 
-- WHERE TABLE_SCHEMA = 'elearnia_db' AND TABLE_NAME = 'quizzes' AND COLUMN_NAME = 'course_id';

-- Ensuite, supprimez la contrainte (remplacez 'nom_de_la_contrainte' par le nom trouvé):
-- ALTER TABLE quizzes DROP FOREIGN KEY nom_de_la_contrainte;

-- Ou essayez ces noms communs:
ALTER TABLE quizzes DROP FOREIGN KEY IF EXISTS quizzes_ibfk_1;
ALTER TABLE quizzes DROP FOREIGN KEY IF EXISTS FKpxdnhxeppxx606nhyjtjyharp;
ALTER TABLE quizzes DROP FOREIGN KEY IF EXISTS fk_quizzes_course;

-- Étape 2: Modifier la colonne pour permettre NULL
ALTER TABLE quizzes MODIFY COLUMN course_id BIGINT NULL;

-- Étape 3: Recréer la contrainte de clé étrangère (optionnel, pour les quizzes liés à des cours)
-- Cette contrainte permettra NULL pour les quizzes standalone
ALTER TABLE quizzes ADD CONSTRAINT FK_quizzes_course 
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE;

