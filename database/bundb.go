package database

import (
	"database/sql"

	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/sqlitedialect"
	"github.com/uptrace/bun/driver/sqliteshim"
)

// BunDB wraps a bun.DB connection for database operations.
type BunDB struct {
	db *bun.DB
}

// NewBunDB creates a new BunDB instance with SQLite driver.
func NewBunDB(path string) (*BunDB, error) {
	sqldb, err := sql.Open(sqliteshim.ShimName, path)
	if err != nil {
		return nil, err
	}
	return &BunDB{db: bun.NewDB(sqldb, sqlitedialect.New())}, nil
}

// Close closes the database connection.
func (db *BunDB) Close() error {
	return db.db.Close()
}
