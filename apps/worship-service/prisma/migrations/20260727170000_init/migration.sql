-- CreateEnum
CREATE TYPE "SongKey" AS ENUM ('C', 'Cm', 'C7', 'Cm7', 'Cs', 'Csm', 'D', 'Dm', 'D7', 'Dm7', 'Eb', 'Ebm', 'E', 'Em', 'E7', 'Em7', 'F', 'Fm', 'F7', 'Fm7', 'Fs', 'Fsm', 'G', 'Gm', 'G7', 'Gm7', 'Ab', 'Abm', 'A', 'Am', 'A7', 'Am7', 'Bb', 'Bbm', 'B', 'Bm', 'B7', 'Bm7');

-- CreateTable
CREATE TABLE "Song" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "artist" TEXT,
    "key" TEXT,
    "bpm" INTEGER,
    "duration" INTEGER,
    "lyrics" TEXT,
    "chords" TEXT,
    "capo" INTEGER,
    "youtubeUrl" TEXT,
    "thumbnail" TEXT,
    "notes" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Song_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Tag" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT NOT NULL DEFAULT '#008CFF',

    CONSTRAINT "Tag_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SongTag" (
    "songId" TEXT NOT NULL,
    "tagId" TEXT NOT NULL,

    CONSTRAINT "SongTag_pkey" PRIMARY KEY ("songId","tagId")
);

-- CreateTable
CREATE TABLE "Playlist" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "createdBy" TEXT NOT NULL,
    "isPublic" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Playlist_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlaylistSong" (
    "id" TEXT NOT NULL,
    "playlistId" TEXT NOT NULL,
    "songId" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "notes" TEXT,
    "transpose" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "PlaylistSong_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorshipEvent" (
    "id" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "playlistId" TEXT,
    "notes" TEXT,
    "estimatedTime" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WorshipEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorshipEventSong" (
    "id" TEXT NOT NULL,
    "worshipEventId" TEXT NOT NULL,
    "songId" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "transpose" INTEGER NOT NULL DEFAULT 0,
    "notes" TEXT,

    CONSTRAINT "WorshipEventSong_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorshipEventMusician" (
    "id" TEXT NOT NULL,
    "worshipEventId" TEXT NOT NULL,
    "memberId" TEXT NOT NULL,
    "instrument" TEXT,
    "role" TEXT,
    "isConfirmed" BOOLEAN NOT NULL DEFAULT false,
    "isSubstituted" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "WorshipEventMusician_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Favorite" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "songId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Favorite_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SongHistory" (
    "id" TEXT NOT NULL,
    "songId" TEXT NOT NULL,
    "eventId" TEXT,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SongHistory_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PlaylistSong_playlistId_idx" ON "PlaylistSong"("playlistId");

-- CreateIndex
CREATE INDEX "PlaylistSong_songId_idx" ON "PlaylistSong"("songId");

-- CreateIndex
CREATE UNIQUE INDEX "WorshipEvent_eventId_key" ON "WorshipEvent"("eventId");

-- CreateIndex
CREATE UNIQUE INDEX "WorshipEvent_playlistId_key" ON "WorshipEvent"("playlistId");

-- CreateIndex
CREATE INDEX "WorshipEventSong_worshipEventId_idx" ON "WorshipEventSong"("worshipEventId");

-- CreateIndex
CREATE INDEX "WorshipEventMusician_worshipEventId_idx" ON "WorshipEventMusician"("worshipEventId");

-- CreateIndex
CREATE INDEX "Favorite_userId_idx" ON "Favorite"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Favorite_userId_songId_key" ON "Favorite"("userId", "songId");

-- CreateIndex
CREATE INDEX "SongHistory_songId_idx" ON "SongHistory"("songId");

-- CreateIndex
CREATE INDEX "SongHistory_date_idx" ON "SongHistory"("date");

-- AddForeignKey
ALTER TABLE "SongTag" ADD CONSTRAINT "SongTag_songId_fkey" FOREIGN KEY ("songId") REFERENCES "Song"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SongTag" ADD CONSTRAINT "SongTag_tagId_fkey" FOREIGN KEY ("tagId") REFERENCES "Tag"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlaylistSong" ADD CONSTRAINT "PlaylistSong_playlistId_fkey" FOREIGN KEY ("playlistId") REFERENCES "Playlist"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlaylistSong" ADD CONSTRAINT "PlaylistSong_songId_fkey" FOREIGN KEY ("songId") REFERENCES "Song"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorshipEvent" ADD CONSTRAINT "WorshipEvent_playlistId_fkey" FOREIGN KEY ("playlistId") REFERENCES "Playlist"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorshipEventSong" ADD CONSTRAINT "WorshipEventSong_worshipEventId_fkey" FOREIGN KEY ("worshipEventId") REFERENCES "WorshipEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorshipEventSong" ADD CONSTRAINT "WorshipEventSong_songId_fkey" FOREIGN KEY ("songId") REFERENCES "Song"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorshipEventMusician" ADD CONSTRAINT "WorshipEventMusician_worshipEventId_fkey" FOREIGN KEY ("worshipEventId") REFERENCES "WorshipEvent"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Favorite" ADD CONSTRAINT "Favorite_songId_fkey" FOREIGN KEY ("songId") REFERENCES "Song"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SongHistory" ADD CONSTRAINT "SongHistory_songId_fkey" FOREIGN KEY ("songId") REFERENCES "Song"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- Additional FK indexes
CREATE INDEX IF NOT EXISTS "SongTag_tagId_idx" ON "SongTag"("tagId");
CREATE INDEX IF NOT EXISTS "WorshipEventSong_songId_idx" ON "WorshipEventSong"("songId");
CREATE INDEX IF NOT EXISTS "WorshipEventMusician_memberId_idx" ON "WorshipEventMusician"("memberId");
CREATE INDEX IF NOT EXISTS "Favorite_songId_idx" ON "Favorite"("songId");
