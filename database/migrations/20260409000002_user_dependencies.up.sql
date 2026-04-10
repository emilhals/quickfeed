-- Migration 002: User Dependencies - Add NOT NULL constraints and CASCADE deletes
-- This migration adds stricter constraints to user-related tables

-- Step 1: Add NOT NULL constraints to users table
-- SQLite doesn't support ALTER COLUMN, so we need to recreate the table

-- Create new users table with NOT NULL constraints
CREATE TABLE users_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "is_admin" NUMERIC,
    "name" TEXT,
    "student_id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "avatar_url" TEXT NOT NULL,
    "login" TEXT NOT NULL,
    "update_token" NUMERIC,
    "scm_remote_id" INTEGER NOT NULL,
    "refresh_token" TEXT,
    UNIQUE("scm_remote_id"),
    UNIQUE("student_id")
);

-- Copy data from old table
INSERT INTO users_new SELECT * FROM users;

-- Drop old table and rename new one
DROP TABLE users;
ALTER TABLE users_new RENAME TO users;

-- Step 2: Recreate courses with NOT NULL constraints and CASCADE
CREATE TABLE courses_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "course_creator_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "tag" TEXT,
    "scm_organization_id" INTEGER NOT NULL,
    "scm_organization_name" TEXT,
    "slip_days" INTEGER,
    "dockerfile_digest" TEXT,
    CONSTRAINT "fk_users_courses" FOREIGN KEY ("course_creator_id") REFERENCES "users"("id") ON DELETE CASCADE,
    UNIQUE("code", "year")
);

INSERT INTO courses_new SELECT * FROM courses;
DROP TABLE courses;
ALTER TABLE courses_new RENAME TO courses;

-- Step 3: Recreate groups with NOT NULL and CASCADE
CREATE TABLE groups_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "course_id" INTEGER NOT NULL,
    "status" INTEGER NOT NULL DEFAULT 0 CHECK ("status" IN (0, 1)),
    CONSTRAINT "fk_courses_groups" FOREIGN KEY ("course_id") REFERENCES "courses"("id") ON DELETE CASCADE,
    UNIQUE("course_id", "name")
);

INSERT INTO groups_new SELECT * FROM groups;
DROP TABLE groups;
ALTER TABLE groups_new RENAME TO groups;

-- Step 4: Recreate group_users (no changes, just for consistency)
CREATE TABLE group_users_new (
    "group_id" INTEGER,
    "user_id" INTEGER,
    PRIMARY KEY ("group_id", "user_id"),
    CONSTRAINT "fk_group_users_group" FOREIGN KEY ("group_id") REFERENCES "groups"("id"),
    CONSTRAINT "fk_group_users_user" FOREIGN KEY ("user_id") REFERENCES "users"("id")
);

INSERT INTO group_users_new SELECT * FROM group_users;
DROP TABLE group_users;
ALTER TABLE group_users_new RENAME TO group_users;

-- Step 5: Recreate enrollments with CASCADE and updated UNIQUE constraint
CREATE TABLE enrollments_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "user_id" INTEGER NOT NULL,
    "course_id" INTEGER NOT NULL,
    "group_id" INTEGER,
    "status" INTEGER NOT NULL DEFAULT 0 CHECK ("status" IN (0,1,2,3)),
    "state" INTEGER NOT NULL DEFAULT 0 CHECK ("state" IN (0,1,2,3)),
    "last_activity_date" DATETIME,
    "total_approved" INTEGER,
    CONSTRAINT "fk_courses_enrollments" FOREIGN KEY ("course_id") REFERENCES "courses"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_groups_enrollments" FOREIGN KEY ("group_id") REFERENCES "groups"("id") ON DELETE CASCADE,
    CONSTRAINT "fk_users_enrollments" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE,
    UNIQUE("user_id", "course_id")
);

INSERT INTO enrollments_new SELECT * FROM enrollments;
DROP TABLE enrollments;
ALTER TABLE enrollments_new RENAME TO enrollments;

-- Step 6: Transform repositories table structure
-- Old: user_id, group_id, scm_organization_id
-- New: enrollments_id, group_id, scm_repository_id (scm_organization_id removed)
CREATE TABLE repositories_new (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "enrollments_id" INTEGER,
    "group_id" INTEGER,
    "scm_repository_id" INTEGER NOT NULL,
    "html_url" TEXT,
    "repo_type" INTEGER NOT NULL DEFAULT 0 CHECK ("repo_type" IN (0,1,2,3,4,5)),
    CONSTRAINT "fk_groups_repositories" FOREIGN KEY ("group_id") REFERENCES "groups"("id") ON DELETE SET NULL,
    CONSTRAINT "fk_enrollments_repositories" FOREIGN KEY ("enrollments_id") REFERENCES "enrollments"("id") ON DELETE SET NULL,
    CHECK (("group_id" != 0 AND "enrollments_id" = 0)
        OR ("group_id" = 0 AND "enrollments_id" != 0))
);

-- Migrate data: Map user_id to enrollments_id via enrollments table
-- For user repositories, find the enrollment_id
INSERT INTO repositories_new ("id", "enrollments_id", "group_id", "scm_repository_id", "html_url", "repo_type")
SELECT
    r.id,
    CASE
        WHEN r.user_id != 0 THEN (SELECT e.id FROM enrollments e WHERE e.user_id = r.user_id LIMIT 1)
        ELSE 0
    END as enrollments_id,
    r.group_id,
    COALESCE(r.scm_repository_id, r.scm_organization_id) as scm_repository_id,
    r.html_url,
    r.repo_type
FROM repositories r;

DROP TABLE repositories;
ALTER TABLE repositories_new RENAME TO repositories;
