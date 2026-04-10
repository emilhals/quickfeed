-- Rollback Migration 005: Remove Performance Indexes
-- This migration removes all indexes added in migration 005

DROP INDEX IF EXISTS idx_repositories_repo_type;
DROP INDEX IF EXISTS idx_repositories_enrollment;
DROP INDEX IF EXISTS idx_repositories_group;

DROP INDEX IF EXISTS idx_approval_enrollment;
DROP INDEX IF EXISTS idx_approval_submission;

DROP INDEX IF EXISTS idx_checklist_item_checklist;

DROP INDEX IF EXISTS idx_checklist_assignment;
DROP INDEX IF EXISTS idx_checklist_review;

DROP INDEX IF EXISTS idx_reviews_submission;

DROP INDEX IF EXISTS idx_submissions_group;
DROP INDEX IF EXISTS idx_submissions_user;
DROP INDEX IF EXISTS idx_submissions_assignment;

DROP INDEX IF EXISTS idx_test_info_assignment;

DROP INDEX IF EXISTS idx_feedback_receipt_user;
DROP INDEX IF EXISTS idx_feedback_receipt_assignment;

DROP INDEX IF EXISTS idx_assignment_feedback_course;
DROP INDEX IF EXISTS idx_assignment_feedback_assignment;

DROP INDEX IF EXISTS idx_assignments_course;

DROP INDEX IF EXISTS idx_used_slip_days_assignment;
DROP INDEX IF EXISTS idx_used_slip_days_enrollment;

DROP INDEX IF EXISTS idx_group_users_user;
DROP INDEX IF EXISTS idx_group_users_group;

DROP INDEX IF EXISTS idx_groups_id_status_composite;
DROP INDEX IF EXISTS idx_groups_course;

DROP INDEX IF EXISTS idx_enrollments_status;
DROP INDEX IF EXISTS idx_enrollments_course;
DROP INDEX IF EXISTS idx_enrollments_user;
DROP INDEX IF EXISTS idx_enrollments_id_user_composite;

DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_users_login;
