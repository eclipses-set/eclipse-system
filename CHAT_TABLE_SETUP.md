# Chat Messages Table Setup Guide

## Problem
The chat functionality requires a `chat_messages` table in your Supabase database. If you see errors like:
```
Could not find the table 'public.chat_messages' in the schema cache
```

This means the table doesn't exist yet.

## Solution

### Step 1: Open Supabase SQL Editor
1. Go to your Supabase project dashboard
2. Click on "SQL Editor" in the left sidebar
3. Click "New Query"

### Step 2: Run the SQL Script
1. Open the file `create_chat_table.sql` in this directory
2. Copy the entire SQL script
3. Paste it into the Supabase SQL Editor
4. Click "Run" or press `Ctrl+Enter` (Windows) / `Cmd+Enter` (Mac)

### Step 3: Verify Table Creation
After running the SQL, you should see a success message. The table `chat_messages` will be created with the following structure:

- `id` - Primary key (auto-incrementing)
- `incident_id` - Reference to the incident
- `sender_id` - ID of the message sender
- `sender_type` - Type of sender ('admin' or 'student')
- `receiver_id` - ID of the message receiver
- `receiver_type` - Type of receiver ('admin' or 'student')
- `message` - The message content
- `timestamp` - When the message was sent
- `is_read` - Whether the message has been read
- `created_at` - Creation timestamp

### Step 4: Test the Chat Functionality
1. Restart your Flask application if it's running
2. Log in as an admin
3. Click the chat button in the dashboard
4. Try sending a message to a student

## Alternative: Check Table Status via API

You can check if the table exists by calling:
```
GET /api/chat/check-table
```

This will return:
```json
{
  "success": true,
  "table_exists": true/false,
  "message": "Table exists" or "Table does not exist..."
}
```

## Troubleshooting

### If the table still doesn't work after creation:
1. Make sure you're using the correct Supabase project
2. Check that your `.env` file has the correct `SUPABASE_URL` and `SUPABASE_KEY`
3. Verify the table exists in Supabase Dashboard > Table Editor
4. Check that your API key has the necessary permissions

### If you get permission errors:
You may need to adjust the RLS (Row Level Security) policies or grant permissions. The SQL script includes commented lines for this.

## Notes
- The table uses `BIGSERIAL` for the ID to support large numbers of messages
- Indexes are created for better query performance
- The table supports both admin-to-student and student-to-admin messaging


