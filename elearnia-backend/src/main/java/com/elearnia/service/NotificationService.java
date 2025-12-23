package com.elearnia.service;

import com.elearnia.entities.Course;
import com.elearnia.entities.Notification;
import com.elearnia.model.User;
import com.elearnia.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;

    @Transactional
    public void sendEnrollmentNotification(User teacher, User student, Course course) {
        String message = String.format(
                "%s s'est inscrit à votre cours \"%s\"",
                student.getFullName(),
                course.getTitle()
        );

        Notification notification = Notification.builder()
                .user(teacher)
                .message(message)
                .type("ENROLLMENT")
                .read(false)
                .build();

        notificationRepository.save(notification);
    }

    @Transactional
    public void sendCompletionNotification(User teacher, User student, Course course) {
        String message = String.format(
                "%s a terminé votre cours \"%s\"",
                student.getFullName(),
                course.getTitle()
        );

        Notification notification = Notification.builder()
                .user(teacher)
                .message(message)
                .type("COMPLETION")
                .read(false)
                .build();

        notificationRepository.save(notification);
    }
}











