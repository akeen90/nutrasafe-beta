// Firestore Architecture Documentation
// This file describes the data structure and relationships for the fasting feature

/*

COLLECTION STRUCTURE:

1. fasting_plans (Collection)
   ├── Document ID: Auto-generated
   ├── Fields:
   │   ├── user_id (string, required) - Firebase Auth UID
   │   ├── name (string, required) - Plan name (1-50 chars)
   │   ├── duration_hours (integer, required) - 1-168 hours
   │   ├── days_of_week (array<string>, required) - ["Mon", "Tue", ...]
   │   ├── allowed_drinks (string, required) - "strict" | "practical" | "lenient"
   │   ├── reminder_enabled (boolean, required)
   │   ├── reminder_minutes_before_end (integer, required) - 0-1440 minutes
   │   ├── active (boolean, required) - Only one active plan per user
   │   └── created_at (timestamp, required)
   │
   └── Indexes:
       ├── user_id ASC, active DESC, created_at DESC
       └── user_id ASC, name ASC

2. fasting_sessions (Collection)
   ├── Document ID: Auto-generated
   ├── Fields:
   │   ├── user_id (string, required) - Firebase Auth UID
   │   ├── plan_id (string, optional) - Reference to fasting_plans document
   │   ├── start_time (timestamp, required) - Session start time
   │   ├── end_time (timestamp, optional) - Session end time (null if active)
   │   ├── manually_edited (boolean, required) - Whether times were manually edited
   │   ├── skipped (boolean, required) - Whether session was skipped
   │   ├── completion_status (string, required) - "active" | "completed" | "earlyEnd" | "overGoal" | "failed" | "skipped"
   │   ├── target_duration_hours (integer, required) - Target duration in hours
   │   ├── notes (string, optional) - User notes about the session
   │   ├── created_at (timestamp, required) - Session creation time
   │   └── archived (boolean, required, default: false) - Soft delete flag
   │
   └── Indexes:
       ├── user_id ASC, completion_status ASC, start_time DESC
       ├── user_id ASC, start_time DESC
       └── user_id ASC, plan_id ASC, start_time DESC

3. fasting_notifications (Collection)
   ├── Document ID: Auto-generated
   ├── Fields:
   │   ├── user_id (string, required) - Firebase Auth UID
   │   ├── session_id (string, required) - Reference to fasting_sessions document
   │   ├── type (string, required) - "fast_start" | "midway_check_in" | "phase_transition" | "reminder_before_end" | "goal_reached" | "over_goal_encouragement"
   │   ├── title (string, required) - Notification title
   │   ├── body (string, required) - Notification body text
   │   ├── scheduled_date (timestamp, required) - When to show notification
   │   └── created_at (timestamp, required)
   │
   └── Indexes:
       ├── user_id ASC, scheduled_date ASC
       └── session_id ASC, scheduled_date ASC

4. fasting_settings (Collection)
   ├── Document ID: User ID (same as Firebase Auth UID)
   ├── Fields:
   │   ├── user_id (string, required) - Firebase Auth UID
   │   ├── education_completed (boolean, required) - Whether user completed education
   │   ├── default_allowed_drinks (string, optional) - Default drink philosophy
   │   ├── notifications_enabled (boolean, required) - Global notification preference
   │   ├── widget_enabled (boolean, required) - Widget preference
   │   └── updated_at (timestamp, required)

DATA RELATIONSHIPS:

User (1) → (N) fasting_plans
- One user can have multiple fasting plans
- Only one plan can be active at a time

User (1) → (N) fasting_sessions
- One user can have multiple fasting sessions
- Only one session can be active at a time

fasting_plans (1) → (N) fasting_sessions
- One plan can have multiple sessions
- Sessions can exist without a plan (manual fasting)

fasting_sessions (1) → (N) fasting_notifications
- One session can have multiple notifications
- Notifications are automatically cleaned up when sessions end

SECURITY RULES SUMMARY:

1. Users can only read/write their own data
2. Sessions can only be edited by the user who created them
3. End time must be > start time when saved
4. No deletion of completed sessions (set archived flag instead)
5. History protected from tampering except manual edit field
6. Only manually edited sessions can have times changed
7. Cannot delete active fasting plans
8. Cannot delete non-archived sessions

QUERY PATTERNS:

1. Get user's active plan:
   db.collection("fasting_plans")
     .whereField("user_id", isEqualTo: userId)
     .whereField("active", isEqualTo: true)
     .limit(to: 1)

2. Get user's active session:
   db.collection("fasting_sessions")
     .whereField("user_id", isEqualTo: userId)
     .whereField("completion_status", isEqualTo: "active")
     .limit(to: 1)

3. Get recent sessions for insights:
   db.collection("fasting_sessions")
     .whereField("user_id", isEqualTo: userId)
     .whereField("completion_status", in: ["completed", "earlyEnd", "overGoal"])
     .order(by: "start_time", descending: true)
     .limit(to: 30)

4. Get upcoming notifications:
   db.collection("fasting_notifications")
     .whereField("user_id", isEqualTo: userId)
     .whereField("scheduled_date", isGreaterThan: Date())
     .order(by: "scheduled_date", ascending: true)

BATCH OPERATIONS:

1. When activating a new plan:
   - Set all other user plans to active: false
   - Set new plan to active: true
   - Update user settings if needed

2. When ending a session:
   - Update session completion_status
   - Cancel all pending notifications for this session
   - Update user analytics

3. When starting a new session:
   - Check for existing active session
   - Create new session document
   - Schedule notifications based on plan settings
   - Update widget timeline

*/