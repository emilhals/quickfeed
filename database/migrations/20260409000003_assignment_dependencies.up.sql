-- Migration 003: Assignment Dependencies - Add constraints and restructure tables
-- This migration adds NOT NULL constraints and CASCADE deletes to assignment-related tables

-- Step 1: Recreate assignments with NOT NULL on name and CASCADE
CREATE TABLE assignments_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "course_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "deadline" DATETIME,
    "auto_approve" NUMERIC,
    "order" INTEGER,
    "is_group_lab" NUMERIC,
    "score_limit" INTEGER,
    "reviewers" INTEGER,
    "container_timeout" INTEGER,
    CONSTRAINT "fk_courses_assignments" FOREIGN KEY ("course_id") REFERENCES "courses"("id") ON DELETE CASCADE
);

INSERT INTO assignments_new SELECT * FROM assignments;
DROP TABLE assignments;
ALTER TABLE assignments_new RENAME TO assignments;

-- Step 2: Recreate assignment_feedback with NOT NULL on created_at and CASCADE
CREATE TABLE assignment_feedback_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "assignment_id" INTEGER NOT NULL,
    "course_id" INTEGER NOT NULL,
    "liked_content" TEXT,
    "improvement_suggestions" TEXT,
    "time_spent" INTEGER,
    "created_at" DATETIME NOT NULL,
    CONSTRAINT "fk_assignments_assignment_feedback" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_courses_assignment_feedback" FOREIGN KEY ("course_id") REFERENCES "courses"("id") ON DELETE CASCADE
);

INSERT INTO assignment_feedback_new SELECT * FROM assignment_feedback;
DROP TABLE assignment_feedback;
ALTER TABLE assignment_feedback_new RENAME TO assignment_feedback;

-- Step 3: Recreate test_info with NOT NULL on max_score and weight
CREATE TABLE test_info_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "assignment_id" INTEGER NOT NULL,
    "test_name" TEXT NOT NULL,
    "max_score" INTEGER NOT NULL,
    "weight" INTEGER NOT NULL,
    "details" TEXT,
    CONSTRAINT "fk_assignments_test_infos" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE,
    UNIQUE("assignment_id", "test_name")
);

INSERT INTO test_info_new SELECT * FROM test_info;
DROP TABLE test_info;
ALTER TABLE test_info_new RENAME TO test_info;

-- Step 4: Recreate submissions with NOT NULL constraints and CHECK constraint
CREATE TABLE submissions_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "assignment_id" INTEGER NOT NULL,
    "group_id" INTEGER,
    "user_id" INTEGER,
    "score" INTEGER,
    "commit_hash" TEXT NOT NULL,
    "released" NUMERIC NOT NULL,
    "approved_date" DATETIME,
    CONSTRAINT "fk_assignments_submissions" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_groups_submissions" FOREIGN KEY ("group_id") REFERENCES "groups"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_users_submissions" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
    CHECK (("group_id" != 0 AND "user_id" = 0)
        OR ("group_id" = 0 AND "user_id" != 0))
);

-- Note: status field is removed in revised schema
INSERT INTO submissions_new ("id", "assignment_id", "group_id", "user_id", "score", "commit_hash", "released", "approved_date")
SELECT "id", "assignment_id", "group_id", "user_id", "score", "commit_hash", "released", "approved_date"
FROM submissions;

DROP TABLE submissions;
ALTER TABLE submissions_new RENAME TO submissions;

-- Step 5: Restructure used_slip_days (remove id, make composite primary key)
CREATE TABLE used_slip_days_new (
    "assignment_id" INTEGER,
    "enrollment_id" INTEGER,
    "used_days" INTEGER,
    PRIMARY KEY ("assignment_id", "enrollment_id"),
    CONSTRAINT "fk_enrollments_used_slip_days" FOREIGN KEY ("enrollment_id") REFERENCES "enrollments"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_assignments_used_slip_days" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE
);

INSERT INTO used_slip_days_new ("assignment_id", "enrollment_id", "used_days")
SELECT "assignment_id", "enrollment_id", "used_days"
FROM used_slip_days;

DROP TABLE used_slip_days;
ALTER TABLE used_slip_days_new RENAME TO used_slip_days;

-- Step 6: Recreate feedback_receipt with CASCADE
CREATE TABLE feedback_receipt_new (
    "assignment_id" INTEGER,
    "user_id" INTEGER,
    PRIMARY KEY ("assignment_id", "user_id"),
    CONSTRAINT "fk_assignments_feedback_receipt" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_users_feedback_receipt" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
);

INSERT INTO feedback_receipt_new SELECT * FROM feedback_receipt;
DROP TABLE feedback_receipt;
ALTER TABLE feedback_receipt_new RENAME TO feedback_receipt;
