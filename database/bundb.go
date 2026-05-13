package database

import (
	"database/sql"

	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/sqlitedialect"
	"go.uber.org/zap"
)

// BunDB implements the Database interface.
type BunDB struct {
	conn *bun.DB
}

// NewBunDB creates a new bun database using the provided driver.
func NewBunDB(path string, logger *zap.Logger) (*BunDB, error) {
	sqlDB, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	conn := bun.NewDB(sqlDB, sqlitedialect.New())

	/*schema.RegisterSerializer("timestamp", &TimestampSerializer{})

	if err := conn.AutoMigrate(
		&qf.User{},
		&qf.Course{},
		&qf.Enrollment{},
		&qf.Assignment{},
		&qf.Submission{},
		&qf.Grade{},
		&qf.Group{},
		&qf.Repository{},
		&qf.UsedSlipDays{},
		&qf.GradingBenchmark{},
		&qf.TestInfo{},
		&qf.GradingCriterion{},
		&qf.Review{},
		&qf.AssignmentFeedback{},
		&qf.FeedbackReceipt{},
		&qf.Issue{},
		&qf.Task{},
		&qf.PullRequest{},
		&score.BuildInfo{},
		&score.Score{},
	); err != nil {
		return nil, err
	}*/

	return &BunDB{conn}, nil
}

func (db *BunDB) Close() error {
	sqlDB := db.conn.DB
	return sqlDB.Close()
}
