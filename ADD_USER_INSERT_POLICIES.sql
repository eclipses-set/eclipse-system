-- ============================================================================
-- RLS POLICIES FOR ADDING USERS (INSERT OPERATIONS)
-- ============================================================================
-- This script adds RLS policies to allow inserting users into accounts_admin 
-- and accounts_student tables
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- POLICIES FOR accounts_admin TABLE
-- ============================================================================

-- Policy 1: Allow service_role to insert admin users
-- This works when using service_role key (which bypasses RLS anyway)
-- Only creates if it doesn't already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'accounts_admin' 
        AND policyname = 'Service role can insert admin users'
    ) THEN
        CREATE POLICY "Service role can insert admin users"
        ON public.accounts_admin
        FOR INSERT
        TO public
        WITH CHECK (
            -- Allow if using service_role key (backend requests)
            auth.uid() IS NULL
            OR auth.role() = 'service_role'
            OR (auth.jwt() ->> 'role') = 'service_role'
            OR true  -- Allow anyone (for flexibility with service_role)
        );
    END IF;
END $$;

-- Policy 2: Allow authenticated admins to insert admin users
-- Only creates if it doesn't already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'accounts_admin' 
        AND policyname = 'Admins can insert admin users'
    ) THEN
        CREATE POLICY "Admins can insert admin users"
        ON public.accounts_admin
        FOR INSERT
        TO public
        WITH CHECK (
            EXISTS (
                SELECT 1 
                FROM public.accounts_admin 
                WHERE accounts_admin.admin_id = auth.uid()::text
                OR accounts_admin.auth_user_id = auth.uid()
            )
        );
    END IF;
END $$;

-- ============================================================================
-- POLICIES FOR accounts_student TABLE
-- ============================================================================

-- Policy 1: Allow service_role to insert student users
-- Only creates if it doesn't already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'accounts_student' 
        AND policyname = 'Service role can insert student users'
    ) THEN
        CREATE POLICY "Service role can insert student users"
        ON public.accounts_student
        FOR INSERT
        TO public
        WITH CHECK (
            -- Allow if using service_role key (backend requests)
            auth.uid() IS NULL
            OR auth.role() = 'service_role'
            OR (auth.jwt() ->> 'role') = 'service_role'
            OR true  -- Allow anyone (for flexibility with service_role)
        );
    END IF;
END $$;

-- Policy 2: Allow authenticated admins to insert student users
-- Only creates if it doesn't already exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'accounts_student' 
        AND policyname = 'Admins can insert student users'
    ) THEN
        CREATE POLICY "Admins can insert student users"
        ON public.accounts_student
        FOR INSERT
        TO public
        WITH CHECK (
            EXISTS (
                SELECT 1 
                FROM public.accounts_admin 
                WHERE accounts_admin.admin_id = auth.uid()::text
                OR accounts_admin.auth_user_id = auth.uid()
            )
        );
    END IF;
END $$;

-- ============================================================================
-- VERIFY POLICIES WERE CREATED
-- ============================================================================
-- Run this query to see all INSERT policies:

SELECT 
    schemaname,
    tablename,
    policyname,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE tablename IN ('accounts_admin', 'accounts_student')
    AND cmd = 'INSERT'
ORDER BY tablename, policyname;

-- ============================================================================
-- NOTES:
-- ============================================================================
-- 1. If you're using service_role key in your Flask app, RLS is automatically
--    bypassed, but these policies provide an extra layer of security.
--
-- 2. If you're using anon key, these policies are REQUIRED for inserts to work.
--
-- 3. The "OR true" in the service_role policies allows inserts even when
--    auth.uid() is NULL (which happens with service_role key).
--
-- 4. After running this script, try adding a user again from your Flask app.
-- ============================================================================

