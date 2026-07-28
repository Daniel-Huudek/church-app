-- Single database for the modular monolith API.
-- Kept for volume init compatibility; POSTGRES_DB already creates church_db.
SELECT 'church_db ready' AS status;
