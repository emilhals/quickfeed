-- Migration 005: Add Performance Indexes
-- This migration adds indexes for improved query performance

-- Users - for lookups during login and joins
CREATE INDEX IF NOT EXISTS idx_users_login ON "users"("login");
CREATE INDEX IF NOT EXISTS idx_users_email ON "users"("email");

-- Enrollments - speeds up enrollment queries and updates
CREATE INDEX IF NOT EXISTS idx_enrollments_id_user_composite ON "enrollments"("id", "user_id");
CREATE INDEX IF NOT EXISTS idx_enrollments_user ON "enrollments"("user_id");
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON "enrollments"("course_id");
CREATE INDEX IF NOT EXISTS idx_enrollments_status ON "enrollments"("status");

-- Groups - for group lookups
CREATE INDEX IF NOT EXISTS idx_groups_course ON "groups"("course_id");
CREATE INDEX IF NOT EXISTS idx_groups_id_status_composite ON "groups"("status", "id");

-- Group users - needed to find user/group from group_user table
CREATE INDEX IF NOT EXISTS idx_group_users_group ON "group_users"("group_id");
CREATE INDEX IF NOT EXISTS idx_group_users_user ON "group_users"("user_id");

-- Used slip days - for slip day calculations
CREATE INDEX IF NOT EXISTS idx_used_slip_days_enrollment ON "used_slip_days"("enrollment_id");
CREATE INDEX IF NOT EXISTS idx_used_slip_days_assignment ON "used_slip_days"("assignment_id");

-- Assignments - for fetching assignments by course
CREATE INDEX IF NOT EXISTS idx_assignments_course ON "assignments"("course_id");

-- Assignment feedback - for feedback queries
CREATE INDEX IF NOT EXISTS idx_assignment_feedback_assignment ON "assignment_feedback"("assignment_id");
CREATE INDEX IF NOT EXISTS idx_assignment_feedback_course ON "assignment_feedback"("course_id");

-- Feedback receipt - for tracking feedback receipts
CREATE INDEX IF NOT EXISTS idx_feedback_receipt_assignment ON "feedback_receipt"("assignment_id");
CREATE INDEX IF NOT EXISTS idx_feedback_receipt_user ON "feedback_receipt"("user_id");

-- Test info - for displaying test names on webpage
CREATE INDEX IF NOT EXISTS idx_test_info_assignment ON "test_info"("assignment_id");

-- Submissions - for frequent submission queries
CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON "submissions"("assignment_id");
CREATE INDEX IF NOT EXISTS idx_submissions_user ON "submissions"("user_id");
CREATE INDEX IF NOT EXISTS idx_submissions_group ON "submissions"("group_id");

-- Reviews - for fetching reviews by submission
CREATE INDEX IF NOT EXISTS idx_reviews_submission ON "reviews"("submission_id");

-- Checklist - for review checklists
CREATE INDEX IF NOT EXISTS idx_checklist_review ON "checklist"("review_id");
CREATE INDEX IF NOT EXISTS idx_checklist_assignment ON "checklist"("assignment_id");

-- Checklist item - for checklist items
CREATE INDEX IF NOT EXISTS idx_checklist_item_checklist ON "checklist_item"("checklist_id");

-- Approval - for approval tracking
CREATE INDEX IF NOT EXISTS idx_approval_submission ON "approval"("submission_id");
CREATE INDEX IF NOT EXISTS idx_approval_enrollment ON "approval"("enrollment_id");

-- Repositories - for repository lookups
CREATE INDEX IF NOT EXISTS idx_repositories_group ON "repositories"("group_id");
CREATE INDEX IF NOT EXISTS idx_repositories_enrollment ON "repositories"("enrollments_id");
CREATE INDEX IF NOT EXISTS idx_repositories_repo_type ON "repositories"("repo_type");
