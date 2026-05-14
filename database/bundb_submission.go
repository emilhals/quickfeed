package database

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/quickfeed/quickfeed/kit/score"
	"github.com/quickfeed/quickfeed/qf"
	"github.com/uptrace/bun"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// CreateSubmission creates a new submission record or updates the most
// recent submission, as defined by the provided submission query.
func (db *BunDB) CreateSubmission(submission *qf.Submission) error {
	if err := db.checkSubmission(submission); err != nil {
		return err
	}
	ctx := context.Background()
	return db.conn.RunInTx(ctx, nil, func(ctx context.Context, tx bun.Tx) error {
		if submission.GetID() != 0 {
			exists, err := tx.NewSelect().Model((*qf.Submission)(nil)).
				Where("id = ?", submission.GetID()).Exists(ctx)
			if err != nil {
				return err
			}
			if !exists {
				return fmt.Errorf("submission %d not found", submission.GetID())
			}
			if _, err := tx.NewDelete().Model((*score.Score)(nil)).
				Where("submission_id = ?", submission.GetID()).Exec(ctx); err != nil {
				return err
			}
			if _, err := tx.NewDelete().Model((*score.BuildInfo)(nil)).
				Where("submission_id = ?", submission.GetID()).Exec(ctx); err != nil {
				return err
			}
			if submission.GetBuildInfo() != nil {
				submission.BuildInfo.SubmissionID = submission.GetID()
			}
			for _, sc := range submission.GetScores() {
				sc.SubmissionID = submission.GetID()
			}
		} else {
			if err := bunSetGrades(ctx, tx, submission); err != nil {
				return err
			}
		}
		_, err := tx.NewInsert().Model(submission).
			On("CONFLICT (id) DO UPDATE").
			Set("score = EXCLUDED.score, status = EXCLUDED.status, approved = EXCLUDED.approved").
			Exec(ctx)
		return err
	})
}

// bunSetGrades initializes grade records for a new submission.
func bunSetGrades(ctx context.Context, tx bun.Tx, submission *qf.Submission) error {
	var userIDs []uint64
	if submission.GetUserID() > 0 {
		userIDs = []uint64{submission.GetUserID()}
	}
	if submission.GetGroupID() > 0 {
		if err := tx.NewSelect().Model((*qf.Enrollment)(nil)).
			Column("user_id").
			Where("group_id = ?", submission.GetGroupID()).
			Scan(ctx, &userIDs); err != nil {
			return err
		}
	}
	if submission.GetGrades() == nil {
		submission.Grades = make([]*qf.Grade, len(userIDs))
		for i, userID := range userIDs {
			submission.Grades[i] = &qf.Grade{UserID: userID}
		}
	}
	var assignment qf.Assignment
	if err := tx.NewSelect().Model(&assignment).
		Where("id = ?", submission.GetAssignmentID()).Scan(ctx); err != nil {
		return err
	}
	submission.SetGradesIfApproved(&assignment, submission.GetScore())
	return nil
}

// checkSubmission returns an error if the submission is invalid.
func (db *BunDB) checkSubmission(submission *qf.Submission) error {
	ctx := context.Background()
	if submission.GetAssignmentID() < 1 {
		return ErrInvalidAssignmentID
	}
	switch {
	case submission.GetUserID() > 0 && submission.GetGroupID() > 0:
		return ErrInvalidSubmission
	case submission.GetUserID() > 0:
		exists, err := db.conn.NewSelect().Model((*qf.User)(nil)).
			Where("id = ?", submission.GetUserID()).Exists(ctx)
		if err != nil {
			return fmt.Errorf("user %d not found for submission: %w", submission.GetUserID(), err)
		}
		if !exists {
			return fmt.Errorf("user %d not found for submission: %+v", submission.GetUserID(), submission)
		}
	case submission.GetGroupID() > 0:
		exists, err := db.conn.NewSelect().Model((*qf.Group)(nil)).
			Where("id = ?", submission.GetGroupID()).Exists(ctx)
		if err != nil {
			return fmt.Errorf("group %d not found for submission: %w", submission.GetGroupID(), err)
		}
		if !exists {
			return fmt.Errorf("group %d not found for submission: %+v", submission.GetGroupID(), submission)
		}
	default:
		return ErrInvalidSubmission
	}
	exists, err := db.conn.NewSelect().Model((*qf.Assignment)(nil)).
		Where("id = ?", submission.GetAssignmentID()).Exists(ctx)
	if err != nil {
		return fmt.Errorf("assignment %d not found: %w", submission.GetAssignmentID(), err)
	}
	if !exists {
		return fmt.Errorf("assignment %d not found", submission.GetAssignmentID())
	}
	return nil
}

// GetSubmission fetches a submission record matching the given query.
func (db *BunDB) GetSubmission(query *qf.Submission) (*qf.Submission, error) {
	ctx := context.Background()
	var submission qf.Submission
	q := db.conn.NewSelect().
		Model(&submission).
		Relation("Reviews").
		Relation("BuildInfo").
		Relation("Scores").
		Relation("Grades").
		Relation("Reviews.GradingBenchmarks").
		Relation("Reviews.GradingBenchmarks.Criteria")
	if query.GetID() > 0 {
		q = q.Where("submission.id = ?", query.GetID())
	}
	if query.GetAssignmentID() > 0 {
		q = q.Where("submission.assignment_id = ?", query.GetAssignmentID())
	}
	if query.GetUserID() > 0 {
		q = q.Where("submission.user_id = ?", query.GetUserID())
	}
	if query.GetGroupID() > 0 {
		q = q.Where("submission.group_id = ?", query.GetGroupID())
	}
	if err := q.OrderExpr("submission.id DESC").Limit(1).Scan(ctx); err != nil {
		return nil, err
	}
	return &submission, nil
}

