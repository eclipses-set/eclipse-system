-- ============================================================================
-- INCIDENT ARCHIVE TABLE SETUP FOR SUPABASE
-- ============================================================================
-- This script creates a table to store archived incidents
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- Create incident_archive table (only if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.incident_archive (
    archive_id BIGSERIAL PRIMARY KEY,
    icd_id VARCHAR(255) NOT NULL,
    icd_timestamp TIMESTAMPTZ,
    resolved_timestamp TIMESTAMPTZ,
    pending_timestamp TIMESTAMPTZ,
    cancelled_timestamp TIMESTAMPTZ,
    icd_status VARCHAR(50),
    icd_lat DECIMAL(10, 8),
    icd_lng DECIMAL(11, 8),
    assigned_responder_id VARCHAR(255),
    status_updated_at TIMESTAMPTZ,
    status_updated_by VARCHAR(255),
    icd_category VARCHAR(100),
    icd_medical_type VARCHAR(100),
    icd_security_type VARCHAR(100),
    icd_university_type VARCHAR(100),
    icd_description TEXT,
    icd_image VARCHAR(255),
    user_id VARCHAR(255),
    archived_by VARCHAR(255) NOT NULL,
    archive_reason TEXT,
    archived_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_incident_archive_icd_id ON public.incident_archive(icd_id);
CREATE INDEX IF NOT EXISTS idx_incident_archive_archived_at ON public.incident_archive(archived_at DESC);
CREATE INDEX IF NOT EXISTS idx_incident_archive_archived_by ON public.incident_archive(archived_by);
CREATE INDEX IF NOT EXISTS idx_incident_archive_status ON public.incident_archive(icd_status);

-- Add comments for documentation
COMMENT ON TABLE public.incident_archive IS 'Stores archived incidents from the alert_incidents table';
COMMENT ON COLUMN public.incident_archive.archive_id IS 'Primary key, auto-incrementing archive record ID';
COMMENT ON COLUMN public.incident_archive.icd_id IS 'Original incident ID';
COMMENT ON COLUMN public.incident_archive.archived_by IS 'Admin ID who archived this incident';
COMMENT ON COLUMN public.incident_archive.archive_reason IS 'Reason for archiving the incident';
COMMENT ON COLUMN public.incident_archive.archived_at IS 'Timestamp when incident was archived';

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Enable RLS on the table
ALTER TABLE public.incident_archive ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to read archived incidents" ON public.incident_archive;
DROP POLICY IF EXISTS "Allow authenticated users to insert archived incidents" ON public.incident_archive;
DROP POLICY IF EXISTS "Allow authenticated users to delete archived incidents" ON public.incident_archive;
DROP POLICY IF EXISTS "Service role can read archived incidents" ON public.incident_archive;
DROP POLICY IF EXISTS "Service role can insert archived incidents" ON public.incident_archive;
DROP POLICY IF EXISTS "Service role can delete archived incidents" ON public.incident_archive;

-- Policy 1: Allow service_role to read archived incidents
-- This works when using service_role key (Flask backend)
CREATE POLICY "Service role can read archived incidents"
ON public.incident_archive
FOR SELECT
TO public
USING (
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
    OR (auth.jwt() ->> 'role') = 'service_role'
    OR true  -- Allow anyone (for flexibility with service_role)
);

-- Policy 2: Allow service_role to insert archived incidents
-- This is needed for your Flask backend to archive incidents
CREATE POLICY "Service role can insert archived incidents"
ON public.incident_archive
FOR INSERT
TO public
WITH CHECK (
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
    OR (auth.jwt() ->> 'role') = 'service_role'
    OR true  -- Allow anyone (for flexibility with service_role)
);

-- Policy 3: Allow service_role to delete archived incidents (for restore)
CREATE POLICY "Service role can delete archived incidents"
ON public.incident_archive
FOR DELETE
TO public
USING (
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
    OR (auth.jwt() ->> 'role') = 'service_role'
    OR true  -- Allow anyone (for flexibility with service_role)
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- Run these after creating the table to verify it was created correctly:
-- SELECT table_name, column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'incident_archive'
-- ORDER BY ordinal_position;

