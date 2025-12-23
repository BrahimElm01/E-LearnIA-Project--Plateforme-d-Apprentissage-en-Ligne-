-- Ajouter la colonne level si elle n'existe pas
ALTER TABLE quizzes 
ADD COLUMN IF NOT EXISTS level VARCHAR(20) NOT NULL DEFAULT 'BEGINNER';

-- Ajouter la colonne course_id si elle n'existe pas (elle devrait déjà exister mais on la rend nullable)
ALTER TABLE quizzes 
MODIFY COLUMN course_id BIGINT NULL;

-- Ajouter la colonne courseId si elle n'existe pas (pour stocker l'ID du cours même si la relation est nullable)
-- Note: Cette colonne peut être redondante avec course_id, mais elle permet de stocker l'ID même si course est null
ALTER TABLE quizzes 
ADD COLUMN IF NOT EXISTS courseId BIGINT NULL;










