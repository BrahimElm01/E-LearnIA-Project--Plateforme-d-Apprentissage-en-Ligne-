CREATE DATABASE IF NOT EXISTS peer_review CHARACTER SET utf8mb4;
USE peer_review;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(150) UNIQUE,
  password_hash VARCHAR(255),
  role ENUM('teacher','student')
);
