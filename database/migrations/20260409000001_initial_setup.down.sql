-- Rollback migration: Drop all tables in reverse order of creation

-- Drop indexes first
DROP INDEX IF EXISTS idx_grade;
DROP INDEX IF EXISTS idx_repository;
DROP INDEX IF EXISTS idx_enrollment;
DROP INDEX IF EXISTS idx_group;
DROP INDEX IF EXISTS idx_course;

-- Drop relational tables
DROP TABLE IF EXISTS feedback_receipt;
DROP TABLE IF EXISTS assignment_feedback;
DROP TABLE IF EXISTS test_info;
DROP TABLE IF EXISTS grades;
DROP TABLE IF EXISTS scores;
DROP TABLE IF EXISTS build_infos;
DROP TABLE IF EXISTS issues;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS grading_benchmarks;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS used_slip_days;
DROP TABLE IF EXISTS group_users;

-- Drop child enum tables
DROP TABLE IF EXISTS grading_criterions;
DROP TABLE IF EXISTS submissions;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS groups;

-- Drop parent tables
DROP TABLE IF EXISTS assignments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS users;

-- Drop base enum tables
DROP TABLE IF EXISTS repositories;
DROP TABLE IF EXISTS pull_requests;
