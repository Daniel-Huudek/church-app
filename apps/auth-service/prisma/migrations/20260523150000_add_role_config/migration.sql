-- Add missing Permission enum values (if not already present)
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'members_export';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'members_import';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'ministries_write';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'ministries_delete';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'schedules_read';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'schedules_write';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'schedules_delete';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'events_read';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'events_write';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'events_delete';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'prayers_read';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'prayers_write';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'prayers_delete';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'prayers_comment';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'prayers_react';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'finance_read';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'finance_write';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'finance_delete';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'finance_export';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'finance_audit';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'finance_close';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'finance_reports';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'notifications_send';

-- Create RoleConfig table
CREATE TABLE "RoleConfig" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "permissions" TEXT[] NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "RoleConfig_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "RoleConfig_name_key" ON "RoleConfig"("name");
