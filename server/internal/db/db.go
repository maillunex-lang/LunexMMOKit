package db

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
)

func OpenFromEnv() (*sql.DB, error) {
	url := os.Getenv("LUNEX_DATABASE_URL")
	if url == "" {
		return nil, fmt.Errorf("LUNEX_DATABASE_URL not set")
	}
	return Open(url)
}

func Open(url string) (*sql.DB, error) {
	d, err := sql.Open("pgx", url)
	if err != nil {
		return nil, err
	}
	d.SetMaxOpenConns(8)
	d.SetConnMaxLifetime(30 * time.Minute)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := d.PingContext(ctx); err != nil {
		_ = d.Close()
		return nil, err
	}
	return d, nil
}
