-- Rollback Migration 004: Submission Dependencies
-- Reverses table renames and restructures back to original schema

-- Step 1: Recreate scores table (deprecated but restored for rollback)
CREATE TABLE scores (
    "id" INTEGER PRIMARY KEY,
    "submission_id" INTEGER NOT NULL,
    "test_name" TEXT,
    "task_name" TEXT,
    "score" INTEGER,
    "max_score" INTEGER,
    "weight" INTEGER,
    "test_details" TEXT,
    CONSTRAINT "fk_submissions_scores" FOREIGN KEY ("submission_id") REFERENCES "submissions"("id")
);

-- Note: scores data cannot be restored from approval table - different structure

-- Step 2: Restore grades table from approval
CREATE TABLE grades (
    "submission_id" INTEGER,
    "user_id" INTEGER,
    "status" INTEGER,
    PRIMARY KEY ("submission_id", "user_id"),
    CONSTRAINT "fk_submissions_grades" FOREIGN KEY ("submission_id") REFERENCES "submissions"("id"),
    CONSTRAINT "fk_users_grades" FOREIGN KEY ("user_id") REFERENCES "users"("id")
);

-- Migrate data back: Map enrollment_id to user_id
INSERT INTO grades ("submission_id", "user_id", "status")
SELECT
    a.submission_id,
    (SELECT e.user_id FROM enrollments e WHERE e.id = a.enrollment_id) as user_id,
    a.decision
FROM approval a;

DROP TABLE approval;

-- Step 3: Restore grading_criterions from checklist_item
CREATE TABLE grading_criterions (
    "id" INTEGER PRIMARY KEY,
    "benchmark_id" INTEGER NOT NULL,
    "course_id" INTEGER NOT NULL,
    "points" INTEGER,
    "description" TEXT,
    "grade" INTEGER NOT NULL DEFAULT 0 CHECK ("grade" IN (0,1,2)),
    "comment" TEXT,
    CONSTRAINT "fk_grading_benchmarks_criteria" FOREIGN KEY ("benchmark_id") REFERENCES "grading_benchmarks"("id"),
    CONSTRAINT "fk_courses_grading_criterions" FOREIGN KEY ("course_id") REFERENCES "courses"("id")
);

-- Note: course_id needs to be derived during migration
INSERT INTO grading_criterions ("id", "benchmark_id", "points", "description", "grade", "comment", "course_id")
SELECT
    ci.id,
    ci.checklist_id as benchmark_id,
    ci.points,
    ci.description,
    ci.grade,
    ci.comment,
    (SELECT c.assignment_id FROM checklist c WHERE c.id = ci.checklist_id) as course_id
FROM checklist_item ci;

DROP TABLE checklist_item;

-- Step 4: Restore grading_benchmarks from checklist
CREATE TABLE grading_benchmarks (
    "id" INTEGER PRIMARY KEY,
    "course_id" INTEGER NOT NULL,
    "assignment_id" INTEGER NOT NULL,
    "review_id" INTEGER NOT NULL,
    "heading" TEXT,
    "comment" TEXT,
    CONSTRAINT "fk_assignments_grading_benchmarks" FOREIGN KEY ("assignment_id") REFERENCES "assignments"("id"),
    CONSTRAINT "fk_reviews_grading_benchmarks" FOREIGN KEY ("review_id") REFERENCES "reviews"("id"),
    CONSTRAINT "fk_courses_grading_benchmarks" FOREIGN KEY ("course_id") REFERENCES "courses"("id")
);

-- Derive course_id from assignment
INSERT INTO grading_benchmarks ("id", "assignment_id", "review_id", "heading", "comment", "course_id")
SELECT
    c.id,
    c.assignment_id,
    c.review_id,
    c.heading,
    c.comment,
    (SELECT a.course_id FROM assignments a WHERE a.id = c.assignment_id) as course_id
FROM checklist c;

DROP TABLE checklist;

-- Step 5: Restore reviews (add reviewer_id back, remove NOT NULL from score, remove CASCADE)
CREATE TABLE reviews_old (
    "id" INTEGER PRIMARY KEY,
    "submission_id" INTEGER NOT NULL,
    "reviewer_id" INTEGER NOT NULL,
    "feedback" TEXT,
    "ready" NUMERIC,
    "score" INTEGER,
    "edited" DATETIME,
    CONSTRAINT "fk_submissions_reviews" FOREIGN KEY ("submission_id") REFERENCES "submissions"("id"),
    CONSTRAINT "fk_users_reviews" FOREIGN KEY ("reviewer_id") REFERENCES "users"("id")
);

-- Note: reviewer_id cannot be restored - set to 0
INSERT INTO reviews_old ("id", "submission_id", "reviewer_id", "feedback", "ready", "score", "edited")
SELECT "id", "submission_id", 0 as reviewer_id, "feedback", "ready", "score", "edited"
FROM reviews;

DROP TABLE reviews;
ALTER TABLE reviews_old RENAME TO reviews;

-- Step 6: Restore build_infos from build_info (add id back, remove submission_id as PK)
CREATE TABLE build_infos (
    "id" INTEGER PRIMARY KEY,
    "submission_id" INTEGER NOT NULL,
    "build_log" TEXT,
    "exec_time" INTEGER,
    "build_date" DATETIME,
    "submission_date" DATETIME,
    CONSTRAINT "fk_submissions_build_info" FOREIGN KEY ("submission_id") REFERENCES "submissions"("id"),
    UNIQUE("submission_id")
);

INSERT INTO build_infos ("submission_id", "build_log", "exec_time", "build_date", "submission_date")
SELECT "submission_id", "build_log", "exec_time", "build_date", "submission_date"
FROM build_info;

DROP TABLE build_info;
