package auth

import (
	"encoding/json"
	"net/http"
	"os"
	"strings"
)

type HTTP struct {
	Svc *Service
}

func (h *HTTP) Register(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	var body struct {
		Login    string `json:"login"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	id, err := h.Svc.Register(r.Context(), body.Login, body.Password)
	if err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}
	writeJSON(w, map[string]any{"ok": true, "account_id": id})
}

func (h *HTTP) Login(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	var body struct {
		Login    string `json:"login"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	token, id, err := h.Svc.Login(r.Context(), body.Login, body.Password)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	writeJSON(w, map[string]any{"ok": true, "token": token, "account_id": id, "protocol_version": 1})
}

func (h *HTTP) Logout(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	h.Svc.Logout(bearer(r))
	writeJSON(w, map[string]any{"ok": true})
}

func (h *HTTP) Session(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	token := bearer(r)
	accountID, err := h.Svc.AccountID(token)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	writeJSON(w, map[string]any{
		"ok": true, "account_id": accountID, "protocol_version": 1, "session": "active",
	})
}

// Expire is a DEV/TEST-only hook (LUNEX_ALLOW_TEST_EXPIRE=1) for N01 expired-token checks.
func (h *HTTP) Expire(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	if os.Getenv("LUNEX_ALLOW_TEST_EXPIRE") != "1" {
		http.Error(w, "forbidden", http.StatusForbidden)
		return
	}
	tok := bearer(r)
	h.Svc.ExpireTokenForTest(tok)
	writeJSON(w, map[string]any{"ok": true, "expired": true})
}

func (h *HTTP) Characters(w http.ResponseWriter, r *http.Request) {
	token := bearer(r)
	accountID, err := h.Svc.AccountID(token)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	switch r.Method {
	case http.MethodGet:
		list, err := h.Svc.ListCharacters(r.Context(), accountID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if list == nil {
			list = []map[string]any{}
		}
		writeJSON(w, map[string]any{"ok": true, "characters": list})
	case http.MethodPost:
		var body struct {
			Name          string `json:"name"`
			ClassActorID  string `json:"class_actor_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			http.Error(w, "bad json", http.StatusBadRequest)
			return
		}
		if body.ClassActorID == "" {
			body.ClassActorID = "10001"
		}
		id, err := h.Svc.CreateCharacter(r.Context(), accountID, body.Name, body.ClassActorID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusConflict)
			return
		}
		writeJSON(w, map[string]any{"ok": true, "character_id": id})
	default:
		http.Error(w, "method", http.StatusMethodNotAllowed)
	}
}

func bearer(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if strings.HasPrefix(h, "Bearer ") {
		return strings.TrimPrefix(h, "Bearer ")
	}
	return r.Header.Get("X-Lunex-Token")
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
