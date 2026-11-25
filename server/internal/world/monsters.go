package world

import (
	"time"
)

// Monster AI states (C02).
const (
	MobIdle   = "idle"
	MobPatrol = "patrol"
	MobAggro  = "aggro"
	MobReturn = "return"
	MobDead   = "dead"
)

// Kind discriminates players vs mobs.
const (
	KindPlayer = "player"
	KindMob    = "mob"
	KindBoss   = "boss"
)

// LootGrant records a one-shot reward for a kill event.
type LootGrant struct {
	ItemID   string `json:"item_id"`
	Qty      int    `json:"qty"`
	Currency int    `json:"currency"`
	XP       int    `json:"xp"`
}

// MonsterDef templates spawn parameters.
type MonsterDef struct {
	Name         string
	StableID     string
	Kind         string // mob|boss
	HP           int
	Damage       int
	AggroRadius  float64
	LeashRadius  float64
	PatrolRadius float64
	RespawnAfter time.Duration
	Loot         LootGrant
	AttackRange  float64
	AttackCD     time.Duration
	Speed        float64
}

var Shardling = MonsterDef{
	Name: "Осколочник", StableID: "mob_shardling", Kind: KindMob,
	HP: 80, Damage: 8, AggroRadius: 8, LeashRadius: 18, PatrolRadius: 4,
	RespawnAfter: 5 * time.Second, AttackRange: 2.2, AttackCD: 800 * time.Millisecond, Speed: 2.5,
	Loot: LootGrant{ItemID: "shard_dust", Qty: 1, Currency: 3, XP: 15},
}

var ShardBoss = MonsterDef{
	Name: "Страж Осколка", StableID: "boss_shard_warden", Kind: KindBoss,
	HP: 400, Damage: 22, AggroRadius: 12, LeashRadius: 30, PatrolRadius: 2,
	RespawnAfter: 30 * time.Second, AttackRange: 3.0, AttackCD: 1 * time.Second, Speed: 3.0,
	Loot: LootGrant{ItemID: "warden_core", Qty: 1, Currency: 50, XP: 120},
}

// MobAI holds server-side monster behaviour (not sent fully to clients).
type MobAI struct {
	Def         MonsterDef
	Home        Vec3
	State       string
	TargetID    int64
	PatrolDir   float64
	RespawnAt   time.Time
	SpawnGen    int64          // increments each respawn — loot key uses this
	LootClaimed map[int64]bool // accountID → claimed for this SpawnGen
	LastLootKey string
}

func (s *Sim) ensureMobFields(e *Entity) {
	if e.Kind == "" {
		if e.AccountID == 0 {
			e.Kind = KindMob
		} else {
			e.Kind = KindPlayer
		}
	}
	if e.AI == nil && (e.Kind == KindMob || e.Kind == KindBoss) {
		e.AI = &MobAI{State: MobIdle, LootClaimed: map[int64]bool{}}
	}
}

// SpawnMonster places a patrolling hostile. Returns entity id.
func (s *Sim) SpawnMonster(location string, home Vec3, def MonsterDef) *Entity {
	s.mu.Lock()
	defer s.mu.Unlock()
	if def.Kind == "" {
		def.Kind = KindMob
	}
	if def.HP <= 0 {
		def.HP = 80
	}
	s.nextID++
	id := s.nextID
	e := &Entity{
		ID: id, AccountID: 0, Name: def.Name, ClassActorID: def.StableID,
		Kind: def.Kind, Location: location, Pos: home, Yaw: 0,
		HP: def.HP, MaxHP: def.HP, Alive: true, LastMove: s.now(),
		AI: &MobAI{
			Def: def, Home: home, State: MobPatrol, PatrolDir: 1,
			SpawnGen: 1, LootClaimed: map[int64]bool{},
		},
	}
	s.ents[id] = e
	cp := *e
	return &cp
}

