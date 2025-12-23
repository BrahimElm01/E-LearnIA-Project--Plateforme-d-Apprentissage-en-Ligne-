package com.elearnia.repository;

import com.elearnia.entities.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);
    
    List<Notification> findByUserIdAndReadFalseOrderByCreatedAtDesc(Long userId);
    
    @Modifying
    @Query("UPDATE Notification n SET n.read = true WHERE n.user.id = :userId")
    void markAllAsRead(Long userId);
    
    @Modifying
    @Query("UPDATE Notification n SET n.read = true WHERE n.id = :notificationId")
    void markAsRead(Long notificationId);
}