// GetLastSubmission returns the last submission for the given query and course ID.
func (db *BunDB) GetLastSubmission(courseID uint64, query *qf.Submission) (*qf.Submission, error) {
	submission, err := db.GetSubmission(query)
	if err != nil {
		return nil, err
	}
	exists, err := db.conn.NewSelect().Model((*qf.Assignment)(nil)).
		Where("id = ? AND course_id = ?", submission.GetAssignmentID(), courseID).
		Exists(context.Background())
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, fmt.Errorf("assignment %d not found for course %d", submission.GetAssignmentID(), courseID)
	}
	return submission, nil
}

// GetLastSubmissions returns all latest submissions for the given course and query.
func (db *BunDB) GetLastSubmissions(courseID uint64, query *qf.Submission) ([]*qf.Submission, error) {
	ctx := context.Background()
	var course qf.Course
	if err := db.conn.NewSelect().
		Model(&course).
		Relation("Assignments").
		Where("course.id = ?", courseID).
		Scan(ctx); err != nil {
		return nil, err
	}
	var latestSubs []*qf.Submission
	for _, a := range course.GetAssignments() {
		query.AssignmentID = a.GetID()
		temp, err := db.GetSubmission(query)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				continue
			}
			return nil, err
		}
		latestSubs = append(latestSubs, temp)
	}
	return latestSubs, nil
}

// GetSubmissions returns all submissions matching the query.
func (db *BunDB) GetSubmissions(query *qf.Submission) ([]*qf.Submission, error) {
	if _, err := db.GetAssignment(&qf.Assignment{ID: query.GetAssignmentID()}); err != nil {
		return nil, err
	}
	ctx := context.Background()
	var submissions []*qf.Submission
	q := db.conn.NewSelect().Model(&submissions).Relation("Grades")
	if query.GetAssignmentID() > 0 {
		q = q.Where("submission.assignment_id = ?", query.GetAssignmentID())
	}
	if query.GetUserID() > 0 {
		q = q.Where("submission.user_id = ?", query.GetUserID())
	}
	if query.GetGroupID() > 0 {
		q = q.Where("submission.group_id = ?", query.GetGroupID())
	}
	if err := q.Scan(ctx); err != nil {
		return nil, err
	}
	return submissions, nil
}

// UpdateSubmission updates submission with the given approved status.
func (db *BunDB) UpdateSubmission(query *qf.Submission) error {
	ctx := context.Background()
	_, err := db.conn.NewUpdate().Model(query).WherePK().Exec(ctx)
	return err
}

// GetReview fetches a review matching the given query.
func (db *BunDB) GetReview(query *qf.Review) (*qf.Review, error) {
	ctx := context.Background()
	var review qf.Review
	q := db.conn.NewSelect().
		Model(&review).
		Relation("GradingBenchmarks").
		Relation("GradingBenchmarks.Criteria")
	if query.GetID() > 0 {
		q = q.Where("review.id = ?", query.GetID())
	}
	if query.GetSubmissionID() > 0 {
		q = q.Where("review.submission_id = ?", query.GetSubmissionID())
	}
	if err := q.Scan(ctx); err != nil {
		return nil, err
	}
	return &review, nil
}

// CreateReview creates a new submission review.
func (db *BunDB) CreateReview(query *qf.Review) error {
	submission, err := db.GetSubmission(&qf.Submission{ID: query.GetSubmissionID()})
	if err != nil {
		return err
	}
	assignment, err := db.GetAssignment(&qf.Assignment{ID: submission.GetAssignmentID()})
	if err != nil {
		return err
	}
	if len(submission.GetReviews()) >= int(assignment.GetReviewers()) {
		return ErrAllReviewsCreated(submission.GetID(), assignment.GetName(), assignment.GetReviewers())
	}
	query.Edited = timestamppb.Now()
	query.ComputeScore()
	benchmarks, err := db.GetBenchmarks(&qf.Assignment{ID: submission.GetAssignmentID()})
	if err != nil {
		return err
	}
	query.GradingBenchmarks = benchmarks
	for _, bm := range query.GetGradingBenchmarks() {
		bm.ID = 0
		for _, c := range bm.GetCriteria() {
			c.ID = 0
		}
	}
	ctx := context.Background()
	_, err = db.conn.NewInsert().Model(query).Exec(ctx)
	return err
}

// UpdateReview updates a review.
func (db *BunDB) UpdateReview(query *qf.Review) error {
	if query.GetID() == 0 {
		return ErrEmptyReviewID
	}
	submission, err := db.GetSubmission(&qf.Submission{ID: query.GetSubmissionID()})
	if err != nil {
		return err
	}
	query.Edited = timestamppb.Now()
	query.ComputeScore()
	for id, review := range submission.GetReviews() {
		if review.GetID() == query.GetID() {
			submission.Reviews[id] = query
			break
		}
	}
	submission.Score = query.GetScore()
	return db.UpdateSubmission(submission)
}

// DeleteReview removes all reviews matching the query.
func (db *BunDB) DeleteReview(query *qf.Review) error {
	ctx := context.Background()
	q := db.conn.NewDelete().Model((*qf.Review)(nil))
	if query.GetID() > 0 {
		q = q.Where("id = ?", query.GetID())
	}
	if query.GetSubmissionID() > 0 {
		q = q.Where("submission_id = ?", query.GetSubmissionID())
	}
	_, err := q.Exec(ctx)
	return err
}