// Tick advances monster AI by dt seconds (patrol/aggro/leash/respawn).
func (s *Sim) Tick(dt float64) {
	if dt <= 0 {
		dt = 0.05
	}
	if dt > 1 {
		dt = 1
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	now := s.now()
	// Snapshot player positions for aggro scan
	type pl struct {
		id  int64
		pos Vec3
		loc string
	}
	var players []pl
	for _, e := range s.ents {
		if e.Kind == KindPlayer && e.Alive {
			players = append(players, pl{e.ID, e.Pos, e.Location})
		}
	}
	for _, e := range s.ents {
		if e.AI == nil || (e.Kind != KindMob && e.Kind != KindBoss) {
			continue
		}
		ai := e.AI
		if !e.Alive {
			if ai.State != MobDead {
				ai.State = MobDead
				ai.RespawnAt = now.Add(ai.Def.RespawnAfter)
			}
			if !ai.RespawnAt.IsZero() && !now.Before(ai.RespawnAt) {
				e.Alive = true
				e.HP = e.MaxHP
				e.Pos = ai.Home
				ai.State = MobPatrol
				ai.TargetID = 0
				ai.SpawnGen++
				ai.LootClaimed = map[int64]bool{}
				ai.RespawnAt = time.Time{}
			}
			continue
		}
		// Find nearest player in aggro
		var nearest int64
		nearestDist := 1e9
		for _, p := range players {
			if p.loc != e.Location {
				continue
			}
			d := e.Pos.Dist(p.pos)
			if d < nearestDist {
				nearestDist = d
				nearest = p.id
			}
		}
		switch ai.State {
		case MobIdle, MobPatrol:
			if nearest != 0 && nearestDist <= ai.Def.AggroRadius {
				ai.State = MobAggro
				ai.TargetID = nearest
				break
			}
			// Simple patrol along X around home
			r := ai.Def.PatrolRadius
			if r <= 0 {
				r = 3
			}
			speed := ai.Def.Speed
			if speed <= 0 {
				speed = 2
			}
			e.Pos.X += ai.PatrolDir * speed * dt
			if e.Pos.X > ai.Home.X+r {
				e.Pos.X = ai.Home.X + r
				ai.PatrolDir = -1
			} else if e.Pos.X < ai.Home.X-r {
				e.Pos.X = ai.Home.X - r
				ai.PatrolDir = 1
			}
			e.Pos.Z = ai.Home.Z
			ai.State = MobPatrol
		case MobAggro:
			tgt, ok := s.ents[ai.TargetID]
			if !ok || !tgt.Alive || tgt.Location != e.Location {
				ai.State = MobReturn
				ai.TargetID = 0
				break
			}
			if e.Pos.Dist(ai.Home) > ai.Def.LeashRadius {
				ai.State = MobReturn
				ai.TargetID = 0
				break
			}
			// Chase
			dir := tgt.Pos.Sub(e.Pos)
			dist := dir.Len()
			speed := ai.Def.Speed
			if speed <= 0 {
				speed = 2.5
			}
			if dist > ai.Def.AttackRange {
				if dist > 0.001 {
					step := speed * dt
					if step > dist-ai.Def.AttackRange*0.5 {
						step = dist - ai.Def.AttackRange*0.5
					}
					e.Pos.X += dir.X / dist * step
					e.Pos.Z += dir.Z / dist * step
				}
			} else if !now.Before(e.AtkReadyAt) {
				// Mob hits player
				tgt.HP -= ai.Def.Damage
				if tgt.HP <= 0 {
					tgt.HP = 0
					tgt.Alive = false
				}
				cd := ai.Def.AttackCD
				if cd <= 0 {
					cd = time.Second
				}
				e.AtkReadyAt = now.Add(cd)
			}
		case MobReturn:
			dir := ai.Home.Sub(e.Pos)
			dist := dir.Len()
			speed := ai.Def.Speed * 1.4
			step := speed * dt
			if dist <= 0.25 || step >= dist {
				e.Pos = ai.Home
				e.HP = e.MaxHP // heal on leash return
				ai.State = MobPatrol
				break
			}
			e.Pos.X += dir.X / dist * step
			e.Pos.Z += dir.Z / dist * step
		}
	}
}

// grantLootOnce awards kill loot at most once per (account, spawn generation).
func (s *Sim) grantLootOnce(killer *Entity, mob *Entity) *LootGrant {
	if killer == nil || mob == nil || mob.AI == nil {
		return nil
	}
	ai := mob.AI
	if ai.LootClaimed == nil {
		ai.LootClaimed = map[int64]bool{}
	}
	if killer.AccountID == 0 {
		return nil
	}
	if ai.LootClaimed[killer.AccountID] {
		return nil // already rewarded this life
	}
	ai.LootClaimed[killer.AccountID] = true
	loot := ai.Def.Loot
	if loot.Qty == 0 && loot.Currency == 0 && loot.XP == 0 {
		loot = LootGrant{ItemID: "scrap", Qty: 1, Currency: 1, XP: 5}
	}
	ai.LastLootKey = loot.ItemID
	return &loot
}
