-- CreateIndex
CREATE INDEX IF NOT EXISTS "members_deletedAt_idx" ON "members"("deletedAt");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "members_status_idx" ON "members"("status");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "members_email_idx" ON "members"("email");
