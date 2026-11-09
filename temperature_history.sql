CREATE TABLE temperature_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    truck_id VARCHAR(50) NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    location VARCHAR(100),
    humidity DECIMAL(5,2),
    recorded_at DATETIME NOT NULL,

    INDEX idx_truck_time (truck_id, recorded_at)
);