package world

import (
	"encoding/json"
	"net/http"
	"strings"
)

// TokenAccounts resolves bearer tokens to account IDs (auth.Service).
type TokenAccounts interface {
	AccountID(token string) (int64, error)
}

// HTTP exposes N02/C01 world endpoints.
type HTTP struct {
	Sim  *Sim
	Auth TokenAccounts
}

func (h *HTTP) Join(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	accountID, err := h.account(r)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body struct {
		Name         string `json:"name"`
		ClassActorID string `json:"class_actor_id"`
		Location     string `json:"location"`
		Pos          Vec3   `json:"pos"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	if body.Name == "" {
		body.Name = "Hero"
	}
	if body.ClassActorID == "" {
		body.ClassActorID = "10001"
	}
	if body.Location == "" {
		body.Location = "eternity_capital"
	}
	spawn := body.Pos

	ent, err := h.Sim.Join(accountID, body.Name, body.ClassActorID, body.Location, spawn)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	writeJSON(w, map[string]any{"ok": true, "entity": ent})
}

func (h *HTTP) Move(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	accountID, err := h.account(r)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	ent, ok := h.Sim.EntityByAccount(accountID)
	if !ok {
		http.Error(w, "not joined", http.StatusConflict)
		return
	}
	var body struct {
		Pos Vec3    `json:"pos"`
		Yaw float64 `json:"yaw"`
		DT  float64 `json:"dt"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	res, err := h.Sim.Move(ent.ID, body.Pos, body.Yaw, body.DT)
	if err != nil && err != ErrDead {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	// Move already clears AutoBattle when accepted (C03 manual priority)
	writeJSON(w, map[string]any{"ok": true, "move": res})
}

func (h *HTTP) Snapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	accountID, err := h.account(r)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	ent, ok := h.Sim.EntityByAccount(accountID)
	if !ok {
		http.Error(w, "not joined", http.StatusConflict)
		return
	}
	snap, err := h.Sim.Snapshot(ent.ID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	writeJSON(w, map[string]any{"ok": true, "entities": snap, "self_id": ent.ID})
}

func (h *HTTP) Attack(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	accountID, err := h.account(r)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	ent, ok := h.Sim.EntityByAccount(accountID)
	if !ok {
		http.Error(w, "not joined", http.StatusConflict)
		return
	}
	var body struct {
		TargetID     int64  `json:"target_id"`
		SkillID      string `json:"skill_id"`
		ClientDamage int    `json:"client_damage"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	h.Sim.ManualInput(accountID) // manual skill cancels auto-battle
	res, err := h.Sim.Attack(AttackRequest{
		AttackerID: ent.ID, TargetID: body.TargetID,
		SkillID: body.SkillID, ClientDamage: body.ClientDamage,
	})
	// Soft-fail combat errors as 200 with ok:false so clients can show reason
	if err != nil && !res.OK {
		writeJSON(w, map[string]any{"ok": false, "attack": res, "error": err.Error()})
		return
	}
	writeJSON(w, map[string]any{"ok": res.OK, "attack": res})
}

func (h *HTTP) AutoBattle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	accountID, err := h.account(r)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	var body struct {
		Enabled bool `json:"enabled"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	if err := h.Sim.SetAutoBattle(accountID, body.Enabled); err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}
	writeJSON(w, map[string]any{"ok": true, "auto_battle": body.Enabled})
}

func (h *HTTP) Celestial(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	accountID, err := h.account(r)
	if err != nil {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}
	ok, reason, until := h.Sim.ActivateCelestial(accountID)
	writeJSON(w, map[string]any{
		"ok": ok, "reason": reason,
		"until_unix": until.Unix(),
	})
}

func (h *HTTP) account(r *http.Request) (int64, error) {
	tok := bearer(r)
	if h.Auth == nil {
		return 0, ErrUnknownEntity
	}
	return h.Auth.AccountID(tok)
}

func bearer(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if strings.HasPrefix(strings.ToLower(h), "bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}

// Mount registers world routes on mux.
func (h *HTTP) Mount(mux *http.ServeMux) {
	mux.HandleFunc("/v1/world/join", h.Join)
	mux.HandleFunc("/v1/world/move", h.Move)
	mux.HandleFunc("/v1/world/snapshot", h.Snapshot)
	mux.HandleFunc("/v1/world/attack", h.Attack)
	mux.HandleFunc("/v1/world/auto_battle", h.AutoBattle)
	mux.HandleFunc("/v1/world/celestial", h.Celestial)
}
