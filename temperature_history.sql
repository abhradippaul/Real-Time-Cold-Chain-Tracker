CREATE TABLE IF NOT EXISTS temperature_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    truck_id VARCHAR(50) NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    location VARCHAR(100),
    humidity DECIMAL(5,2),
    recorded_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT uq_truck_recorded_at UNIQUE (truck_id, recorded_at)
);

CREATE INDEX IF NOT EXISTS idx_truck_time ON temperature_history (truck_id, recorded_at);
