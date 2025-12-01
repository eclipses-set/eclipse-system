-- ============================================================================
-- SAFE USER ARCHIVE TABLE CREATION
-- ============================================================================
-- This script safely creates the user_archive table without errors
-- It handles cases where the table or constraints already exist
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- Create user_archive table (only if it doesn't exist)
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

-- Create indexes (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_user_archive_user_id ON public.user_archive(user_id);
CREATE INDEX IF NOT EXISTS idx_user_archive_user_type ON public.user_archive(user_type);
CREATE INDEX IF NOT EXISTS idx_user_archive_archived_at ON public.user_archive(archived_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_archive_archived_by ON public.user_archive(archived_by);

-- Add comments for documentation (won't error if already exists)
COMMENT ON TABLE public.user_archive IS 'Stores archived users (both admin and student accounts)';
COMMENT ON COLUMN public.user_archive.archive_id IS 'Primary key, auto-incrementing archive record ID';
COMMENT ON COLUMN public.user_archive.user_id IS 'Original user ID (admin_id for admin, user_id for student)';
COMMENT ON COLUMN public.user_archive.user_type IS 'Type of user: admin or student';
COMMENT ON COLUMN public.user_archive.archived_by IS 'Admin ID who archived this user';
COMMENT ON COLUMN public.user_archive.archive_reason IS 'Reason for archiving the user';
COMMENT ON COLUMN public.user_archive.archived_at IS 'Timestamp when user was archived';

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this to verify the table was created correctly:
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_archive' 
ORDER BY ordinal_position;

-- ============================================================================
-- NEXT STEP: Run ARCHIVE_TABLE_RLS_POLICIES.sql after this
-- ============================================================================


