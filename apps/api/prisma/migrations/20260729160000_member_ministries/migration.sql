-- CreateTable
CREATE TABLE "member_ministries" (
    "id" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "ministryId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "member_ministries_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "member_ministries_memberId_idx" ON "member_ministries"("memberId");

-- CreateIndex
CREATE INDEX "member_ministries_ministryId_idx" ON "member_ministries"("ministryId");

-- CreateIndex
CREATE UNIQUE INDEX "member_ministries_memberId_ministryId_key" ON "member_ministries"("memberId", "ministryId");

-- AddForeignKey
ALTER TABLE "member_ministries" ADD CONSTRAINT "member_ministries_memberId_fkey" FOREIGN KEY ("memberId") REFERENCES "members"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "member_ministries" ADD CONSTRAINT "member_ministries_ministryId_fkey" FOREIGN KEY ("ministryId") REFERENCES "ministries"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Backfill existing primary ministry links
INSERT INTO "member_ministries" ("id", "memberId", "ministryId", "createdAt")
SELECT m."id" || ':' || m."ministryId", m."id", m."ministryId", CURRENT_TIMESTAMP
FROM "members" m
WHERE m."ministryId" IS NOT NULL
  AND m."deletedAt" IS NULL
ON CONFLICT ("memberId", "ministryId") DO NOTHING;
