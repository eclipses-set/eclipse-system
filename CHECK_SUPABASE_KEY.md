# How to Check Which Supabase Key You're Using

## The Problem

Your RLS policies check `auth.uid()`, but when your Flask backend uses the Supabase client, there's no authenticated user, so `auth.uid()` is NULL and the policies fail.

## Quick Check

### Step 1: Check Your `.env` File

Open your `.env` file and look at the `SUPABASE_KEY` value.

### Step 2: Identify the Key Type

1. **Service Role Key** (Recommended for Backend):
   - Very long string
   - Starts with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **Automatically bypasses RLS** ✅
   - Found in: Supabase Dashboard → Settings → API → `service_role` key
   - **This is what you should use for Flask backend!**

2. **Anon/Public Key**:
   - Also long but different
   - **Respects RLS policies** ❌
   - Found in: Supabase Dashboard → Settings → API → `anon` `public` key
   - Used for frontend applications

## How to Fix

### Option 1: Use Service Role Key (Easiest - Recommended)

1. Go to **Supabase Dashboard** → **Settings** → **API**
2. Find the **`service_role`** key (scroll down, it's in a separate section)
3. Copy it
4. Update your `.env` file:
   ```
   SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlvdXJwcm9qZWN0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTY0MjU2ODAwMCwiZXhwIjoxOTU4MTQ0MDAwfQ.your_service_role_key_here
   ```
5. **Restart your Flask application**
6. ✅ **Done!** RLS is now bypassed automatically

### Option 2: Update RLS Policies (If You Must Use Anon Key)

If you're using the anon key, run the SQL in `RLS_POLICY_FIX_V2.sql` to update your policies.

## Test Your Setup

Add this temporary code to your Flask app to check:

```python
import os
from dotenv import load_dotenv

load_dotenv()
SUPABASE_KEY = os.getenv('SUPABASE_KEY')

# Check key type
if SUPABASE_KEY:
    # Service role keys are JWT tokens - decode to check
    try:
        import base64
        import json
        # JWT has 3 parts separated by dots
        parts = SUPABASE_KEY.split('.')
        if len(parts) >= 2:
            # Decode the payload (second part)
            payload = json.loads(base64.urlsafe_b64decode(parts[1] + '=='))
            role = payload.get('role', 'unknown')
            print(f"🔑 Supabase Key Role: {role}")
            if role == 'service_role':
                print("✅ Using service_role key - RLS is bypassed!")
            else:
                print("⚠️ Not using service_role key - RLS policies apply")
    except:
        print("⚠️ Could not determine key type")
```

## Why This Matters

- **Service Role Key**: Bypasses RLS completely - your Flask app can do anything
- **Anon Key**: Must follow RLS policies - your policies check `auth.uid()` which is NULL for backend requests

## Current Issue

Your policies look like this:
```sql
WHERE accounts_admin.admin_id = auth.uid()::text
```

But `auth.uid()` is NULL when your Flask app makes requests, so the policy fails.

**Solution**: Use service_role key (bypasses RLS) or update policies to handle NULL auth.uid().


