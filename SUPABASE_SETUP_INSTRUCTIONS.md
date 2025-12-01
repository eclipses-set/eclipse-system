# Supabase Chat Messages Setup Instructions

## Overview
This guide ensures that all chat conversations are properly stored and retained in your Supabase database.

## Prerequisites
- Access to your Supabase project dashboard
- SQL Editor access in Supabase

## Step-by-Step Setup

### Step 1: Open Supabase SQL Editor
1. Go to your Supabase project dashboard: https://app.supabase.com
2. Select your project
3. Click on **"SQL Editor"** in the left sidebar
4. Click **"New Query"** to create a new SQL query

### Step 2: Run the Complete Setup Script
1. Open the file `SUPABASE_CHAT_SETUP_COMPLETE.sql` in this directory
2. **Copy the entire SQL script** (everything from `-- ============================================================================` to the end)
3. **Paste it into the Supabase SQL Editor**
4. Click **"Run"** or press `Ctrl+Enter` (Windows) / `Cmd+Enter` (Mac)

### Step 3: Verify Table Creation
After running the SQL, you should see a success message. To verify:

1. Go to **"Table Editor"** in the left sidebar
2. Look for the `chat_messages` table
3. Click on it to see the structure

The table should have these columns:
- `id` (bigserial, Primary Key)
- `incident_id` (varchar, NOT NULL)
- `sender_id` (varchar, NOT NULL)
- `sender_type` (varchar, NOT NULL)
- `receiver_id` (varchar, NOT NULL)
- `receiver_type` (varchar, NOT NULL)
- `message` (text, NOT NULL)
- `timestamp` (timestamptz, default: now())
- `is_read` (boolean, default: false)
- `created_at` (timestamptz, default: now())
- `image_url` (varchar, nullable)

### Step 4: Test Message Retention
1. Restart your Flask application if it's running
2. Log in as an admin
3. Send a test message to a student
4. Check in Supabase Table Editor that the message appears in `chat_messages` table

## Important Notes

### Message Retention
- **All messages are permanently stored** in the database
- Messages are **NOT automatically deleted** unless:
  - The associated incident is deleted (due to CASCADE)
  - You manually delete them
- The `timestamp` field is used for sorting and display
- The `created_at` field is the permanent record timestamp

### Data Integrity
- The setup includes validation triggers that ensure:
  - Only valid students can send/receive messages
  - Students must be associated with the incident
  - Foreign key relationships are maintained

### Performance
- Indexes are created for fast querying:
  - By sender/receiver
  - By incident
  - By timestamp (for sorting)
  - Composite indexes for common queries

## Troubleshooting

### If you see "table already exists" errors:
- This is normal if the table was already created
- The script uses `CREATE TABLE IF NOT EXISTS` so it's safe to run multiple times
- You can ignore these warnings

### If messages are not being saved:
1. Check your Flask application logs for errors
2. Verify your Supabase connection credentials in `.env`:
   - `SUPABASE_URL`
   - `SUPABASE_KEY`
3. Check the Supabase logs in the dashboard
4. Verify the table exists in Table Editor

### If you need to check existing messages:
Run this query in SQL Editor:
```sql
SELECT 
  id,
  incident_id,
  sender_id,
  sender_type,
  receiver_id,
  receiver_type,
  message,
  timestamp,
  is_read,
  created_at,
  image_url
FROM public.chat_messages
ORDER BY timestamp DESC
LIMIT 10;
```

### If you need to view all conversations:
```sql
SELECT 
  cm.id,
  cm.incident_id,
  cm.sender_id,
  cm.sender_type,
  cm.receiver_id,
  cm.receiver_type,
  LEFT(cm.message, 50) as message_preview,
  cm.timestamp,
  cm.is_read,
  ai.icd_status as incident_status
FROM public.chat_messages cm
LEFT JOIN public.alert_incidents ai ON cm.incident_id = ai.icd_id
ORDER BY cm.timestamp DESC;
```

## Backup Recommendations

### Regular Backups
Supabase automatically backs up your database, but you can also:

1. **Manual Backup via SQL:**
   ```sql
   -- Export all chat messages
   COPY public.chat_messages TO '/path/to/backup.csv' WITH CSV HEADER;
   ```

2. **Use Supabase Dashboard:**
   - Go to **Settings** > **Database**
   - Use the backup/restore features

### Retention Policy
- Messages are stored indefinitely by default
- If you need to implement a retention policy (e.g., delete messages older than X years), you can create a scheduled function
- **Recommendation:** Keep all messages for compliance and audit purposes

## Security Notes

### Row Level Security (RLS)
The script includes optional RLS policies. If you want to enable them:

1. Uncomment the RLS sections in the SQL script
2. Adjust policies based on your security requirements
3. Test thoroughly before deploying to production

### API Access
- Ensure your Supabase API key has proper permissions
- Use service_role key only on the backend (never expose in frontend)
- Use anon key for public operations (if needed)

## Support

If you encounter any issues:
1. Check the Supabase logs in the dashboard
2. Check your Flask application logs
3. Verify table structure matches the expected schema
4. Test with a simple INSERT query to verify permissions

## Next Steps

After setup:
1. ✅ Test sending messages from the admin dashboard
2. ✅ Verify messages appear in Supabase
3. ✅ Test loading chat history
4. ✅ Verify message retention after page refresh
5. ✅ Test with multiple students and incidents

Your chat system is now fully configured for permanent message retention!


