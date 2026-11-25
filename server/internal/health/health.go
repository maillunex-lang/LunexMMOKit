package health

import (
	"encoding/json"
	"net/http"
	"time"
)

type Response struct {
	OK        bool   `json:"ok"`
	Service   string `json:"service"`
	TimeUTC   string `json:"time_utc"`
	Authority string `json:"authority"`
}

func Handle(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(Response{
		OK:        true,
		Service:   "lunexd",
		TimeUTC:   time.Now().UTC().Format(time.RFC3339),
		Authority: "server", // client must not invent final combat/loot/quest rewards
	})
}
