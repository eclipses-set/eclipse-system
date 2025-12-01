# Chat Messages Table - Foreign Key Relationships Setup

## Overview
The `chat_messages` table has been updated to include proper foreign key relationships with `alert_incidents` and `accounts_student` tables, ensuring referential integrity and data consistency.

## Database Schema

### Foreign Key Relationships

1. **`incident_id` → `alert_incidents.icd_id`**
   - Direct foreign key constraint
   - ON DELETE CASCADE: If an incident is deleted, all related chat messages are automatically deleted
   - ON UPDATE CASCADE: If an incident ID is updated, chat messages are automatically updated

2. **`sender_id` / `receiver_id` → `accounts_student.user_id`** (when type is 'student')
   - Conditional validation via database trigger
   - When `sender_type = 'student'`, `sender_id` must exist in `accounts_student.user_id`
   - When `receiver_type = 'student'`, `receiver_id` must exist in `accounts_student.user_id`

## Setup Instructions

### Step 1: Run the SQL Script

Execute the SQL script `create_chat_table_with_fkeys.sql` in your Supabase SQL Editor:

```sql
-- This script creates the table with:
-- 1. Foreign key constraint for incident_id → alert_incidents.icd_id
-- 2. Database trigger to validate student IDs
-- 3. All necessary indexes for performance
```

**Important Notes:**
- If you already have a `chat_messages` table, you may need to drop it first (see script comments)
- The foreign key constraint requires that all `incident_id` values in existing messages must exist in `alert_incidents`
- The trigger validates student IDs at the database level for additional security

### Step 2: Verify Table Creation

After running the script, verify the table was created correctly:

```sql
-- Check table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'chat_messages';

-- Check foreign key constraints
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'chat_messages';
```

### Step 3: Test the Application

1. **Test Message Sending:**
   - Open an incident in the dashboard
   - Click "Chat Student"
   - Send a test message
   - Verify it appears in the `chat_messages` table

2. **Test Foreign Key Validation:**
   - Try sending a message with an invalid `incident_id` (should fail)
   - Try sending a message with an invalid `student_id` when type is 'student' (should fail)

## Application Code Updates

### New Validation Functions

1. **`validate_incident_exists(incident_id)`**
   - Checks if an incident exists in `alert_incidents` table
   - Used before inserting messages to prevent foreign key violations

2. **`validate_student_exists(user_id)`**
   - Checks if a student exists in `accounts_student` table
   - Used when `sender_type` or `receiver_type` is 'student'

### Updated Functions

1. **`send_chat_message()`**
   - Now validates all foreign key relationships before inserting
   - Provides clear error messages for constraint violations
   - Handles foreign key errors gracefully

2. **`get_chat_history()`**
   - Validates foreign key relationships for returned messages
   - Filters out messages with invalid references
   - Logs warnings for data integrity issues

## Database Triggers

A PostgreSQL trigger function `validate_chat_message_user_ids()` has been created to:
- Validate that `sender_id` exists in `accounts_student` when `sender_type = 'student'`
- Validate that `receiver_id` exists in `accounts_student` when `receiver_type = 'student'`
- Raise an exception if validation fails

This provides an additional layer of data integrity at the database level.

## Indexes

The following indexes have been created for optimal query performance:

1. **`idx_chat_messages_sender_receiver`** - For querying messages between specific users
2. **`idx_chat_messages_receiver_read`** - For finding unread messages
3. **`idx_chat_messages_incident`** - For filtering messages by incident
4. **`idx_chat_messages_timestamp`** - For ordering messages by time
5. **`idx_chat_messages_incident_timestamp`** - Composite index for incident-specific message queries

## Data Integrity Benefits

1. **Referential Integrity:**
   - Cannot create messages for non-existent incidents
   - Cannot create messages from/to non-existent students
   - Automatic cleanup when incidents are deleted (CASCADE)

2. **Data Consistency:**
   - All messages are linked to valid incidents
   - All student references are validated
   - Prevents orphaned records

3. **Error Prevention:**
   - Application-level validation catches errors before database insertion
   - Database-level constraints provide final safety net
   - Clear error messages help with debugging

## Troubleshooting

### Error: "violates foreign key constraint"
- **Cause:** Trying to insert a message with an `incident_id` that doesn't exist
- **Solution:** Ensure the incident exists in `alert_incidents` before sending messages

### Error: "sender_id does not exist in accounts_student table"
- **Cause:** Trying to send a message as a student that doesn't exist
- **Solution:** Verify the student exists in `accounts_student` table

### Warning: "Message references non-existent incident"
- **Cause:** Existing message in database references deleted incident
- **Solution:** This is handled automatically - the message is filtered out from results

## Migration from Existing Table

If you already have a `chat_messages` table without foreign keys:

1. **Backup your data:**
   ```sql
   CREATE TABLE chat_messages_backup AS SELECT * FROM chat_messages;
   ```

2. **Clean invalid data:**
   ```sql
   -- Remove messages with invalid incident_ids
   DELETE FROM chat_messages 
   WHERE incident_id NOT IN (SELECT icd_id FROM alert_incidents);
   
   -- Remove messages with invalid student sender_ids
   DELETE FROM chat_messages 
   WHERE sender_type = 'student' 
     AND sender_id NOT IN (SELECT user_id::text FROM accounts_student);
   
   -- Remove messages with invalid student receiver_ids
   DELETE FROM chat_messages 
   WHERE receiver_type = 'student' 
     AND receiver_id NOT IN (SELECT user_id::text FROM accounts_student);
   ```

3. **Drop and recreate table:**
   ```sql
   DROP TABLE chat_messages CASCADE;
   -- Then run create_chat_table_with_fkeys.sql
   ```

4. **Restore valid data:**
   ```sql
   INSERT INTO chat_messages 
   SELECT * FROM chat_messages_backup;
   ```

## Testing Checklist

- [ ] Table created successfully with foreign key constraints
- [ ] Trigger function created and active
- [ ] Indexes created successfully
- [ ] Can send messages with valid incident_id
- [ ] Cannot send messages with invalid incident_id (error caught)
- [ ] Cannot send messages with invalid student_id (error caught)
- [ ] Messages are filtered by incident_id correctly
- [ ] Unread message count works correctly
- [ ] Chat history loads correctly
- [ ] Messages are deleted when incident is deleted (CASCADE test)

## Support

If you encounter any issues:
1. Check the application logs for validation errors
2. Verify foreign key constraints in Supabase dashboard
3. Check that all referenced records exist in parent tables
4. Review the SQL script for any syntax errors


