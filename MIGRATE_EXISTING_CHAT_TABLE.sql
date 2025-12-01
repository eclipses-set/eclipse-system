-- ============================================================================
-- MIGRATION SCRIPT FOR EXISTING chat_messages TABLE
-- This script adds missing components to your existing table
-- Safe to run multiple times - it checks if components exist first
-- ============================================================================

-- Step 1: Add image_url column if it doesn't exist
-- ============================================================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'chat_messages' 
      AND column_name = 'image_url'
  ) THEN
    ALTER TABLE public.chat_messages 
    ADD COLUMN image_url character varying(500) NULL;
    
    COMMENT ON COLUMN public.chat_messages.image_url IS 'URL or filename of image attached to the message';
    
    RAISE NOTICE 'Added image_url column to chat_messages table';
  ELSE
    RAISE NOTICE 'image_url column already exists';
  END IF;
END $$;

-- Step 2: Add foreign key constraint if it doesn't exist
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_schema = 'public' 
      AND table_name = 'chat_messages' 
      AND constraint_name = 'fk_chat_messages_incident'
  ) THEN
    ALTER TABLE public.chat_messages
    ADD CONSTRAINT fk_chat_messages_incident 
    FOREIGN KEY (incident_id) 
    REFERENCES public.alert_incidents(icd_id) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE;
    
    RAISE NOTICE 'Added foreign key constraint fk_chat_messages_incident';
  ELSE
    RAISE NOTICE 'Foreign key constraint fk_chat_messages_incident already exists';
  END IF;
END $$;

-- Step 3: Create composite index for incident_id and timestamp if it doesn't exist
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_chat_messages_incident_timestamp 
  ON public.chat_messages USING btree (incident_id, timestamp DESC) 
  TABLESPACE pg_default;

-- Step 4: Create index for faster sender/receiver/timestamp queries if it doesn't exist
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver_timestamp 
  ON public.chat_messages USING btree (sender_id, receiver_id, timestamp DESC) 
  TABLESPACE pg_default;

-- Step 5: Create validation function
-- ============================================================================
CREATE OR REPLACE FUNCTION validate_chat_message_user_ids()
RETURNS TRIGGER AS $$
DECLARE
  incident_user_id TEXT;
BEGIN
  -- First, get the user_id (student_id) associated with the incident
  SELECT user_id::text INTO incident_user_id
  FROM public.alert_incidents
  WHERE icd_id = NEW.incident_id;
  
  -- If incident doesn't exist, the foreign key constraint will catch this
  -- But we check here for better error message
  IF incident_user_id IS NULL THEN
    RAISE EXCEPTION 'incident_id % does not exist in alert_incidents table', NEW.incident_id;
  END IF;
  
  -- Validate sender_id based on sender_type
  IF NEW.sender_type = 'student' THEN
    -- Check if student exists in accounts_student
    IF NOT EXISTS (SELECT 1 FROM public.accounts_student WHERE user_id::text = NEW.sender_id) THEN
      RAISE EXCEPTION 'sender_id % does not exist in accounts_student table', NEW.sender_id;
    END IF;
    
    -- CRITICAL: Validate that the sender student is the one who reported the incident
    IF NEW.sender_id != incident_user_id THEN
      RAISE EXCEPTION 'sender_id % is not the reporter of incident % (incident belongs to user_id: %)', 
        NEW.sender_id, NEW.incident_id, incident_user_id;
    END IF;
  END IF;
  
  -- Validate receiver_id based on receiver_type
  IF NEW.receiver_type = 'student' THEN
    -- Check if student exists in accounts_student
    IF NOT EXISTS (SELECT 1 FROM public.accounts_student WHERE user_id::text = NEW.receiver_id) THEN
      RAISE EXCEPTION 'receiver_id % does not exist in accounts_student table', NEW.receiver_id;
    END IF;
    
    -- CRITICAL: Validate that the receiver student is the one who reported the incident
    IF NEW.receiver_id != incident_user_id THEN
      RAISE EXCEPTION 'receiver_id % is not the reporter of incident % (incident belongs to user_id: %)', 
        NEW.receiver_id, NEW.incident_id, incident_user_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create trigger to validate user IDs on insert/update
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_validate_chat_message_user_ids ON public.chat_messages;
CREATE TRIGGER trigger_validate_chat_message_user_ids
  BEFORE INSERT OR UPDATE ON public.chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION validate_chat_message_user_ids();

-- Step 7: Add table and column comments for documentation
-- ============================================================================
COMMENT ON TABLE public.chat_messages IS 'Stores chat messages between admins and students for incident communication. All messages are permanently retained.';
COMMENT ON COLUMN public.chat_messages.incident_id IS 'Reference to the incident this message is related to (FK: alert_incidents.icd_id)';
COMMENT ON COLUMN public.chat_messages.sender_id IS 'ID of the message sender (admin_id or user_id depending on sender_type)';
COMMENT ON COLUMN public.chat_messages.sender_type IS 'Type of sender: admin or student';
COMMENT ON COLUMN public.chat_messages.receiver_id IS 'ID of the message receiver (admin_id or user_id depending on receiver_type)';
COMMENT ON COLUMN public.chat_messages.receiver_type IS 'Type of receiver: admin or student';
COMMENT ON COLUMN public.chat_messages.message IS 'The message content (text)';
COMMENT ON COLUMN public.chat_messages.is_read IS 'Whether the message has been read by the receiver';
COMMENT ON COLUMN public.chat_messages.timestamp IS 'When the message was sent (used for sorting and display)';
COMMENT ON COLUMN public.chat_messages.created_at IS 'When the record was created in the database (permanent record timestamp)';

-- Add comment for image_url if column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'chat_messages' 
      AND column_name = 'image_url'
  ) THEN
    COMMENT ON COLUMN public.chat_messages.image_url IS 'URL or filename of image attached to the message (optional)';
  END IF;
END $$;

-- Step 8: Verify the migration
-- ============================================================================
-- Run this query to verify everything is set up correctly:
SELECT 
  'Table Structure' as check_type,
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'chat_messages'
ORDER BY ordinal_position;

-- Check indexes
SELECT 
  'Indexes' as check_type,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'chat_messages'
ORDER BY indexname;

-- Check constraints
SELECT 
  'Constraints' as check_type,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' 
  AND table_name = 'chat_messages'
ORDER BY constraint_name;

-- Check triggers
SELECT 
  'Triggers' as check_type,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public' 
  AND event_object_table = 'chat_messages'
ORDER BY trigger_name;

-- ============================================================================
-- MIGRATION COMPLETE!
-- ============================================================================
-- Your existing chat_messages table has been updated with:
-- ✅ image_url column (for image attachments)
-- ✅ Foreign key constraint to alert_incidents
-- ✅ Additional indexes for better performance
-- ✅ Validation function and trigger for data integrity
-- ✅ Table and column comments for documentation
-- ============================================================================


















