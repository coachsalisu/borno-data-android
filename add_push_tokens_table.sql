-- Run in phpMyAdmin before deploying the new app.js.
-- Stores each device's push token so the server can send notifications to
-- it later. A user can have multiple tokens (e.g. if they reinstall), so
-- this is a separate table rather than a column on users.
CREATE TABLE IF NOT EXISTS push_tokens (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_email VARCHAR(255) NOT NULL,
  token VARCHAR(255) NOT NULL UNIQUE,
  platform VARCHAR(20) NOT NULL DEFAULT 'android',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
