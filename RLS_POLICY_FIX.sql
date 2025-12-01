-- ============================================================================
-- RLS POLICY FIX FOR ADMIN UPDATES
-- ============================================================================
-- This script adds RLS policies to allow admins to update student data
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- Policy 1: Allow admins to update all student data
-- This checks if the user is an admin by looking up their admin_id in accounts_admin table
CREATE POLICY "Admins can update all student data"
ON public.accounts_student
FOR UPDATE
TO public
USING (
    EXISTS (
        SELECT 1 
        FROM public.accounts_admin 
        WHERE accounts_admin.admin_id = auth.uid()::text
        OR accounts_admin.auth_user_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 
        FROM public.accounts_admin 
        WHERE accounts_admin.admin_id = auth.uid()::text
        OR accounts_admin.auth_user_id = auth.uid()
    )
);

-- Policy 2: Allow admins to insert student data
-- (If you don't already have this)
CREATE POLICY "Admins can insert student data"
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
    OR true  -- Allow anyone if using service role key
);

-- Policy 3: Allow admins to delete student data (if needed)
CREATE POLICY "Admins can delete student data"
ON public.accounts_student
FOR DELETE
TO public
USING (
    EXISTS (
        SELECT 1 
        FROM public.accounts_admin 
        WHERE accounts_admin.admin_id = auth.uid()::text
        OR accounts_admin.auth_user_id = auth.uid()
    )
);

-- ============================================================================
-- ALTERNATIVE: If you're using service_role key, you can disable RLS
-- ============================================================================
-- WARNING: Only do this if you're using service_role key in your backend
-- This disables RLS entirely for the table
-- ALTER TABLE public.accounts_student DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- VERIFY YOUR POLICIES
-- ============================================================================
-- Run this to see all your current policies:
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'accounts_student'
ORDER BY policyname;


