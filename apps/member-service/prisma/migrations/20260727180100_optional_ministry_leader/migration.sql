-- Allow ministries without a leader (e.g. auto-created Diáconos)
ALTER TABLE "ministries" ALTER COLUMN "leaderId" DROP NOT NULL;
