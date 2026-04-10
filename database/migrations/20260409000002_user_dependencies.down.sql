-- Rollback Migration 002: User Dependencies
-- Reverses NOT NULL constraints and CASCADE deletes

-- Step 1: Restore repositories table structure
CREATE TABLE repositories_old (
    "id" INTEGER PRIMARY KEY,
    "scm_organization_id" INTEGER NOT NULL,
    "scm_repository_id" INTEGER,
    "user_id" INTEGER NOT NULL,
    "group_id" INTEGER NOT NULL,
    "html_url" TEXT,
    "repo_type" INTEGER NOT NULL DEFAULT 0 CHECK ("repo_type" IN (0,1,2,3,4,5)),
    CONSTRAINT "fk_users_repositories" FOREIGN KEY ("user_id") REFERENCES "users"("id"),
    CONSTRAINT "fk_groups_repositories" FOREIGN KEY ("group_id") REFERENCES "groups"("id"),
    UNIQUE("scm_organization_id", "user_id", "group_id", "repo_type")
);

-- Migrate data back: Map enrollments_id to user_id
INSERT INTO repositories_old ("id", "scm_organization_id", "scm_repository_id", "user_id", "group_id", "html_url", "repo_type")
SELECT
    r.id,
    r.scm_repository_id as scm_organization_id,
    r.scm_repository_id,
    CASE
        WHEN r.enrollments_id != 0 THEN (SELECT e.user_id FROM enrollments e WHERE e.id = r.enrollments_id)
        ELSE 0
    END as user_id,
    r.group_id,
    r.html_url,
    r.repo_type
FROM repositories r;

DROP TABLE repositories;
ALTER TABLE repositories_old RENAME TO repositories;

-- Step 2: Restore enrollments (remove CASCADE, restore UNIQUE constraint order)
CREATE TABLE enrollments_old (
    "id" INTEGER PRIMARY KEY,
    "course_id" INTEGER NOT NULL,
    "user_id" INTEGER NOT NULL,
    "group_id" INTEGER,
    "status" INTEGER NOT NULL DEFAULT 0 CHECK ("status" IN (0,1,2,3)),
    "state" INTEGER NOT NULL DEFAULT 0 CHECK ("state" IN (0,1,2,3)),
    "last_activity_date" DATETIME,
    "total_approved" INTEGER,
    CONSTRAINT "fk_courses_enrollments" FOREIGN KEY ("course_id") REFERENCES "courses"("id"),
    CONSTRAINT "fk_groups_enrollments" FOREIGN KEY ("group_id") REFERENCES "groups"("id"),
    CONSTRAINT "fk_users_enrollments" FOREIGN KEY ("user_id") REFERENCES "users"("id"),
    UNIQUE("course_id", "user_id")
);

INSERT INTO enrollments_old SELECT * FROM enrollments;
DROP TABLE enrollments;
ALTER TABLE enrollments_old RENAME TO enrollments;

-- Step 3: Restore group_users
CREATE TABLE group_users_old (
    "group_id" INTEGER,
    "user_id" INTEGER,
    PRIMARY KEY ("group_id","user_id"),
    CONSTRAINT "fk_group_users_group" FOREIGN KEY ("group_id") REFERENCES "groups"("id"),
    CONSTRAINT "fk_group_users_user" FOREIGN KEY ("user_id") REFERENCES "users"("id")
);

INSERT INTO group_users_old SELECT * FROM group_users;
DROP TABLE group_users;
ALTER TABLE group_users_old RENAME TO group_users;

-- Step 4: Restore groups (remove NOT NULL on name, remove CASCADE)
CREATE TABLE groups_old (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT,
    "course_id" INTEGER NOT NULL,
    "status" INTEGER NOT NULL DEFAULT 0 CHECK ("status" IN (0, 1)),
    CONSTRAINT "fk_courses_groups" FOREIGN KEY ("course_id") REFERENCES "courses"("id"),
    UNIQUE("course_id", "name")
);

INSERT INTO groups_old SELECT * FROM groups;
DROP TABLE groups;
ALTER TABLE groups_old RENAME TO groups;

-- Step 5: Restore courses (remove NOT NULL constraints, remove CASCADE)
CREATE TABLE courses_old (
    "id" INTEGER PRIMARY KEY,
    "course_creator_id" INTEGER NOT NULL,
    "name" TEXT,
    "code" TEXT,
    "year" INTEGER,
    "tag" TEXT,
    "scm_organization_id" INTEGER,
    "scm_organization_name" TEXT,
    "slip_days" INTEGER,
    "dockerfile_digest" TEXT,
    UNIQUE("code", "year")
);

INSERT INTO courses_old SELECT * FROM courses;
DROP TABLE courses;
ALTER TABLE courses_old RENAME TO courses;

-- Step 6: Restore users (remove NOT NULL constraints)
CREATE TABLE users_old (
    "id" INTEGER PRIMARY KEY,
    "is_admin" INTEGER NOT NULL DEFAULT 0,
    "name" TEXT,
    "student_id" TEXT NOT NULL,
    "email" TEXT,
    "avatar_url" TEXT,
    "login" TEXT,
    "update_token" NUMERIC,
    "scm_remote_id" INTEGER NOT NULL,
    "refresh_token" TEXT,
    UNIQUE("scm_remote_id"),
    UNIQUE("student_id")
);

INSERT INTO users_old SELECT * FROM users;
DROP TABLE users;
ALTER TABLE users_old RENAME TO users;
