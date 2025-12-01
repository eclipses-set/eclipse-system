# RLS (Row Level Security) Troubleshooting Guide

## Problem: Can't Update Data in Supabase

If you can't update data even though the code looks correct, it's likely an **RLS (Row Level Security) policy issue**.

## Quick Check: Which Key Are You Using?

### Check Your `.env` File

Look for your `SUPABASE_KEY` value:

1. **Service Role Key** (starts with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` and is very long)
   - ✅ **Bypasses RLS** - Your code should work without RLS policies
   - ✅ **Recommended for backend/server-side operations**
   - ⚠️ **Keep this secret!** Never expose it in frontend code

2. **Anon/Public Key** (also long but different)
   - ❌ **Respects RLS** - You need proper RLS policies
   - ✅ Safe to use in frontend (but still keep it somewhat private)

## Solution 1: Use Service Role Key (Recommended)

If you're building a backend application (like this Flask app), you should use the **service_role key**:

1. Go to Supabase Dashboard → Settings → API
2. Copy the **`service_role`** key (NOT the `anon` key)
3. Update your `.env` file:
   ```
   SUPABASE_KEY=your_service_role_key_here
   ```
4. Restart your Flask application

**This will bypass RLS entirely**, so your updates will work.

## Solution 2: Add RLS Policies (If Using Anon Key)

If you must use the anon key, you need to add RLS policies that allow admins to update data.

### Step 1: Check Current Policies

In Supabase SQL Editor, run:
```sql
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'accounts_student';
```

### Step 2: Add Admin Update Policy

Run the SQL from `RLS_POLICY_FIX.sql` to add policies that allow admins to:
- ✅ Update student data
- ✅ Insert student data  
- ✅ Delete student data

### Step 3: Verify Policies

After adding policies, verify they exist:
```sql
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'accounts_student' 
AND cmd = 'UPDATE';
```

You should see policies for both:
- "Students can update their own data"
- "Admins can update all student data"

## Solution 3: Temporarily Disable RLS (For Testing Only)

⚠️ **WARNING: Only for development/testing!**

If you want to test without RLS:
```sql
ALTER TABLE public.accounts_student DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts_admin DISABLE ROW LEVEL SECURITY;
```

**Remember to re-enable it:**
```sql
ALTER TABLE public.accounts_student ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts_admin ENABLE ROW LEVEL SECURITY;
```

## Common RLS Policy Issues

### Issue 1: Policy Only Allows Students
**Problem:** Policy says "Students can update their own data" but doesn't allow admins.

**Solution:** Add a separate policy for admins (see `RLS_POLICY_FIX.sql`)

### Issue 2: Policy Uses `auth.uid()` But You're Not Authenticated
**Problem:** Your Flask app doesn't use Supabase Auth, so `auth.uid()` is NULL.

**Solution:** 
- Use service_role key (bypasses RLS)
- OR create policies that don't rely on `auth.uid()`

### Issue 3: Policy Checks Wrong Table
**Problem:** Policy checks `accounts_admin` but your admin isn't in that table format.

**Solution:** Adjust the policy to match your actual admin authentication method.

## Testing Your Setup

### Test 1: Check Which Key You're Using
Add this to your Flask app temporarily:
```python
print(f"Supabase Key starts with: {SUPABASE_KEY[:20]}...")
# Service role keys are longer and different from anon keys
```

### Test 2: Try Direct SQL Update
In Supabase SQL Editor, try:
```sql
UPDATE accounts_student 
SET full_name = 'Test Update' 
WHERE student_id = 'SOME_EXISTING_ID';
```

If this works but your Flask app doesn't, it's an RLS issue.

### Test 3: Check Supabase Logs
1. Go to Supabase Dashboard → Logs
2. Try updating a record from your app
3. Check for RLS-related errors

## Recommended Setup for Backend Apps

For a Flask backend application like yours:

1. ✅ **Use service_role key** in `.env`
2. ✅ **Keep RLS enabled** (for security)
3. ✅ **Service role bypasses RLS** automatically
4. ✅ **No need for complex RLS policies** for backend operations

This is the standard setup for server-side applications.

## Need Help?

If updates still don't work after trying these solutions:

1. Check browser console for errors
2. Check Flask server logs for detailed error messages
3. Check Supabase Dashboard → Logs for database errors
4. Verify your `.env` file has the correct key
5. Restart your Flask application after changing `.env`


