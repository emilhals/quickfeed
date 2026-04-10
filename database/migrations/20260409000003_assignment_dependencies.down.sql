-- Rollback Migration 003: Assignment Dependencies
-- Reverses NOT NULL constraints and restructures tables back to original

-- Step 1: Restore feedback_receipt (remove CASCADE)
CREATE TABLE feedback_receipt_old (
    "assignment_id" INTEGER,
    "user_id" INTEGER,
    PRIMARY KEY ("assignment_id", "user_id"),
    CONSTRAINT "fk_assignments_feedback_receipt" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id"),
    CONSTRAINT "fk_users_feedback_receipt" FOREIGN KEY ("user_id") REFERENCES "users"("id")
);

INSERT INTO feedback_receipt_old SELECT * FROM feedback_receipt;
DROP TABLE feedback_receipt;
ALTER TABLE feedback_receipt_old RENAME TO feedback_receipt;

-- Step 2: Restore used_slip_days (add id back, remove composite PK)
CREATE TABLE used_slip_days_old (
    "id" INTEGER PRIMARY KEY,
    "enrollment_id" INTEGER NOT NULL,
    "assignment_id" INTEGER,
    "used_days" INTEGER,
    CONSTRAINT "fk_enrollments_used_slip_days" FOREIGN KEY ("enrollment_id") REFERENCES "enrollments"("id"),
    CONSTRAINT "fk_assignments_used_slip_days" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id")
);

INSERT INTO used_slip_days_old ("enrollment_id", "assignment_id", "used_days")
SELECT "enrollment_id", "assignment_id", "used_days"
FROM used_slip_days;

DROP TABLE used_slip_days;
ALTER TABLE used_slip_days_old RENAME TO used_slip_days;

-- Step 3: Restore submissions (remove CHECK constraint, remove NOT NULL, add status back)
CREATE TABLE submissions_old (
    "id" INTEGER PRIMARY KEY,
    "assignment_id" INTEGER NOT NULL,
    "user_id" INTEGER,
    "group_id" INTEGER,
    "score" INTEGER,
    "commit_hash" TEXT,
    "released" NUMERIC,
    "status" INTEGER NOT NULL DEFAULT 0 CHECK ("status" IN (0,1,2,3)),
    "approved_date" DATETIME,
    CONSTRAINT "fk_assignments_submissions" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id"),
    CONSTRAINT "fk_users_submissions" FOREIGN KEY ("user_id") REFERENCES "users"("id"),
    CONSTRAINT "fk_groups_submissions" FOREIGN KEY ("group_id") REFERENCES "groups"("id")
);

INSERT INTO submissions_old ("id", "assignment_id", "user_id", "group_id", "score", "commit_hash", "released", "approved_date")
SELECT "id", "assignment_id", "user_id", "group_id", "score", "commit_hash", "released", "approved_date"
FROM submissions;

DROP TABLE submissions;
ALTER TABLE submissions_old RENAME TO submissions;

-- Step 4: Restore test_info (remove NOT NULL from max_score and weight)
CREATE TABLE test_info_old (
    "id" INTEGER PRIMARY KEY,
    "assignment_id" INTEGER NOT NULL,
    "test_name" TEXT NOT NULL,
    "max_score" INTEGER,
    "weight" INTEGER,
    "details" TEXT,
    CONSTRAINT "fk_assignments_test_infos" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id"),
    UNIQUE("assignment_id", "test_name")
);

INSERT INTO test_info_old SELECT * FROM test_info;
DROP TABLE test_info;
ALTER TABLE test_info_old RENAME TO test_info;

-- Step 5: Restore assignment_feedback (remove NOT NULL from created_at, remove CASCADE)
CREATE TABLE assignment_feedback_old (
    "id" INTEGER PRIMARY KEY,
    "assignment_id" INTEGER NOT NULL,
    "course_id" INTEGER NOT NULL,
    "liked_content" TEXT,
    "improvement_suggestions" TEXT,
    "time_spent" INTEGER,
    "created_at" DATETIME,
    CONSTRAINT "fk_assignments_assignment_feedback" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id"),
    CONSTRAINT "fk_courses_assignment_feedback" FOREIGN KEY ("course_id") REFERENCES "courses"("id")
);

INSERT INTO assignment_feedback_old SELECT * FROM assignment_feedback;
DROP TABLE assignment_feedback;
ALTER TABLE assignment_feedback_old RENAME TO assignment_feedback;

-- Step 6: Restore assignments (remove NOT NULL from name, remove CASCADE)
CREATE TABLE assignments_old (
    "id" INTEGER PRIMARY KEY,
    "course_id" INTEGER NOT NULL,
    "name" TEXT,
    "deadline" DATETIME,
    "auto_approve" NUMERIC,
    "order" INTEGER,
    "is_group_lab" NUMERIC,
    "score_limit" INTEGER,
    "reviewers" INTEGER,
    "container_timeout" INTEGER,
    CONSTRAINT "fk_courses_assignments" FOREIGN KEY ("course_id") REFERENCES "courses"("id")
);

INSERT INTO assignments_old SELECT * FROM assignments;
DROP TABLE assignments;
ALTER TABLE assignments_old RENAME TO assignments;
