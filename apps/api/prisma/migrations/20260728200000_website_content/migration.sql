-- CreateTable
CREATE TABLE "website_contents" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "content" JSONB NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "updatedBy" TEXT,

    CONSTRAINT "website_contents_pkey" PRIMARY KEY ("id")
);
