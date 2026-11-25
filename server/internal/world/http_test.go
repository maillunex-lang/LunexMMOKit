package world

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

type stubAuth map[string]int64

func (s stubAuth) AccountID(token string) (int64, error) {
	id, ok := s[token]
	if !ok {
		return 0, ErrUnknownEntity
	}
	return id, nil
}

func TestHTTPTwoClientsSnapshotAndTeleport(t *testing.T) {
	sim := NewSim()
	h := &HTTP{Sim: sim, Auth: stubAuth{"tokA": 1, "tokB": 2}}
	mux := http.NewServeMux()
	h.Mount(mux)

	join := func(tok, name string, z float64) {
		body, _ := json.Marshal(map[string]any{
			"name": name, "class_actor_id": "10001", "location": "eternity_capital",
			"pos": map[string]float64{"x": 0, "y": 1, "z": z},
		})
		req := httptest.NewRequest(http.MethodPost, "/v1/world/join", bytes.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+tok)
		req.Header.Set("Content-Type", "application/json")
		rr := httptest.NewRecorder()
		mux.ServeHTTP(rr, req)
		if rr.Code != 200 {
			t.Fatalf("join %s: %d %s", tok, rr.Code, rr.Body.String())
		}
	}
	join("tokA", "A", 0)
	join("tokB", "B", 3)

	req := httptest.NewRequest(http.MethodGet, "/v1/world/snapshot", nil)
	req.Header.Set("Authorization", "Bearer tokA")
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)
	if rr.Code != 200 {
		t.Fatal(rr.Body.String())
	}
	var snap struct {
		OK       bool             `json:"ok"`
		Entities []SnapshotEntity `json:"entities"`
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &snap)
	if !snap.OK || len(snap.Entities) < 2 {
		t.Fatalf("snapshot %+v", snap)
	}

	// Teleport cheat
	body, _ := json.Marshal(map[string]any{
		"pos": map[string]float64{"x": 80, "y": 1, "z": 0}, "yaw": 0, "dt": 0.1,
	})
	req = httptest.NewRequest(http.MethodPost, "/v1/world/move", bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer tokA")
	req.Header.Set("Content-Type", "application/json")
	rr = httptest.NewRecorder()
	mux.ServeHTTP(rr, req)
	var mov struct {
		OK   bool       `json:"ok"`
		Move MoveResult `json:"move"`
	}
	_ = json.Unmarshal(rr.Body.Bytes(), &mov)
	if mov.Move.Accepted {
		t.Fatal("teleport accepted over HTTP")
	}
}
