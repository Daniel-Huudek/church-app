ALTER TABLE "notifications" ADD COLUMN "isRead" BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX "notifications_isRead_idx" ON "notifications"("isRead");
