-- ============================================================================
-- VERIFICATION QUERIES FOR CHAT MESSAGES
-- Run these in Supabase SQL Editor to verify your chat messages are being saved
-- ============================================================================

-- Query 1: Check if table exists and has correct structure
-- ============================================================================
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'chat_messages'
ORDER BY ordinal_position;

-- Query 2: Count total messages in database
-- ============================================================================
SELECT COUNT(*) as total_messages FROM public.chat_messages;

-- Query 3: View recent messages (last 10)
-- ============================================================================
SELECT 
  id,
  incident_id,
  sender_id,
  sender_type,
  receiver_id,
  receiver_type,
  LEFT(message, 100) as message_preview,
  timestamp,
  is_read,
  created_at,
  CASE WHEN image_url IS NOT NULL THEN 'Yes' ELSE 'No' END as has_image
FROM public.chat_messages
ORDER BY timestamp DESC
LIMIT 10;

-- Query 4: View messages by incident
-- ============================================================================
SELECT 
  cm.incident_id,
  COUNT(*) as message_count,
  MIN(cm.timestamp) as first_message,
  MAX(cm.timestamp) as last_message
FROM public.chat_messages cm
GROUP BY cm.incident_id
ORDER BY last_message DESC;

-- Query 5: View conversations between admin and students
-- ============================================================================
SELECT 
  cm.id,
  cm.incident_id,
  cm.sender_type,
  cm.sender_id,
  cm.receiver_id,
  LEFT(cm.message, 50) as message_preview,
  cm.timestamp,
  cm.is_read,
  ai.icd_status as incident_status
FROM public.chat_messages cm
LEFT JOIN public.alert_incidents ai ON cm.incident_id = ai.icd_id
WHERE cm.sender_type = 'admin' OR cm.receiver_type = 'admin'
ORDER BY cm.timestamp DESC
LIMIT 20;

-- Query 6: Check for messages with images
-- ============================================================================
SELECT 
  id,
  incident_id,
  sender_id,
  receiver_id,
  image_url,
  timestamp
FROM public.chat_messages
WHERE image_url IS NOT NULL
ORDER BY timestamp DESC;

-- Query 7: Verify foreign key relationships
-- ============================================================================
SELECT 
  cm.incident_id,
  CASE 
    WHEN ai.icd_id IS NULL THEN 'MISSING - Foreign key violation!'
    ELSE 'OK'
  END as incident_status
FROM public.chat_messages cm
LEFT JOIN public.alert_incidents ai ON cm.incident_id = ai.icd_id
GROUP BY cm.incident_id, ai.icd_id
HAVING ai.icd_id IS NULL;

-- Query 8: Check message retention (messages per day)
-- ============================================================================
SELECT 
  DATE(timestamp) as message_date,
  COUNT(*) as messages_count
FROM public.chat_messages
GROUP BY DATE(timestamp)
ORDER BY message_date DESC
LIMIT 30;

-- Query 9: Find unread messages
-- ============================================================================
SELECT 
  receiver_id,
  receiver_type,
  COUNT(*) as unread_count
FROM public.chat_messages
WHERE is_read = false
GROUP BY receiver_id, receiver_type
ORDER BY unread_count DESC;

-- Query 10: Verify indexes exist
-- ============================================================================
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'chat_messages'
ORDER BY indexname;


















