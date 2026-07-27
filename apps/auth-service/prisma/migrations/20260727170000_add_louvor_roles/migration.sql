-- Add worship-related roles used by the app
ALTER TYPE "Role" ADD VALUE IF NOT EXISTS 'LOUVOR';
ALTER TYPE "Role" ADD VALUE IF NOT EXISTS 'LIDER_LOUVOR';
