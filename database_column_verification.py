#!/usr/bin/env python3
"""
Database Column Verification Script
==================================
This script verifies that all required columns exist in the accounts_student table
to ensure compatibility with the Flask user management application.
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client
supabase_url = os.getenv('SUPABASE_URL')
supabase_key = os.getenv('SUPABASE_KEY')

if not supabase_url or not supabase_key:
    print("❌ Error: SUPABASE_URL and SUPABASE_KEY must be set in environment variables")
    exit(1)

supabase: Client = create_client(supabase_url, supabase_key)

def verify_accounts_student_columns():
    """Verify that all required columns exist in the accounts_student table"""
    
    print("🔍 Verifying accounts_student table columns...")
    print("=" * 60)
    
    try:
        # Get table structure from Supabase
        result = supabase.table('accounts_student').select('*').limit(1).execute()
        
        if not result.data:
            print("⚠️  Warning: Table exists but has no data")
            # Still need to check column structure even if table is empty
            # Let's try to get column info via a different approach
        
        # Expected columns based on app.py analysis
        required_columns = {
            'user_id': 'SERIAL PRIMARY KEY',
            'student_id': 'VARCHAR(50) - Student ID',
            'student_user': 'VARCHAR(50) - Username',
            'student_pass': 'VARCHAR(255) - Password (hashed)',
            'student_email': 'VARCHAR(100) - Email address',
            'full_name': 'VARCHAR(100) - Full name',
            'student_yearlvl': 'VARCHAR(20) - Year level',
            'student_cnum': 'VARCHAR(20) - Contact number',
            'student_emergencycontact': 'TEXT - Emergency contact information',
            'student_contactperson': 'VARCHAR(100) - Contact person name',
            'student_medinfo': 'TEXT - Medical information',
            'student_address': 'TEXT - Address',
            'student_profile': 'VARCHAR(255) - Profile image filename',
            'student_status': 'VARCHAR(20) - Status (active/inactive)',
            'student_created_at': 'TIMESTAMP - Creation timestamp'
        }
        
        print("Required columns for accounts_student table:")
        print("-" * 60)
        
        # We'll try to get column information by attempting to select each column
        existing_columns = []
        missing_columns = []
        
        # Test each required column
        for column_name, description in required_columns.items():
            try:
                # Try to select just this column
                result = supabase.table('accounts_student').select(column_name).limit(0).execute()
                # If no error, column exists
                existing_columns.append((column_name, description))
                print(f"✅ {column_name:<30} - EXISTS")
            except Exception as e:
                missing_columns.append((column_name, description))
                print(f"❌ {column_name:<30} - MISSING")
                print(f"   {description}")
        
        print("\n" + "=" * 60)
        print("SUMMARY")
        print("=" * 60)
        print(f"✅ Columns that exist: {len(existing_columns)}")
        print(f"❌ Missing columns: {len(missing_columns)}")
        
        if missing_columns:
            print("\n🚨 MISSING COLUMNS NEED TO BE ADDED:")
            print("-" * 40)
            for column_name, description in missing_columns:
                print(f"• {column_name}")
                print(f"  Purpose: {description}")
            print("\n💡 To fix this, run this SQL in your Supabase SQL Editor:")
            print("ALTER TABLE accounts_student")
            for column_name, _ in missing_columns:
                if column_name in ['student_emergencycontact', 'student_medinfo', 'student_address']:
                    print(f"ADD COLUMN IF NOT EXISTS {column_name} TEXT,")
                elif column_name in ['student_contactperson', 'student_status']:
                    print(f"ADD COLUMN IF NOT EXISTS {column_name} VARCHAR(20),")
                elif column_name == 'student_created_at':
                    print(f"ADD COLUMN IF NOT EXISTS {column_name} TIMESTAMP DEFAULT NOW(),")
                else:
                    print(f"ADD COLUMN IF NOT EXISTS {column_name} VARCHAR(255),")
            print(";")
        else:
            print("\n🎉 All required columns exist! Your database is ready.")
            print("✅ You can now run your Flask application: python app.py")
        
        return len(missing_columns) == 0
        
    except Exception as e:
        print(f"❌ Error accessing database: {e}")
        print("\n🔧 Make sure:")
        print("1. Your .env file has the correct SUPABASE_URL and SUPABASE_KEY")
        print("2. The accounts_student table exists in your Supabase project")
        print("3. Your API key has read permissions for the table")
        return False

def check_specific_missing_columns():
    """Specifically check for the columns that were causing the original error"""
    print("\n🔍 Checking specific columns from error message...")
    print("-" * 50)
    
    problematic_columns = ['student_emergencycontact', 'student_contactperson', 'student_medinfo']
    
    for column in problematic_columns:
        try:
            result = supabase.table('accounts_student').select(column).limit(0).execute()
            print(f"✅ {column} - EXISTS")
        except Exception as e:
            print(f"❌ {column} - MISSING")

if __name__ == "__main__":
    print("Database Column Verification Tool")
    print("For Emergency Alert System User Management")
    print("=" * 60)
    
    # Main verification
    success = verify_accounts_student_columns()
    
    # Check specific problematic columns
    check_specific_missing_columns()
    
    print("\n" + "=" * 60)
    if success:
        print("🎉 SUCCESS: Database verification passed!")
    else:
        print("⚠️  WARNING: Database verification failed!")
        print("Please add the missing columns and run this script again.")
    print("=" * 60)