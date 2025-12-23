package com.elearnia.config;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DatabaseMigration {

    @Autowired(required = false)
    private JdbcTemplate jdbcTemplate;

    @PostConstruct
    public void migrateDatabase() {
        if (jdbcTemplate == null) {
            log.warn("JdbcTemplate not available, skipping database migration");
            return;
        }

        try {
            // Vérifier si course_id est déjà nullable
            String checkSql = "SELECT IS_NULLABLE FROM information_schema.COLUMNS " +
                    "WHERE TABLE_SCHEMA = DATABASE() " +
                    "AND TABLE_NAME = 'quizzes' " +
                    "AND COLUMN_NAME = 'course_id'";
            
            try {
                String isNullable = jdbcTemplate.queryForObject(checkSql, String.class);
                if ("YES".equalsIgnoreCase(isNullable)) {
                    log.info("course_id column is already nullable, no migration needed");
                    return;
                }
            } catch (Exception e) {
                log.debug("Could not check column nullable status: {}", e.getMessage());
            }

            log.info("Attempting to make course_id nullable in quizzes table...");

            // Trouver et supprimer la contrainte de clé étrangère
            String findConstraintSql = "SELECT CONSTRAINT_NAME " +
                    "FROM information_schema.KEY_COLUMN_USAGE " +
                    "WHERE TABLE_SCHEMA = DATABASE() " +
                    "AND TABLE_NAME = 'quizzes' " +
                    "AND COLUMN_NAME = 'course_id' " +
                    "AND CONSTRAINT_NAME != 'PRIMARY' " +
                    "LIMIT 1";

            try {
                String constraintName = jdbcTemplate.queryForObject(findConstraintSql, String.class);
                if (constraintName != null) {
                    String dropConstraintSql = "ALTER TABLE quizzes DROP FOREIGN KEY " + constraintName;
                    jdbcTemplate.execute(dropConstraintSql);
                    log.info("Dropped foreign key constraint: {}", constraintName);
                }
            } catch (Exception e) {
                log.debug("Could not find or drop foreign key constraint: {}", e.getMessage());
                // Essayer les noms communs
                try {
                    jdbcTemplate.execute("ALTER TABLE quizzes DROP FOREIGN KEY quizzes_ibfk_1");
                    log.info("Dropped foreign key constraint: quizzes_ibfk_1");
                } catch (Exception e2) {
                    log.debug("Could not drop quizzes_ibfk_1: {}", e2.getMessage());
                }
            }

            // Modifier la colonne pour permettre NULL
            jdbcTemplate.execute("ALTER TABLE quizzes MODIFY COLUMN course_id BIGINT NULL");
            log.info("Modified course_id column to allow NULL");

            // Recréer la contrainte de clé étrangère
            try {
                jdbcTemplate.execute("ALTER TABLE quizzes " +
                        "ADD CONSTRAINT FK_quizzes_course " +
                        "FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE");
                log.info("Recreated foreign key constraint FK_quizzes_course");
            } catch (Exception e) {
                log.debug("Could not recreate foreign key constraint (may already exist): {}", e.getMessage());
            }

            log.info("Database migration completed successfully");

        } catch (Exception e) {
            log.error("Error during database migration: {}", e.getMessage(), e);
            log.warn("Please execute the SQL script manually: EXECUTE_THIS_SQL.sql");
        }
    }
}

