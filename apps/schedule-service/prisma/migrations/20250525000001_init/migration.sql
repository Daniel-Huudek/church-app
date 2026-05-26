-- CreateTable
CREATE TABLE "schedules" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "ministryId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "startTime" TEXT NOT NULL,
    "endTime" TEXT NOT NULL,
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "schedules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "schedule_positions" (
    "id" TEXT NOT NULL,
    "scheduleId" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "position" TEXT NOT NULL,
    "isConfirmed" BOOLEAN NOT NULL DEFAULT false,
    "isSubstituted" BOOLEAN NOT NULL DEFAULT false,
    "substitutedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "schedule_positions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "schedules_eventId_idx" ON "schedules"("eventId");

-- CreateIndex
CREATE INDEX "schedules_ministryId_idx" ON "schedules"("ministryId");

-- CreateIndex
CREATE INDEX "schedules_deletedAt_idx" ON "schedules"("deletedAt");

-- CreateIndex
CREATE INDEX "schedule_positions_memberId_idx" ON "schedule_positions"("memberId");

-- CreateIndex
CREATE INDEX "schedule_positions_scheduleId_idx" ON "schedule_positions"("scheduleId");

-- AddForeignKey
ALTER TABLE "schedule_positions" ADD CONSTRAINT "schedule_positions_scheduleId_fkey" FOREIGN KEY ("scheduleId") REFERENCES "schedules"("id") ON DELETE CASCADE ON UPDATE CASCADE;
