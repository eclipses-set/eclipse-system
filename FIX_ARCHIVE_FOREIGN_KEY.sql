-- ============================================================================
-- FIX FOREIGN KEY CONSTRAINT FOR ARCHIVING INCIDENTS
-- ============================================================================
-- This script provides options to handle foreign key constraints when archiving
-- incidents that have related resolution reports
-- ============================================================================

-- OPTION 1: Change foreign key to CASCADE on delete (Recommended)
-- This will automatically delete resolution reports when an incident is deleted
-- ============================================================================

-- First, drop the existing foreign key constraint
DO $$
BEGIN
    -- Find and drop the existing foreign key constraint
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'incident_resolution_reports_icd_id_fkey'
        AND table_name = 'incident_resolution_reports'
    ) THEN
        ALTER TABLE public.incident_resolution_reports
        DROP CONSTRAINT incident_resolution_reports_icd_id_fkey;
        
        -- Recreate with CASCADE on delete
        ALTER TABLE public.incident_resolution_reports
        ADD CONSTRAINT incident_resolution_reports_icd_id_fkey
        FOREIGN KEY (icd_id)
        REFERENCES public.alert_incidents(icd_id)
        ON DELETE CASCADE;
        
        RAISE NOTICE 'Foreign key constraint updated to CASCADE on delete';
    ELSE
        RAISE NOTICE 'Foreign key constraint not found. It may have a different name.';
    END IF;
END $$;

-- ============================================================================
-- OPTION 2: Set foreign key to NULL on delete (Alternative)
-- This keeps the resolution reports but removes the reference
-- Uncomment below if you prefer this approach instead of Option 1
-- ============================================================================

/*
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'incident_resolution_reports_icd_id_fkey'
        AND table_name = 'incident_resolution_reports'
    ) THEN
        ALTER TABLE public.incident_resolution_reports
        DROP CONSTRAINT incident_resolution_reports_icd_id_fkey;
        
        -- Recreate with SET NULL on delete (requires icd_id to be nullable)
        ALTER TABLE public.incident_resolution_reports
        ALTER COLUMN icd_id DROP NOT NULL;  -- Make nullable if not already
        
        ALTER TABLE public.incident_resolution_reports
        ADD CONSTRAINT incident_resolution_reports_icd_id_fkey
        FOREIGN KEY (icd_id)
        REFERENCES public.alert_incidents(icd_id)
        ON DELETE SET NULL;
        
        RAISE NOTICE 'Foreign key constraint updated to SET NULL on delete';
    END IF;
END $$;
*/

-- ============================================================================
-- VERIFY THE CONSTRAINT
-- ============================================================================
-- Run this to see the foreign key constraint details:
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
    ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'incident_resolution_reports'
    AND kcu.column_name = 'icd_id';

-- The delete_rule should show 'CASCADE' after running Option 1

