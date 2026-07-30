-- AlterTable
ALTER TABLE "WorshipEvent" ADD COLUMN "ministerMemberId" TEXT;

-- CreateIndex
CREATE INDEX "WorshipEvent_ministerMemberId_idx" ON "WorshipEvent"("ministerMemberId");
