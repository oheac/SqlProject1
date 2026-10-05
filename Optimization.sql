SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_telemetry_perf_proof')
    DROP INDEX idx_telemetry_perf_proof ON dbo.flight_telemetry_logs;
GO

SELECT
    mission_id,
    reading_timestamp,
    signal_strength_dbm
FROM
    dbo.flight_telemetry_logs
WHERE
    altitude_meters = 135.00
    AND battery_temp_c = 47.00;
GO

CREATE NONCLUSTERED INDEX idx_telemetry_perf_proof
ON dbo.flight_telemetry_logs (altitude_meters, battery_temp_c);
GO

SELECT
    mission_id,
    reading_timestamp,
    signal_strength_dbm
FROM
    dbo.flight_telemetry_logs
WHERE
    altitude_meters = 135.00
    AND battery_temp_c = 47.00;
GO
