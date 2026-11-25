// Package world — N02 authoritative movement / AOI snapshots (in-memory sim).
package world

import (
	"errors"
	"math"
	"sync"
	"time"
)

var (
	ErrUnknownEntity = errors.New("unknown entity")
	ErrDead          = errors.New("entity dead")
	ErrBadLocation   = errors.New("bad location")
)

// Vec3 is a world-space position (Godot Y-up).
type Vec3 struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
	Z float64 `json:"z"`
}

func (a Vec3) Sub(b Vec3) Vec3 { return Vec3{a.X - b.X, a.Y - b.Y, a.Z - b.Z} }
func (a Vec3) Len() float64    { return math.Sqrt(a.X*a.X + a.Y*a.Y + a.Z*a.Z) }
func (a Vec3) Dist(b Vec3) float64 {
	return a.Sub(b).Len()
}

// Entity is a server-owned actor in a location.
type Entity struct {
	ID           int64   `json:"id"`
	AccountID    int64   `json:"account_id"`
	Name         string  `json:"name"`
	ClassActorID string  `json:"class_actor_id"`
	Location     string  `json:"location"`
	Pos          Vec3    `json:"pos"`
	Yaw          float64 `json:"yaw"`
	HP           int     `json:"hp"`
	MaxHP        int     `json:"max_hp"`
	MP           int     `json:"mp"`
	MaxMP        int     `json:"max_mp"`
	Alive        bool    `json:"alive"`
	LastMove     time.Time
	AtkReadyAt   time.Time
}

// SnapshotEntity is AOI-safe public state.
type SnapshotEntity struct {
	ID           int64   `json:"id"`
	AccountID    int64   `json:"account_id"`
	Name         string  `json:"name"`
	ClassActorID string  `json:"class_actor_id"`
	Location     string  `json:"location"`
	Pos          Vec3    `json:"pos"`
	Yaw          float64 `json:"yaw"`
	HP           int     `json:"hp"`
	MaxHP        int     `json:"max_hp"`
	MP           int     `json:"mp"`
	MaxMP        int     `json:"max_mp"`
	Alive        bool    `json:"alive"`
}

// MoveResult reports whether the intended move was accepted.
type MoveResult struct {
	Accepted bool    `json:"accepted"`
	Reason   string  `json:"reason,omitempty"`
	Pos      Vec3    `json:"pos"`
	Yaw      float64 `json:"yaw"`
}

// Sim is the authoritative world for one process (multi-location map).
type Sim struct {
	mu        sync.Mutex
	nextID    int64
	ents      map[int64]*Entity
	byAccount map[int64]int64
	MaxSpeed  float64 // m/s
	AOIRadius float64
	TickSlack float64
	MinDT     float64
	Now       func() time.Time // injectable for tests
}

func NewSim() *Sim {
	return &Sim{
		ents:      map[int64]*Entity{},
		byAccount: map[int64]int64{},
		MaxSpeed:  6.0,
		AOIRadius: 50.0,
		TickSlack: 1.35,
		MinDT:     0.05,
		Now:       time.Now,
	}
}

func (s *Sim) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

// Join places (or refreshes) an account's entity in a location.
func (s *Sim) Join(accountID int64, name, classID, location string, spawn Vec3) (*Entity, error) {
	if location == "" {
		return nil, ErrBadLocation
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if eid, ok := s.byAccount[accountID]; ok {
		e := s.ents[eid]
		e.Name = name
		e.ClassActorID = classID
		e.Location = location
		e.Pos = spawn
		e.Alive = true
		if e.HP <= 0 {
			e.HP = e.MaxHP
		}
		e.LastMove = s.now()
		cp := *e
		return &cp, nil
	}
	s.nextID++
	id := s.nextID
	e := &Entity{
		ID: id, AccountID: accountID, Name: name, ClassActorID: classID,
		Location: location, Pos: spawn, Yaw: 0,
		HP: 500, MaxHP: 500, MP: 100, MaxMP: 100, Alive: true,
		LastMove: s.now(),
	}
	if classID == "20001" {
		e.HP, e.MaxHP = 420, 420
	}
	s.ents[id] = e
	s.byAccount[accountID] = id
	cp := *e
	return &cp, nil
}

// Leave removes an account from the world.
func (s *Sim) Leave(accountID int64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if eid, ok := s.byAccount[accountID]; ok {
		delete(s.ents, eid)
		delete(s.byAccount, accountID)
	}
}

// Move applies a client intent. Teleport / overspeed cheats are rejected.
func (s *Sim) Move(entityID int64, desired Vec3, yaw float64, clientDT float64) (MoveResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	e, ok := s.ents[entityID]
	if !ok {
		return MoveResult{}, ErrUnknownEntity
	}
	if !e.Alive {
		return MoveResult{Accepted: false, Reason: "dead", Pos: e.Pos, Yaw: e.Yaw}, ErrDead
	}
	dt := clientDT
	if dt < s.MinDT {
		dt = s.MinDT
	}
	if dt > 1.0 {
		dt = 1.0
	}
	dist := e.Pos.Dist(desired)
	maxStep := s.MaxSpeed * dt * s.TickSlack
	if dist > maxStep+0.01 {
		// Teleport / speed hack — keep authoritative position
		return MoveResult{Accepted: false, Reason: "overspeed", Pos: e.Pos, Yaw: e.Yaw}, nil
	}
	e.Pos = desired
	e.Yaw = yaw
	e.LastMove = s.now()
	return MoveResult{Accepted: true, Pos: e.Pos, Yaw: e.Yaw}, nil
}

// Snapshot returns entities in the same location within AOI of the viewer.
func (s *Sim) Snapshot(viewerID int64) ([]SnapshotEntity, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	viewer, ok := s.ents[viewerID]
	if !ok {
		return nil, ErrUnknownEntity
	}
	out := make([]SnapshotEntity, 0, 8)
	for _, e := range s.ents {
		if e.Location != viewer.Location {
			continue
		}
		if e.ID != viewer.ID && viewer.Pos.Dist(e.Pos) > s.AOIRadius {
			continue
		}
		out = append(out, toSnap(e))
	}
	return out, nil
}

// EntityByAccount returns a copy of the entity for an account.
func (s *Sim) EntityByAccount(accountID int64) (*Entity, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	eid, ok := s.byAccount[accountID]
	if !ok {
		return nil, false
	}
	cp := *s.ents[eid]
	return &cp, true
}

func toSnap(e *Entity) SnapshotEntity {
	return SnapshotEntity{
		ID: e.ID, AccountID: e.AccountID, Name: e.Name, ClassActorID: e.ClassActorID,
		Location: e.Location, Pos: e.Pos, Yaw: e.Yaw,
		HP: e.HP, MaxHP: e.MaxHP, MP: e.MP, MaxMP: e.MaxMP, Alive: e.Alive,
	}
}

// Count returns living entities (tests).
func (s *Sim) Count() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return len(s.ents)
}
