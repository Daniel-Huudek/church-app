-- CreateTable
CREATE TABLE "Schedule" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "ministryId" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "startTime" TEXT NOT NULL,
    "endTime" TEXT NOT NULL,
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Schedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SchedulePosition" (
    "id" TEXT NOT NULL,
    "scheduleId" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "position" TEXT NOT NULL,
    "isConfirmed" BOOLEAN NOT NULL DEFAULT false,
    "isSubstituted" BOOLEAN NOT NULL DEFAULT false,
    "substitutedById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SchedulePosition_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Schedule_eventId_idx" ON "Schedule"("eventId");

-- CreateIndex
CREATE INDEX "Schedule_ministryId_idx" ON "Schedule"("ministryId");

-- CreateIndex
CREATE INDEX "Schedule_deletedAt_idx" ON "Schedule"("deletedAt");

-- CreateIndex
CREATE INDEX "SchedulePosition_memberId_idx" ON "SchedulePosition"("memberId");

-- CreateIndex
CREATE INDEX "SchedulePosition_scheduleId_idx" ON "SchedulePosition"("scheduleId");

-- AddForeignKey
ALTER TABLE "SchedulePosition" ADD CONSTRAINT "SchedulePosition_scheduleId_fkey" FOREIGN KEY ("scheduleId") REFERENCES "Schedule"("id") ON DELETE CASCADE ON UPDATE CASCADE;

