package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"os"

	"github.com/uptrace/bun"
	"github.com/uptrace/bun/dialect/sqlitedialect"
	"github.com/uptrace/bun/driver/sqliteshim"
	"github.com/uptrace/bun/migrate"
)

var (
	cmd    = flag.String("cmd", "", "Command to run: init, up, down, status")
	dbPath = flag.String("db", "qf.db", "Path to SQLite database file")
)

func main() {
	flag.Parse()

	if *cmd == "" {
		fmt.Println("Usage: go run main.go -cmd=<init|up|down|status> [-db=path/to/db]")
		os.Exit(1)
	}

	sqldb, err := sql.Open(sqliteshim.ShimName, *dbPath)
	if err != nil {
		fmt.Printf("Failed to open database: %v\n", err)
		os.Exit(1)
	}
	defer sqldb.Close()

	db := bun.NewDB(sqldb, sqlitedialect.New())
	defer db.Close()

	ctx := context.Background()
	migrator := migrate.NewMigrator(db, Migrations)

	switch *cmd {
	case "init":
		if err := migrator.Init(ctx); err != nil {
			fmt.Printf("Failed to initialize migrations: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("Migration system initialized")

	case "up":
		if err := migrator.Lock(ctx); err != nil {
			fmt.Printf("Failed to acquire migration lock: %v\n", err)
			os.Exit(1)
		}
		defer migrator.Unlock(ctx)

		group, err := migrator.Migrate(ctx)
		if err != nil {
			fmt.Printf("Migration failed: %v\n", err)
			os.Exit(1)
		}
		if group.IsZero() {
			fmt.Println("No new migrations to run")
		} else {
			fmt.Printf("Migrated to %s\n", group)
		}

	case "down":
		if err := migrator.Lock(ctx); err != nil {
			fmt.Printf("Failed to acquire migration lock: %v\n", err)
			os.Exit(1)
		}
		defer migrator.Unlock(ctx)

		group, err := migrator.Rollback(ctx)
		if err != nil {
			fmt.Printf("Rollback failed: %v\n", err)
			os.Exit(1)
		}
		if group.IsZero() {
			fmt.Println("No migrations to roll back")
		} else {
			fmt.Printf("Rolled back %s\n", group)
		}

	case "status":
		ms, err := migrator.MigrationsWithStatus(ctx)
		if err != nil {
			fmt.Printf("Failed to get migration status: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("Migrations:\n")
		for _, m := range ms {
			status := "pending"
			if m.GroupID > 0 {
				status = fmt.Sprintf("applied (group %d)", m.GroupID)
			}
			fmt.Printf("  %s - %s\n", m.Name, status)
		}

	default:
		fmt.Printf("Unknown command: %s\n", *cmd)
		fmt.Println("Valid commands: init, up, down, status")
		os.Exit(1)
	}
}
