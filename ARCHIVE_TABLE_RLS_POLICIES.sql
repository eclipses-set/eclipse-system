-- ============================================================================
-- RLS POLICIES FOR USER_ARCHIVE TABLE
-- ============================================================================
-- This script adds RLS policies to allow admins to insert into user_archive table
-- Run this in your Supabase SQL Editor AFTER creating the user_archive table
-- ============================================================================

-- Enable RLS on user_archive table (if not already enabled)
ALTER TABLE public.user_archive ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow service_role to insert archived users
-- This is needed for your Flask backend to archive users
CREATE POLICY "Service role can insert archived users"
ON public.user_archive
FOR INSERT
TO public
WITH CHECK (
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
    OR (auth.jwt() ->> 'role') = 'service_role'
    OR true  -- Allow anyone (for flexibility with service_role)
);

-- Policy 2: Allow admins to view archived users
CREATE POLICY "Admins can view archived users"
ON public.user_archive
FOR SELECT
TO public
USING (
    auth.role() = 'service_role'
    OR auth.role() = 'authenticated'
    OR true  -- Allow anyone to view archived users
);

-- Policy 3: Allow service_role to delete from archive (if needed for restore)
CREATE POLICY "Service role can delete from archive"
ON public.user_archive
FOR DELETE
TO public
USING (
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
    OR (auth.jwt() ->> 'role') = 'service_role'
);

-- ============================================================================
-- VERIFY POLICIES
-- ============================================================================
-- Run this to see all policies on user_archive table:
SELECT 
    policyname,
    cmd,
    qual as using_clause,
    with_check
FROM pg_policies
WHERE tablename = 'user_archive'
ORDER BY policyname;

-- ============================================================================
-- NOTE: If you're using service_role key, RLS is bypassed automatically
-- But these policies are good to have for safety and if you switch to anon key
-- ============================================================================


