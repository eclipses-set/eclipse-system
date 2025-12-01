# Incident-Student Relationship Validation

## Overview
The chat system now enforces a critical relationship: **the student in chat messages must be the same student who reported the incident** (i.e., the `user_id` from `alert_incidents` must match the `student_id` in chat messages).

## Relationship Chain

```
alert_incidents.icd_id (incident_id)
    ↓ (foreign key)
chat_messages.incident_id
    ↓ (validated relationship)
alert_incidents.user_id (student who reported)
    ↓ (must match)
chat_messages.sender_id OR receiver_id (when type is 'student')
    ↓ (foreign key)
accounts_student.user_id
```

## Implementation Details

### 1. Application-Level Validation (`app.py`)

#### New Functions:

1. **`validate_incident_student_relationship(incident_id, student_id)`**
   - Validates that the student is the one who reported the incident
   - Checks that `alert_incidents.user_id` matches the `student_id`
   - Ensures both the incident and student exist

2. **`get_incident_student_id(incident_id)`**
   - Retrieves the `user_id` (student_id) associated with an incident
   - Used to verify relationships before sending messages

#### Updated Functions:

1. **`send_chat_message()`**
   - **Before sending:** Validates that if a student is involved (sender or receiver), they must be the reporter of the incident
   - **Validation steps:**
     1. Check incident exists
     2. Get the `user_id` from the incident
     3. If sender is student: verify `sender_id == incident.user_id`
     4. If receiver is student: verify `receiver_id == incident.user_id`
     5. Use relationship validation function for final check

2. **`get_chat_history()`**
   - **Before filtering:** Validates incident-student relationship
   - **When returning messages:** Validates each message's student matches the incident's `user_id`
   - Filters out messages with invalid relationships

### 2. Database-Level Validation (SQL Trigger)

The database trigger `validate_chat_message_user_ids()` now:

1. **Retrieves the incident's user_id:**
   ```sql
   SELECT user_id::text INTO incident_user_id
   FROM public.alert_incidents
   WHERE icd_id = NEW.incident_id;
   ```

2. **Validates sender (if student):**
   - Checks student exists in `accounts_student`
   - **CRITICAL:** Verifies `sender_id == incident_user_id`

3. **Validates receiver (if student):**
   - Checks student exists in `accounts_student`
   - **CRITICAL:** Verifies `receiver_id == incident_user_id`

4. **Raises exception if validation fails:**
   - Clear error messages indicating which student doesn't match
   - Shows the expected `user_id` from the incident

## Benefits

### 1. Data Integrity
- **Prevents orphaned messages:** Messages can only be created for valid incident-student pairs
- **Prevents cross-incident chat:** Students can only chat about their own incidents
- **Ensures consistency:** All messages are linked to the correct student-incident relationship

### 2. Security
- **Prevents unauthorized access:** Students cannot chat about incidents they didn't report
- **Prevents data leakage:** Messages are strictly tied to the incident reporter
- **Database-level enforcement:** Even if application code is bypassed, database trigger prevents invalid data

### 3. User Experience
- **Clear error messages:** Users know exactly why a message failed
- **Automatic validation:** System ensures correct relationships without manual checks
- **Consistent behavior:** Same validation at both application and database levels

## Example Scenarios

### ✅ Valid Scenario:
```
Incident: ICD_12345
  - user_id: "student_001"
  
Chat Message:
  - incident_id: "ICD_12345"
  - sender_type: "admin"
  - receiver_type: "student"
  - receiver_id: "student_001"  ✅ Matches incident.user_id
```

### ❌ Invalid Scenario:
```
Incident: ICD_12345
  - user_id: "student_001"
  
Chat Message:
  - incident_id: "ICD_12345"
  - sender_type: "admin"
  - receiver_type: "student"
  - receiver_id: "student_002"  ❌ Does NOT match incident.user_id
```

**Result:** Message is rejected with error:
```
Error: Student student_002 is not the reporter of incident ICD_12345 
(incident belongs to student student_001)
```

## Testing

### Test Cases:

1. **Valid Message (Admin to Student)**
   - ✅ Student is the incident reporter
   - ✅ Message is created successfully

2. **Invalid Message (Wrong Student)**
   - ❌ Student is NOT the incident reporter
   - ❌ Message is rejected at application level
   - ❌ Database trigger also prevents insertion

3. **Valid Message Retrieval**
   - ✅ Only messages with correct relationships are returned
   - ✅ Invalid messages are filtered out

4. **Invalid Message Retrieval**
   - ✅ Messages with wrong student-incident relationships are excluded
   - ✅ Warnings logged for data integrity issues

## Error Messages

### Application Level:
```
Error: Student {student_id} is not the reporter of incident {incident_id} 
(incident belongs to student {incident_user_id})
```

### Database Level:
```
ERROR: sender_id {student_id} is not the reporter of incident {incident_id} 
(incident belongs to user_id: {incident_user_id})
```

## Migration Notes

If you have existing chat messages that don't follow this relationship:

1. **Identify invalid messages:**
   ```sql
   SELECT cm.id, cm.incident_id, cm.sender_id, cm.receiver_id, 
          ai.user_id as incident_user_id
   FROM chat_messages cm
   LEFT JOIN alert_incidents ai ON cm.incident_id = ai.icd_id
   WHERE (cm.sender_type = 'student' AND cm.sender_id::text != ai.user_id::text)
      OR (cm.receiver_type = 'student' AND cm.receiver_id::text != ai.user_id::text);
   ```

2. **Clean up invalid messages:**
   ```sql
   DELETE FROM chat_messages cm
   USING alert_incidents ai
   WHERE cm.incident_id = ai.icd_id
     AND (
       (cm.sender_type = 'student' AND cm.sender_id::text != ai.user_id::text)
       OR 
       (cm.receiver_type = 'student' AND cm.receiver_id::text != ai.user_id::text)
     );
   ```

## Summary

The chat system now enforces a strict relationship:
- **`incident_id`** → **`alert_incidents.icd_id`** (foreign key)
- **`alert_incidents.user_id`** → **`chat_messages.sender_id/receiver_id`** (when type is 'student')
- **`chat_messages.sender_id/receiver_id`** → **`accounts_student.user_id`** (when type is 'student')

This ensures that:
1. All messages are linked to valid incidents
2. Students can only chat about incidents they reported
3. Data integrity is maintained at both application and database levels
4. Clear error messages guide developers and users


