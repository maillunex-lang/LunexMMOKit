package world

import (
	"errors"
	"time"
)

var (
	ErrNoEnergy  = errors.New("celestial energy low")
	ErrFormCD    = errors.New("celestial on cooldown")
	ErrNotPlayer = errors.New("not a player")
)

// SetAutoBattle enables/disables server-side auto attack assist (C03).
func (s *Sim) SetAutoBattle(accountID int64, enabled bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	eid, ok := s.byAccount[accountID]
	if !ok {
		return ErrUnknownEntity
	}
	e := s.ents[eid]
	if e.Kind != KindPlayer {
		return ErrNotPlayer
	}
	e.AutoBattle = enabled
	return nil
}

// CancelAuto clears auto-battle on manual input priority (C03 accept).
func (s *Sim) CancelAuto(accountID int64) error {
	return s.SetAutoBattle(accountID, false)
}

// ActivateCelestial toggles temporary celestial form — server validates energy/CD.
func (s *Sim) ActivateCelestial(accountID int64) (ok bool, reason string, until time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	eid, okAcc := s.byAccount[accountID]
	if !okAcc {
		return false, "unknown", time.Time{}
	}
	e := s.ents[eid]
	now := s.now()
	if now.Before(e.CelestialReadyAt) {
		return false, "cooldown", time.Time{}
	}
	if e.CelestialEnergy < 50 {
		return false, "energy", time.Time{}
	}
	e.CelestialEnergy -= 50
	e.Celestial = true
	e.CelestialUntil = now.Add(8 * time.Second)
	e.CelestialReadyAt = now.Add(20 * time.Second)
	return true, "", e.CelestialUntil
}

// TickAutoBattle picks nearest hostile and issues a basic attack for auto-enabled players.
func (s *Sim) TickAutoBattle() []AttackResult {
	s.mu.Lock()
	type job struct{ atk, tgt int64 }
	var jobs []job
	for _, e := range s.ents {
		if e.Kind != KindPlayer || !e.AutoBattle || !e.Alive {
			continue
		}
		var best int64
		bestD := 1e9
		for _, m := range s.ents {
			if (m.Kind != KindMob && m.Kind != KindBoss) || !m.Alive || m.Location != e.Location {
				continue
			}
			d := e.Pos.Dist(m.Pos)
			if d < bestD {
				bestD = d
				best = m.ID
			}
		}
		if best != 0 && bestD <= 6.0 {
			jobs = append(jobs, job{e.ID, best})
		}
	}
	s.mu.Unlock()
	var out []AttackResult
	for _, j := range jobs {
		res, _ := s.Attack(AttackRequest{AttackerID: j.atk, TargetID: j.tgt, SkillID: "basic"})
		if res.OK {
			out = append(out, res)
		}
	}
	return out
}

// ManualInput cancels auto-battle (manual priority). Call from Move/Attack when player issues intent.
func (s *Sim) ManualInput(accountID int64) {
	_ = s.CancelAuto(accountID)
}
