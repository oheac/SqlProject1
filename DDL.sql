-- DRONE MODELS
CREATE TABLE dbo.drone_models (
    model_id INT IDENTITY(1,1),
    model_name VARCHAR(50) NOT NULL,
    max_payload_lbs DECIMAL(6, 2) NOT NULL,
    empty_weight_lbs DECIMAL(6, 2) NOT NULL,
    max_flight_time_mins INT NOT NULL,
    CONSTRAINT pk_drone_models PRIMARY KEY (model_id),
    CONSTRAINT uq_model_name UNIQUE (model_name),
    CONSTRAINT chk_max_payload CHECK (max_payload_lbs > 0.00),
    CONSTRAINT chk_empty_weight CHECK (empty_weight_lbs > 0.00)
);
GO

-- DRONES
CREATE TABLE dbo.drones (
    drone_id INT IDENTITY(1,1),
    serial_number VARCHAR(50) NOT NULL,
    model_id INT NOT NULL,
    total_airframe_hours DECIMAL(8, 2) DEFAULT 0.00 NOT NULL,
    current_status VARCHAR(20) DEFAULT 'Available' NOT NULL,
    onboarding_date DATE NOT NULL,
    CONSTRAINT pk_drones PRIMARY KEY (drone_id),
    CONSTRAINT uq_drone_serial UNIQUE (serial_number),
    CONSTRAINT fk_drones_drone_models FOREIGN KEY (model_id)
        REFERENCES dbo.drone_models (model_id) ON DELETE NO ACTION,
    CONSTRAINT chk_airframe_hours CHECK (total_airframe_hours >= 0.00),
    CONSTRAINT chk_drone_status CHECK (current_status IN ('Available', 'In-Flight', 'Maintenance', 'Retired'))
);
GO

-- BATTERIES
CREATE TABLE dbo.batteries (
    battery_id INT IDENTITY(1,1),
    battery_serial VARCHAR(50) NOT NULL,
    charge_cycles_count INT DEFAULT 0 NOT NULL,
    state_of_health_pct DECIMAL(5, 2) DEFAULT 100.00 NOT NULL,
    battery_status VARCHAR(20) DEFAULT 'Fully Charged' NOT NULL,
    CONSTRAINT pk_batteries PRIMARY KEY (battery_id),
    CONSTRAINT uq_battery_serial UNIQUE (battery_serial),
    CONSTRAINT chk_charge_cycles CHECK (charge_cycles_count >= 0),
    CONSTRAINT chk_health_pct CHECK (state_of_health_pct BETWEEN 0.00 AND 100.00),
    CONSTRAINT chk_battery_status CHECK (battery_status IN ('Fully Charged', 'Charging', 'In-Use', 'Degraded', 'Retired'))
);
GO

-- LAUNCH PADS
CREATE TABLE dbo.launch_pads (
    pad_id INT IDENTITY(1,1),
    hub_name VARCHAR(50) NOT NULL,
    pad_identifier VARCHAR(10) NOT NULL,
    latitude DECIMAL(9, 6) NOT NULL,
    longitude DECIMAL(9, 6) NOT NULL,
    is_active BIT DEFAULT 1 NOT NULL,
    CONSTRAINT pk_launch_pads PRIMARY KEY (pad_id),
    CONSTRAINT uq_hub_pad UNIQUE (hub_name, pad_identifier),
    CONSTRAINT chk_pad_lat CHECK (latitude BETWEEN -90.000000 AND 90.000000),
    CONSTRAINT chk_pad_lon CHECK (longitude BETWEEN -180.000000 AND 180.000000)
);
GO

-- CUSTOMERS
CREATE TABLE dbo.customers (
    customer_id INT IDENTITY(1,1),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    account_created_at DATETIME DEFAULT GETDATE() NOT NULL,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_email UNIQUE (email)
);
GO

-- BATTERY CHARGE LOGS
CREATE TABLE dbo.battery_charge_logs (
    log_id INT IDENTITY(1,1),
    battery_id INT NOT NULL,
    drone_id INT NOT NULL,
    swapped_at DATETIME DEFAULT GETDATE() NOT NULL,
    starting_charge_pct DECIMAL(5, 2) NOT NULL,
    ending_charge_pct DECIMAL(5, 2) NOT NULL,
    CONSTRAINT pk_battery_charge_logs PRIMARY KEY (log_id),
    CONSTRAINT fk_charge_logs_batteries FOREIGN KEY (battery_id)
        REFERENCES dbo.batteries (battery_id) ON DELETE CASCADE,
    CONSTRAINT fk_charge_logs_drones FOREIGN KEY (drone_id)
        REFERENCES dbo.drones (drone_id) ON DELETE CASCADE,
    CONSTRAINT chk_start_charge CHECK (starting_charge_pct BETWEEN 0.00 AND 100.00),
    CONSTRAINT chk_end_charge CHECK (ending_charge_pct BETWEEN 0.00 AND 100.00)
);
GO

