-- ============================================================================
-- USER ARCHIVE TABLE SETUP FOR SUPABASE
-- ============================================================================
-- This script creates a table to store archived users (both admin and student)
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- Drop existing table if you want to recreate it (uncomment if needed)
-- DROP TABLE IF EXISTS public.user_archive CASCADE;

-- Create user_archive table
CREATE TABLE IF NOT EXISTS public.user_archive (
    archive_id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    user_type VARCHAR(50) NOT NULL,
    
    -- Admin fields (nullable, only populated for admin users)
    admin_id VARCHAR(255),
    admin_user VARCHAR(255),
    admin_email VARCHAR(255),
    admin_fullname VARCHAR(255),
    admin_role VARCHAR(255),
    admin_status VARCHAR(50),
    admin_approval VARCHAR(50),
    admin_profile VARCHAR(255),
    admin_pass TEXT,
    admin_created_at TIMESTAMPTZ,
    admin_last_login TIMESTAMPTZ,
    auth_user_id VARCHAR(255),
    
    -- Student fields (nullable, only populated for student users)
    student_id VARCHAR(255),
    student_user VARCHAR(255),
    student_email VARCHAR(255),
    full_name VARCHAR(255),
    student_yearlvl VARCHAR(50),
    student_college VARCHAR(255),
    student_cnum VARCHAR(50),
    student_status VARCHAR(50),
    student_profile VARCHAR(255),
    student_pass TEXT,
    student_address TEXT,
    student_medinfo TEXT,
    residency VARCHAR(50),
    email_verified BOOLEAN DEFAULT FALSE,
    student_created_at TIMESTAMPTZ,
    student_last_login TIMESTAMPTZ,
    
    -- Emergency contacts (for students)
    primary_emergencycontact VARCHAR(50),
    primary_contactperson VARCHAR(255),
    primary_cprelationship VARCHAR(100),
    secondary_emergencycontact VARCHAR(50),
    secondary_contactperson VARCHAR(255),
    secondary_cprelationship VARCHAR(100),
    
    -- Archive metadata
    archived_by VARCHAR(255) NOT NULL,
    archive_reason TEXT,
    archived_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add check constraint only if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'user_archive_user_type_check'
    ) THEN
        ALTER TABLE public.user_archive 
        ADD CONSTRAINT user_archive_user_type_check 
        CHECK (user_type IN ('admin', 'student'));
    END IF;
END $$;

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_user_archive_user_id ON public.user_archive(user_id);
CREATE INDEX IF NOT EXISTS idx_user_archive_user_type ON public.user_archive(user_type);
CREATE INDEX IF NOT EXISTS idx_user_archive_archived_at ON public.user_archive(archived_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_archive_archived_by ON public.user_archive(archived_by);

-- Add comments for documentation
COMMENT ON TABLE public.user_archive IS 'Stores archived users (both admin and student accounts)';
COMMENT ON COLUMN public.user_archive.archive_id IS 'Primary key, auto-incrementing archive record ID';
COMMENT ON COLUMN public.user_archive.user_id IS 'Original user ID (admin_id for admin, user_id for student)';
COMMENT ON COLUMN public.user_archive.user_type IS 'Type of user: admin or student';
COMMENT ON COLUMN public.user_archive.archived_by IS 'Admin ID who archived this user';
COMMENT ON COLUMN public.user_archive.archive_reason IS 'Reason for archiving the user';
COMMENT ON COLUMN public.user_archive.archived_at IS 'Timestamp when user was archived';

-- Grant necessary permissions (adjust based on your Supabase setup)
-- These permissions are usually handled automatically by Supabase

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these after creating the table to verify it was created correctly:

-- Check if table exists
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' AND table_name = 'user_archive';

-- Check table structure
-- SELECT column_name, data_type, is_nullable 
-- FROM information_schema.columns 
-- WHERE table_name = 'user_archive' 
-- ORDER BY ordinal_position;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================





