-- Migration 004: Submission Dependencies - Rename tables and restructure
-- This migration renames grading tables and reorganizes submission-related schema

-- Step 1: Rename and restructure build_infos → build_info (make submission_id the PK, remove id)
CREATE TABLE build_info (
    "submission_id" INTEGER PRIMARY KEY,
    "build_log" TEXT,
    "exec_time" INTEGER,
    "build_date" DATETIME,
    "submission_date" DATETIME,
    CONSTRAINT "fk_submissions_build_info" FOREIGN KEY ("submission_id") REFERENCES "submissions"("id") ON DELETE CASCADE
);

-- Migrate data (only keep first build_info per submission since submission_id becomes primary key)
INSERT INTO build_info ("submission_id", "build_log", "exec_time", "build_date", "submission_date")
SELECT "submission_id", "build_log", "exec_time", "build_date", "submission_date"
FROM build_infos
WHERE id IN (SELECT MIN(id) FROM build_infos GROUP BY submission_id);

DROP TABLE build_infos;

-- Step 2: Recreate reviews with NOT NULL on score, remove reviewer_id, add CASCADE
CREATE TABLE reviews_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "submission_id" INTEGER NOT NULL,
    "feedback" TEXT,
    "ready" NUMERIC,
    "score" INTEGER NOT NULL,
    "edited" DATETIME,
    CONSTRAINT "fk_submissions_reviews" FOREIGN KEY ("submission_id") REFERENCES "submissions"("id") ON DELETE CASCADE
);

INSERT INTO reviews_new ("id", "submission_id", "feedback", "ready", "score", "edited")
SELECT "id", "submission_id", "feedback", "ready", "score", "edited"
FROM reviews;

DROP TABLE reviews;
ALTER TABLE reviews_new RENAME TO reviews;

-- Step 3: Rename and restructure grading_benchmarks → checklist
-- Remove course_id, make review_id nullable with SET NULL
CREATE TABLE checklist (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "review_id" INTEGER DEFAULT NULL,
    "assignment_id" INTEGER NOT NULL,
    "heading" TEXT,
    "comment" TEXT,
    CONSTRAINT "fk_reviews_checklist" FOREIGN KEY ("review_id") REFERENCES "reviews"("id") ON DELETE SET NULL,
    CONSTRAINT "fk_assignments_checklist" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id") ON DELETE CASCADE
);

INSERT INTO checklist ("id", "review_id", "assignment_id", "heading", "comment")
SELECT "id", "review_id", "assignment_id", "heading", "comment"
FROM grading_benchmarks;

DROP TABLE grading_benchmarks;

-- Step 4: Rename and restructure grading_criterions → checklist_item
-- Change to reference checklist instead of benchmark, add NOT NULL constraints
CREATE TABLE checklist_item (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "checklist_id" INTEGER NOT NULL,
    "points" INTEGER NOT NULL,
    "description" TEXT NOT NULL,
    "grade" INTEGER NOT NULL DEFAULT 0 CHECK ("grade" IN (0,1,2)),
    "comment" TEXT,
    CONSTRAINT "fk_checklist_checklist_item" FOREIGN KEY ("checklist_id") REFERENCES "checklist"("id") ON DELETE CASCADE
);

INSERT INTO checklist_item ("id", "checklist_id", "points", "description", "grade", "comment")
SELECT "id", "benchmark_id", "points", "description", "grade", "comment"
FROM grading_criterions;

DROP TABLE grading_criterions;

-- Step 5: Drop and recreate grades table as approval with new structure
-- Old: grades(submission_id, user_id, status)
-- New: approval(submission_id, enrollment_id, decision) with CASCADE
CREATE TABLE approval (
    "submission_id" INTEGER,
    "enrollment_id" INTEGER,
    "decision" INTEGER NOT NULL DEFAULT 0 CHECK ("decision" IN (0,1,2,3)),
    PRIMARY KEY ("submission_id", "enrollment_id"),
    CONSTRAINT "fk_submissions_scores" FOREIGN KEY ("submission_id") REFERENCES "submissions"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_enrollments_scores" FOREIGN KEY ("enrollment_id") REFERENCES "enrollments"("id") ON DELETE CASCADE
);

-- Migrate data: Map user_id to enrollment_id
-- Note: This assumes a unique enrollment per user - may need adjustment
INSERT INTO approval ("submission_id", "enrollment_id", "decision")
SELECT
    g.submission_id,
    (SELECT e.id FROM enrollments e WHERE e.user_id = g.user_id LIMIT 1) as enrollment_id,
    g.status
FROM grades g
WHERE enrollment_id IS NOT NULL;

DROP TABLE grades;

-- Step 6: Drop scores table (replaced by approval)
-- scores table is deprecated in revised schema
DROP TABLE scores;
