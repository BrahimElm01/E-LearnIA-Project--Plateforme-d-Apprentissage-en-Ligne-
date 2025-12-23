-- Script SQL pour mettre à jour la taille de la colonne description dans la table quizzes
-- À exécuter dans MySQL si la table existe déjà

ALTER TABLE quizzes MODIFY COLUMN description VARCHAR(2000);











