-- CreateTable
CREATE TABLE "prayer_requests" (
    "id" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "categoryId" TEXT,
    "isPublic" BOOLEAN NOT NULL DEFAULT true,
    "isAnonymous" BOOLEAN NOT NULL DEFAULT false,
    "isUrgent" BOOLEAN NOT NULL DEFAULT false,
    "isAnswered" BOOLEAN NOT NULL DEFAULT false,
    "answeredAt" TIMESTAMP(3),
    "answeredBy" TEXT,
    "viewsCount" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "prayer_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prayer_categories" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT,
    "icon" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "prayer_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prayer_comments" (
    "id" TEXT NOT NULL,
    "prayerId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "prayer_comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prayer_reactions" (
    "id" TEXT NOT NULL,
    "prayerId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "prayer_reactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "intercessors" (
    "id" TEXT NOT NULL,
    "prayerId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "intercessors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_favorites" (
    "id" TEXT NOT NULL,
    "prayerId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_favorites_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "prayer_requests_authorId_idx" ON "prayer_requests"("authorId");

-- CreateIndex
CREATE INDEX "prayer_requests_categoryId_idx" ON "prayer_requests"("categoryId");

-- CreateIndex
CREATE INDEX "prayer_requests_answeredBy_idx" ON "prayer_requests"("answeredBy");

-- CreateIndex
CREATE UNIQUE INDEX "prayer_categories_name_key" ON "prayer_categories"("name");

-- CreateIndex
CREATE INDEX "prayer_comments_prayerId_idx" ON "prayer_comments"("prayerId");

-- CreateIndex
CREATE INDEX "prayer_comments_authorId_idx" ON "prayer_comments"("authorId");

-- CreateIndex
CREATE INDEX "prayer_reactions_prayerId_idx" ON "prayer_reactions"("prayerId");

-- CreateIndex
CREATE INDEX "prayer_reactions_userId_idx" ON "prayer_reactions"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "prayer_reactions_prayerId_userId_type_key" ON "prayer_reactions"("prayerId", "userId", "type");

-- CreateIndex
CREATE INDEX "intercessors_prayerId_idx" ON "intercessors"("prayerId");

-- CreateIndex
CREATE INDEX "intercessors_userId_idx" ON "intercessors"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "intercessors_prayerId_userId_key" ON "intercessors"("prayerId", "userId");

-- CreateIndex
CREATE INDEX "user_favorites_prayerId_idx" ON "user_favorites"("prayerId");

-- CreateIndex
CREATE INDEX "user_favorites_userId_idx" ON "user_favorites"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "user_favorites_prayerId_userId_key" ON "user_favorites"("prayerId", "userId");

-- AddForeignKey
ALTER TABLE "prayer_requests" ADD CONSTRAINT "prayer_requests_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "prayer_categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prayer_comments" ADD CONSTRAINT "prayer_comments_prayerId_fkey" FOREIGN KEY ("prayerId") REFERENCES "prayer_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prayer_reactions" ADD CONSTRAINT "prayer_reactions_prayerId_fkey" FOREIGN KEY ("prayerId") REFERENCES "prayer_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "intercessors" ADD CONSTRAINT "intercessors_prayerId_fkey" FOREIGN KEY ("prayerId") REFERENCES "prayer_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_favorites" ADD CONSTRAINT "user_favorites_prayerId_fkey" FOREIGN KEY ("prayerId") REFERENCES "prayer_requests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