-- FLIGHT MISSIONS
CREATE TABLE dbo.flight_missions (
    mission_id INT IDENTITY(1,1),
    drone_id INT NOT NULL,
    pad_id INT NOT NULL,
    battery_id INT NOT NULL,
    mission_status VARCHAR(20) DEFAULT 'Scheduled' NOT NULL,
    scheduled_departure DATETIME NOT NULL,
    actual_departure DATETIME,
    actual_arrival DATETIME,
    estimated_duration_mins INT NOT NULL,
    CONSTRAINT pk_flight_missions PRIMARY KEY (mission_id),
    CONSTRAINT fk_missions_drones FOREIGN KEY (drone_id)
        REFERENCES dbo.drones (drone_id) ON DELETE NO ACTION,
    CONSTRAINT fk_missions_launch_pads FOREIGN KEY (pad_id)
        REFERENCES dbo.launch_pads (pad_id) ON DELETE NO ACTION,
    CONSTRAINT fk_missions_batteries FOREIGN KEY (battery_id)
        REFERENCES dbo.batteries (battery_id) ON DELETE NO ACTION,
    CONSTRAINT chk_mission_status CHECK (mission_status IN ('Scheduled', 'In-Flight', 'Completed', 'Aborted', 'Rerouted')),
    CONSTRAINT chk_timestamps CHECK (actual_arrival >= actual_departure)
);
GO

-- DELIVERY PACKAGES
CREATE TABLE dbo.delivery_packages (
    package_id INT IDENTITY(1,1),
    mission_id INT NOT NULL,
    customer_id INT NOT NULL,
    tracking_number VARCHAR(50) NOT NULL,
    package_weight_lbs DECIMAL(5, 2) NOT NULL,
    delivery_address VARCHAR(255) NOT NULL,
    drop_zone_latitude DECIMAL(9, 6) NOT NULL,
    drop_zone_longitude DECIMAL(9, 6) NOT NULL,
    delivery_status VARCHAR(20) DEFAULT 'Processing' NOT NULL,
    CONSTRAINT pk_delivery_packages PRIMARY KEY (package_id),
    CONSTRAINT uq_tracking_num UNIQUE (tracking_number),
    CONSTRAINT fk_packages_missions FOREIGN KEY (mission_id)
        REFERENCES dbo.flight_missions (mission_id) ON DELETE CASCADE,
    CONSTRAINT fk_packages_customers FOREIGN KEY (customer_id)
        REFERENCES dbo.customers (customer_id) ON DELETE NO ACTION,
    CONSTRAINT chk_pkg_weight CHECK (package_weight_lbs > 0.00),
    CONSTRAINT chk_drop_lat CHECK (drop_zone_latitude BETWEEN -90.000000 AND 90.000000),
    CONSTRAINT chk_drop_lon CHECK (drop_zone_longitude BETWEEN -180.000000 AND 180.000000),
    CONSTRAINT chk_delivery_status CHECK (delivery_status IN ('Processing', 'Manifested', 'En-Route', 'Delivered', 'Failed'))
);
GO

-- MAINTENANCE LOGS
CREATE TABLE dbo.maintenance_logs (
    maintenance_id INT IDENTITY(1,1),
    drone_id INT NOT NULL,
    technician_name VARCHAR(100) NOT NULL,
    maintenance_date DATE NOT NULL,
    airframe_hours_at_service DECIMAL(8, 2) NOT NULL,
    work_performed_summary VARCHAR(1000) NOT NULL,
    components_replaced VARCHAR(500),
    faa_compliance_signoff BIT DEFAULT 0 NOT NULL,
    CONSTRAINT pk_maintenance_logs PRIMARY KEY (maintenance_id),
    CONSTRAINT fk_maintenance_drones FOREIGN KEY (drone_id)
        REFERENCES dbo.drones (drone_id) ON DELETE CASCADE,
    CONSTRAINT chk_maintenance_hours CHECK (airframe_hours_at_service >= 0.00)
);
GO

-- FLIGHT TELEMETRY LOGS
CREATE TABLE dbo.flight_telemetry_logs (
    telemetry_id BIGINT IDENTITY(1,1),
    mission_id INT NOT NULL,
    reading_timestamp DATETIME NOT NULL,
    current_latitude DECIMAL(9, 6) NOT NULL,
    current_longitude DECIMAL(9, 6) NOT NULL,
    altitude_meters DECIMAL(6, 2) NOT NULL,
    battery_temp_c DECIMAL(5, 2) NOT NULL,
    signal_strength_dbm INT NOT NULL,
    CONSTRAINT pk_flight_telemetry_logs PRIMARY KEY (telemetry_id),
    CONSTRAINT fk_telemetry_missions FOREIGN KEY (mission_id)
        REFERENCES dbo.flight_missions (mission_id) ON DELETE CASCADE,
    CONSTRAINT chk_telemetry_lat CHECK (current_latitude BETWEEN -90.000000 AND 90.000000),
    CONSTRAINT chk_telemetry_lon CHECK (current_longitude BETWEEN -180.000000 AND 180.000000)
);
GO

CREATE INDEX idx_telemetry_mission_time ON dbo.flight_telemetry_logs (mission_id, reading_timestamp DESC);
CREATE INDEX idx_packages_mission ON dbo.delivery_packages (mission_id);
CREATE INDEX idx_missions_drone ON dbo.flight_missions (drone_id);
GO
