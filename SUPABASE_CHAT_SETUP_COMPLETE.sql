-- ============================================================================
-- COMPLETE CHAT MESSAGES TABLE SETUP FOR SUPABASE
-- ============================================================================
-- This script ensures all chat conversations are properly stored and retained
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- Step 1: Create the chat_messages table (if it doesn't exist)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id bigserial NOT NULL,
  incident_id character varying(50) NOT NULL,
  sender_id character varying(100) NOT NULL,
  sender_type character varying(20) NOT NULL,
  receiver_id character varying(100) NOT NULL,
  receiver_type character varying(20) NOT NULL,
  message text NOT NULL,
  timestamp timestamp with time zone NULL DEFAULT now(),
  is_read boolean NULL DEFAULT false,
  created_at timestamp with time zone NULL DEFAULT now(),
  image_url character varying(500) NULL,
  CONSTRAINT chat_messages_pkey PRIMARY KEY (id),
  CONSTRAINT chat_messages_receiver_type_check CHECK (
    (
      (receiver_type)::text = ANY (
        (
          ARRAY[
            'admin'::character varying,
            'student'::character varying
          ]
        )::text[]
      )
    )
  ),
  CONSTRAINT chat_messages_sender_type_check CHECK (
    (
      (sender_type)::text = ANY (
        (
          ARRAY[
            'admin'::character varying,
            'student'::character varying
          ]
        )::text[]
      )
    )
  ),
  -- Foreign key constraint: incident_id references alert_incidents.icd_id
  CONSTRAINT fk_chat_messages_incident FOREIGN KEY (incident_id) 
    REFERENCES public.alert_incidents(icd_id) 
    ON DELETE CASCADE 
    ON UPDATE CASCADE
) TABLESPACE pg_default;

-- Step 2: Add image_url column if it doesn't exist
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
  END IF;
END $$;

-- Step 3: Create indexes for better query performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver 
  ON public.chat_messages USING btree (sender_id, receiver_id) 
  TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_chat_messages_receiver_read 
  ON public.chat_messages USING btree (receiver_id, is_read) 
  TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_chat_messages_incident 
  ON public.chat_messages USING btree (incident_id) 
  TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp 
  ON public.chat_messages USING btree (timestamp DESC) 
  TABLESPACE pg_default;

-- Create a composite index for incident_id and timestamp (useful for filtering messages by incident)
CREATE INDEX IF NOT EXISTS idx_chat_messages_incident_timestamp 
  ON public.chat_messages USING btree (incident_id, timestamp DESC) 
  TABLESPACE pg_default;

-- Index for faster retrieval of recent messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver_timestamp 
  ON public.chat_messages USING btree (sender_id, receiver_id, timestamp DESC) 
  TABLESPACE pg_default;

-- Step 4: Add table and column comments
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
COMMENT ON COLUMN public.chat_messages.image_url IS 'URL or filename of image attached to the message (optional)';

-- Step 5: Create validation function to ensure data integrity
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

-- Step 7: Ensure messages are never automatically deleted (retention policy)
-- ============================================================================
-- Note: By default, PostgreSQL/Supabase does NOT automatically delete data
-- The ON DELETE CASCADE on the foreign key only applies if the incident is deleted
-- To ensure messages are NEVER deleted, you can add a policy (if using Row Level Security)

-- Optional: Enable Row Level Security to prevent accidental deletions
-- ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Optional: Create a policy to prevent deletions (uncomment if you want extra protection)
-- CREATE POLICY "Prevent chat message deletion" ON public.chat_messages
--   FOR DELETE
--   USING (false);  -- This prevents all deletions

-- Step 8: Grant necessary permissions (adjust based on your Supabase setup)
-- ============================================================================
-- These permissions are usually handled automatically by Supabase
-- But you can explicitly grant if needed:
-- GRANT ALL ON public.chat_messages TO authenticated;
-- GRANT ALL ON public.chat_messages TO service_role;
-- GRANT USAGE, SELECT ON SEQUENCE public.chat_messages_id_seq TO authenticated;
-- GRANT USAGE, SELECT ON SEQUENCE public.chat_messages_id_seq TO service_role;

-- Step 9: Verify table structure
-- ============================================================================
-- Run this query to verify everything is set up correctly:
-- SELECT 
--   column_name, 
--   data_type, 
--   is_nullable,
--   column_default
-- FROM information_schema.columns 
-- WHERE table_schema = 'public' 
--   AND table_name = 'chat_messages'
-- ORDER BY ordinal_position;

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================
-- Your chat_messages table is now ready to store all conversations permanently.
-- All messages will be retained in the database unless explicitly deleted.
-- ============================================================================


