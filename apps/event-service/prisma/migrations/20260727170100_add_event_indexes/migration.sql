CREATE INDEX IF NOT EXISTS "events_date_idx" ON "events"("date");
CREATE INDEX IF NOT EXISTS "events_type_idx" ON "events"("type");
CREATE INDEX IF NOT EXISTS "events_deletedAt_idx" ON "events"("deletedAt");
