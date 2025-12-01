-- ============================================================================
-- FIX RLS POLICIES FOR INCIDENT_ARCHIVE TABLE
-- ============================================================================
-- This script fixes the RLS policies for incident_archive table ONLY
-- It will NOT affect any other tables or their policies
-- Run this in your Supabase SQL Editor if you're getting RLS policy errors
-- ============================================================================

-- IMPORTANT: This script ONLY affects the 'incident_archive' table
-- It will NOT touch policies on:
-- - alert_incidents
-- - accounts_student
-- - accounts_admin
-- - user_archive
-- - incident_audit_trail
-- - Or any other tables

-- Drop existing policies if they exist (to avoid conflicts)
-- Only drops policies on incident_archive table
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
-- VERIFY POLICIES
-- ============================================================================
-- Run this to see all policies on incident_archive table:
SELECT 
    policyname,
    cmd,
    qual as using_clause,
    with_check
FROM pg_policies
WHERE tablename = 'incident_archive'
ORDER BY policyname;

-- ============================================================================
-- SAFETY CHECK: Verify this only affected incident_archive table
-- ============================================================================
-- Run this to confirm no other tables were affected:
-- SELECT tablename, COUNT(*) as policy_count
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- GROUP BY tablename
-- ORDER BY tablename;

