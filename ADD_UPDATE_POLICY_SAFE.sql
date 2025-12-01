-- ============================================================================
-- SAFE ADDITION: New UPDATE Policy for Service Role Key
-- ============================================================================
-- This adds a NEW policy without modifying or dropping any existing policies
-- PostgreSQL RLS uses OR logic - if ANY policy allows, the operation succeeds
-- ============================================================================

-- Add a new policy that allows service_role key to update
-- This works alongside your existing "Admins can update all student data" policy
-- PostgreSQL RLS uses OR logic - if ANY policy allows, the operation succeeds
CREATE POLICY "Service role can update student data"
ON public.accounts_student
FOR UPDATE
TO public
USING (
    -- Allow if using service_role key (backend requests)
    -- When service_role key is used, auth.uid() is NULL
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
    OR (auth.jwt() ->> 'role') = 'service_role'
)
WITH CHECK (
    -- Allow if using service_role key (backend requests)
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
    OR (auth.jwt() ->> 'role') = 'service_role'
);

-- ============================================================================
-- ALTERNATIVE: If the above doesn't work, try this simpler version
-- ============================================================================
-- Some Supabase setups don't expose auth.role() directly
-- This policy allows updates when there's no authenticated user (service_role scenario)

-- Uncomment this if the above policy doesn't work:
/*
CREATE POLICY "Backend service can update student data"
ON public.accounts_student
FOR UPDATE
TO public
USING (
    -- Allow when auth.uid() is NULL (service_role key scenario)
    -- OR when explicitly using service_role
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
)
WITH CHECK (
    auth.uid() IS NULL
    OR auth.role() = 'service_role'
);
*/

-- ============================================================================
-- VERIFY: Check your policies after adding
-- ============================================================================
-- Run this to see all UPDATE policies:
SELECT 
    policyname,
    cmd,
    qual as using_clause,
    with_check
FROM pg_policies
WHERE tablename = 'accounts_student'
AND cmd = 'UPDATE'
ORDER BY policyname;

-- You should now see:
-- 1. "Admins can update all student data" (your existing one)
-- 2. "Students can update their own data" (your existing one)
-- 3. "Service role can update student data" (the new one we just added)

-- ============================================================================
-- TEST: Try updating a record from your Flask app
-- ============================================================================
-- After adding this policy, test updating a student record from your Flask app
-- It should now work!

