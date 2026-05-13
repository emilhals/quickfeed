package database

import (
	"context"
	"errors"

	"github.com/quickfeed/quickfeed/qf"
)

// CreateUser creates new user record. The first user is set as admin.
func (db *BunDB) CreateUser(user *qf.User) error {
	ctx := context.Background()

	if _, err := db.conn.NewInsert().Model(&user).Exec(ctx); err != nil {
		return err
	}
	// The first user defaults to admin user.
	if user.GetID() == 1 {
		user.IsAdmin = true
		// implement update user
	}
	return nil
}

// GetUser returns the given user.
func (db *BunDB) GetUser(userID uint64) (*qf.User, error) {
	ctx := context.Background()

	var user qf.User
	if err := db.conn.NewSelect().Model(&user).Where("id = ?", userID).Scan(ctx); err != nil {
		return nil, err
	}
	return &user, nil
}

// GetUserByRemoteIdentity returns the user for the given remote identity.
func (db *BunDB) GetUserByRemoteIdentity(scmRemoteID uint64) (*qf.User, error) {
	ctx := context.Background()

	var user qf.User
	if err := db.conn.NewSelect().Model(&user).Where("scm_remote_id = ?", scmRemoteID).Scan(ctx); err != nil {
		return nil, err
	}
	return &user, nil
}

// GetUserByCourse returns the given user with enrollments matching the given course query.
func (db *BunDB) GetUserByCourse(query *qf.Course, login string) (*qf.User, error) {
	ctx := context.Background()

	var user qf.User
	var course qf.Course
	enrollmentStatuses := []qf.Enrollment_UserStatus{
		qf.Enrollment_STUDENT,
		qf.Enrollment_TEACHER,
	}

	if err := db.conn.NewSelect().Model(&course).Where("id = ?", query.GetID()).Scan(ctx); err != nil {
		return nil, err
	}

	if err := db.conn.
		Preload("Enrollments", "status in (?)", enrollmentStatuses).
		First(&user, &qf.User{Login: login}).Error; err != nil {
		return nil, err
	}
	for _, e := range user.GetEnrollments() {
		if e.GetCourseID() == course.GetID() {
			user.Enrollments = make([]*qf.Enrollment, 0)
			return &user, nil
		}
	}
	return nil, ErrNotEnrolled
}

// GetUserWithEnrollments returns the given user with enrollments.
func (db *BunDB) GetUserWithEnrollments(userID uint64) (*qf.User, error) {
	ctx := context.Background()

	var user qf.User
	if err := db.conn.
		NewSelect().
		Model(&user).
		Where("id = ?", userID).
		Relation("Enrollments").
		Relation("Enrollments.Course").
		Relation("Enrollments.UsedSlipDays").
		Relation("FeedbackReceipts").
		Scan(ctx); err != nil {
		return nil, err
	}
	return &user, nil
}

// GetUsers fetches all users by provided IDs.
func (db *BunDB) GetUsers(userIDs ...uint64) ([]*qf.User, error) {
	ctx := context.Background()

	var users []*qf.User

	m := db.conn.NewSelect().Model((*qf.User)(nil))
	if len(userIDs) > 0 {
		m = m.Where("id = ?", userIDs)
	}
	if err := m.Scan(ctx, &users); err != nil {
		return nil, err
	}
	return users, nil
}

// UpdateUser updates user information.
func (db *BunDB) UpdateUser(user *qf.User) error {
	ctx := context.Background()

	exists, err := db.conn.NewSelect().Model(&user).Exists(ctx)
	if err != nil {
		return err
	}
	if !exists {
		return errors.New("such user does not exist")
	}

	_, err = db.conn.NewUpdate().Model(&user).WherePK().Exec(ctx)
	return err
}
