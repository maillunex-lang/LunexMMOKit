package world

import (
	"errors"
	"time"
)

var (
	ErrNoTarget   = errors.New("no target")
	ErrOutOfRange = errors.New("out of range")
	ErrOnCooldown = errors.New("on cooldown")
	ErrNoMP       = errors.New("not enough mp")
)

// AttackRequest is client intent. ClientDamage is IGNORED (C01).
type AttackRequest struct {
	AttackerID   int64  `json:"attacker_id"`
	TargetID     int64  `json:"target_id"`
	SkillID      string `json:"skill_id"`      // "" or "basic" / "skill0"…
	ClientDamage int    `json:"client_damage"` // cheat bait — never applied
}

// AttackResult is the authoritative combat outcome.
type AttackResult struct {
	OK            bool   `json:"ok"`
	Reason        string `json:"reason,omitempty"`
	Damage        int    `json:"damage"`
	TargetHP      int    `json:"target_hp"`
	TargetMaxHP   int    `json:"target_max_hp"`
	TargetAlive   bool   `json:"target_alive"`
	AttackerMP    int    `json:"attacker_mp"`
	SkillID       string `json:"skill_id"`
	ClientIgnored bool   `json:"client_damage_ignored"`
}

type skillDef struct {
	Damage int
	Range  float64
	CD     time.Duration
	MPCost int
}

func skillOf(id string) skillDef {
	switch id {
	case "skill0":
		return skillDef{Damage: 55, Range: 4.5, CD: 450 * time.Millisecond, MPCost: 10}
	case "skill1":
		return skillDef{Damage: 80, Range: 5.0, CD: 6 * time.Second, MPCost: 25}
	case "skill2":
		return skillDef{Damage: 110, Range: 6.0, CD: 10 * time.Second, MPCost: 40}
	default: // basic
		return skillDef{Damage: 35, Range: 3.2, CD: 350 * time.Millisecond, MPCost: 0}
	}
}

// Attack resolves a hit on the server. ClientDamage is never used for HP.
func (s *Sim) Attack(req AttackRequest) (AttackResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	at, ok := s.ents[req.AttackerID]
	if !ok {
		return AttackResult{OK: false, Reason: "attacker", ClientIgnored: req.ClientDamage != 0}, ErrUnknownEntity
	}
	if !at.Alive {
		return AttackResult{OK: false, Reason: "dead", ClientIgnored: true}, ErrDead
	}
	tg, ok := s.ents[req.TargetID]
	if !ok {
		return AttackResult{OK: false, Reason: "target", ClientIgnored: true}, ErrNoTarget
	}
	if at.Location != tg.Location {
		return AttackResult{OK: false, Reason: "location", ClientIgnored: true}, ErrOutOfRange
	}
	sk := skillOf(req.SkillID)
	now := s.now()
	if now.Before(at.AtkReadyAt) {
		return AttackResult{OK: false, Reason: "cooldown", ClientIgnored: true, AttackerMP: at.MP}, ErrOnCooldown
	}
	if at.MP < sk.MPCost {
		return AttackResult{OK: false, Reason: "mp", ClientIgnored: true, AttackerMP: at.MP}, ErrNoMP
	}
	if at.Pos.Dist(tg.Pos) > sk.Range+0.15 {
		return AttackResult{OK: false, Reason: "range", ClientIgnored: true}, ErrOutOfRange
	}
	// Authoritative damage — never take ClientDamage
	dmg := sk.Damage
	at.MP -= sk.MPCost
	at.AtkReadyAt = now.Add(sk.CD)
	if tg.Alive {
		tg.HP -= dmg
		if tg.HP <= 0 {
			tg.HP = 0
			tg.Alive = false
		}
	}
	sid := req.SkillID
	if sid == "" {
		sid = "basic"
	}
	return AttackResult{
		OK: true, Damage: dmg, TargetHP: tg.HP, TargetMaxHP: tg.MaxHP,
		TargetAlive: tg.Alive, AttackerMP: at.MP, SkillID: sid,
		ClientIgnored: req.ClientDamage != 0,
	}, nil
}

// SpawnDummy places a hostile dummy for combat tests / slice.
func (s *Sim) SpawnDummy(location string, pos Vec3, hp int) *Entity {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.nextID++
	id := s.nextID
	if hp <= 0 {
		hp = 80
	}
	e := &Entity{
		ID: id, AccountID: 0, Name: "Dummy", ClassActorID: "mob",
		Location: location, Pos: pos, HP: hp, MaxHP: hp, MP: 0, MaxMP: 0, Alive: true,
		LastMove: s.now(),
	}
	s.ents[id] = e
	cp := *e
	return &cp
}
