package com.elearnia.repository;

import com.elearnia.entities.Course;
import com.elearnia.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CourseRepository extends JpaRepository<Course, Long> {

    List<Course> findByTeacher(User teacher);

    long countByTeacher(User teacher);

    @Query("SELECT c FROM Course c LEFT JOIN FETCH c.teacher WHERE c.id = :id")
    Optional<Course> findByIdWithTeacher(@Param("id") Long id);
}
