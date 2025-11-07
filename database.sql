-- Database MariaDB per Orbitica Core - HiScore System
-- Creazione database (opzionale, potrebbe già esistere)
CREATE DATABASE IF NOT EXISTS orbitica CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE orbitica;

-- Tabella per i punteggi
CREATE TABLE IF NOT EXISTS hiscores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    player_initials VARCHAR(3) NOT NULL,
    score INT NOT NULL,
    wave INT NOT NULL DEFAULT 1,
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    device_id VARCHAR(255) DEFAULT NULL,
    INDEX idx_score (score DESC),
    INDEX idx_date (date_created DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Vista per top 10 (opzionale, per ottimizzazione)
CREATE OR REPLACE VIEW top10_hiscores AS
SELECT 
    player_initials,
    score,
    wave,
    date_created
FROM hiscores
ORDER BY score DESC, date_created ASC
LIMIT 10;
