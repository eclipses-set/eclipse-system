# User Archive Table Setup Instructions

## Overview
This guide explains how to set up the user archive functionality that stores archived users in a separate Supabase table.

## Step 1: Create the Archive Table in Supabase

1. Go to your Supabase project dashboard: https://app.supabase.com
2. Select your project
3. Click on **"SQL Editor"** in the left sidebar
4. Click **"New Query"** to create a new SQL query
5. Open the file `create_user_archive_table.sql` in this directory
6. **Copy the entire SQL script** and paste it into the Supabase SQL Editor
7. Click **"Run"** or press `Ctrl+Enter` (Windows) / `Cmd+Enter` (Mac)

## Step 2: Verify Table Creation

After running the SQL, verify the table was created:

1. Go to **"Table Editor"** in the left sidebar
2. Look for the `user_archive` table
3. Click on it to see the structure

The table should have these key columns:
- `archive_id` (Primary Key)
- `user_id` (Original user ID)
- `user_type` (admin or student)
- All admin fields (for admin users)
- All student fields (for student users)
- `archived_by` (Admin ID who archived)
- `archive_reason` (Reason for archiving)
- `archived_at` (Timestamp)

## Step 3: How It Works

### Archive Process:
1. When you click the **Archive** button on a user:
   - A confirmation dialog appears asking for an optional reason
   - The user's complete data is copied to the `user_archive` table
   - The user is deleted from the main `accounts_admin` or `accounts_student` table
   - The user is permanently removed from the active users list

### API Endpoint:
- **POST** `/api/user/<user_id>/archive?type=<admin|student>`
- Body: `{ "reason": "Optional reason for archiving" }`

### Backend Function:
- `archive_user(user_id, user_type, admin_id, reason=None)` in `app.py`
- Copies all user data to archive table
- Deletes user from main table

## Step 4: Testing

1. Go to User Management page
2. Click the **Archive** button (orange archive icon) on any user
3. Enter an optional reason in the dialog
4. Confirm the archive
5. The user should disappear from the active users list
6. Check the `user_archive` table in Supabase to verify the user was archived

## Important Notes

- **Archived users are permanently removed** from the active accounts
- All user data is preserved in the archive table
- The archive includes:
  - All profile information
  - Login credentials (hashed passwords)
  - Emergency contacts (for students)
  - Medical information (for students)
  - Timestamps and metadata

## Restoring Archived Users

Currently, there's no restore functionality. If you need to restore a user:
1. Query the `user_archive` table in Supabase
2. Copy the user data
3. Re-insert into the appropriate `accounts_admin` or `accounts_student` table

## Troubleshooting

### If the archive fails:
1. Check that the `user_archive` table exists in Supabase
2. Verify your Supabase connection credentials in `.env`
3. Check the browser console and server logs for errors
4. Ensure the user exists before archiving

### If you see "Table not found" errors:
- Run the SQL script again in Supabase SQL Editor
- Verify the table name is exactly `user_archive` (case-sensitive)

## Security

- Only authenticated admins can archive users
- The archiving admin's ID is recorded in `archived_by`
- Archive reason is optional but recommended for audit trails





