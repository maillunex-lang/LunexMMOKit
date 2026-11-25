package health

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"time"
)

type Response struct {
	OK        bool   `json:"ok"`
	Service   string `json:"service"`
	TimeUTC   string `json:"time_utc"`
	Authority string `json:"authority"`
	Database  string `json:"database"`
}

var DB *sql.DB

func Handle(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	dbStatus := "skipped"
	ok := true
	if DB != nil {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := DB.PingContext(ctx); err != nil {
			dbStatus = "error: " + err.Error()
			ok = false
			w.WriteHeader(http.StatusServiceUnavailable)
		} else {
			dbStatus = "ok"
		}
	}
	_ = json.NewEncoder(w).Encode(Response{
		OK:        ok,
		Service:   "lunexd",
		TimeUTC:   time.Now().UTC().Format(time.RFC3339),
		Authority: "server",
		Database:  dbStatus,
	})
}
