package database

import (
	"context"
	"errors"

	"github.com/quickfeed/quickfeed/qf"
)

// CreateAssignment creates a new assignment record.
func (db *BunDB) CreateAssignment(assignment *qf.Assignment) error {
	ctx := context.Background()

	// Course id and assignment order must be given.
	if assignment.GetCourseID() < 1 || assignment.GetOrder() < 1 {
		return errors.New("record not found")
	}

	exists, err := db.conn.NewSelect().Model((*qf.Course)(nil)).Where("id = ?", assignment.GetCourseID()).Exists(ctx)
	if err != nil {
		return err
	}
	if !exists {
		return errors.New("such course does not exist")
	}

	// Return the assignment if it exists, create and return a new one if it does not.
	/*assignment, err := db.conn.NewSelect().Model((*qf.Assignment)(nil)).Where("course_id = ? AND order = ?", assignment.GetCourseID(), assignment.GetOrder())


	return db.conn.
		Where(qf.Assignment{
			CourseID: assignment.GetCourseID(),
			Order:    assignment.GetOrder(),
		}).
		Assign(map[string]interface{}{
			"name":              assignment.GetName(),
			"order":             assignment.GetOrder(),
			"deadline":          assignment.GetDeadline().AsTime(),
			"auto_approve":      assignment.GetAutoApprove(),
			"score_limit":       assignment.GetScoreLimit(),
			"is_group_lab":      assignment.GetIsGroupLab(),
			"reviewers":         assignment.GetReviewers(),
			"container_timeout": assignment.GetContainerTimeout(),
			"tasks":             assignment.GetTasks(),
		}).Omit("Tasks").FirstOrCreate(assignment).Error
	*/
	return nil
}
