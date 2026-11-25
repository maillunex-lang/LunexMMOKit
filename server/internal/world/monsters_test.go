package world

import (
	"testing"
	"time"
)

func TestMonsterKillLootOnceRespawnLeash(t *testing.T) {
	s := NewSim()
	clock := time.Unix(5000, 0)
	s.Now = func() time.Time { return clock }

	hero, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	mob := s.SpawnMonster("eternity_capital", Vec3{2, 1, 0}, Shardling)

	// Kill
	var last AttackResult
	for i := 0; i < 10; i++ {
		clock = clock.Add(400 * time.Millisecond)
		last, _ = s.Attack(AttackRequest{AttackerID: hero.ID, TargetID: mob.ID, SkillID: "basic"})
		if !last.TargetAlive {
			break
		}
	}
	if last.TargetAlive {
		t.Fatal("mob should be dead")
	}
	if last.Loot == nil || last.Loot.ItemID != "shard_dust" {
		t.Fatalf("loot missing: %+v", last.Loot)
	}
	// Second "kill" on corpse / re-attack after death should not re-loot
	clock = clock.Add(400 * time.Millisecond)
	again, _ := s.Attack(AttackRequest{AttackerID: hero.ID, TargetID: mob.ID, SkillID: "basic"})
	if again.Loot != nil {
		t.Fatal("loot must be once per life")
	}

	// Respawn after delay
	clock = clock.Add(6 * time.Second)
	s.Tick(0.1)
	ent, ok := s.EntityByID(mob.ID)
	if !ok || !ent.Alive || ent.HP != ent.MaxHP {
		t.Fatalf("respawn failed %+v ok=%v", ent, ok)
	}

	// Kill again → loot again (new SpawnGen)
	for i := 0; i < 10; i++ {
		clock = clock.Add(400 * time.Millisecond)
		last, _ = s.Attack(AttackRequest{AttackerID: hero.ID, TargetID: mob.ID, SkillID: "basic"})
		if !last.TargetAlive {
			break
		}
	}
	if last.Loot == nil {
		t.Fatal("loot on second life missing")
	}
}

func TestLeashReturn(t *testing.T) {
	s := NewSim()
	clock := time.Unix(6000, 0)
	s.Now = func() time.Time { return clock }

	hero, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{5, 1, 0})
	def := Shardling
	def.AggroRadius = 10
	def.LeashRadius = 8
	def.Speed = 5
	mob := s.SpawnMonster("eternity_capital", Vec3{0, 1, 0}, def)

	// Tick into aggro
	s.Tick(0.1)
	m, _ := s.EntityByID(mob.ID)
	if m.AI == nil || m.AI.State != MobAggro {
		// force: hero close
		s.mu.Lock()
		s.ents[mob.ID].AI.State = MobAggro
		s.ents[mob.ID].AI.TargetID = hero.ID
		s.mu.Unlock()
	}
	// Pull hero far beyond leash and tick — mob should return
	s.mu.Lock()
	s.ents[hero.ID].Pos = Vec3{40, 1, 0}
	s.ents[mob.ID].Pos = Vec3{15, 1, 0} // already outside leash from home
	s.ents[mob.ID].AI.State = MobAggro
	s.ents[mob.ID].AI.TargetID = hero.ID
	s.mu.Unlock()
	s.Tick(0.1)
	m, _ = s.EntityByID(mob.ID)
	if m.AI.State != MobReturn && m.AI.State != MobPatrol {
		t.Fatalf("expected return/patrol got %s", m.AI.State)
	}
	// Complete return — stop once home snapped
	homeReached := false
	for i := 0; i < 40; i++ {
		s.Tick(0.2)
		m, _ = s.EntityByID(mob.ID)
		if m.Pos.Dist(Vec3{0, 1, 0}) <= 0.25 {
			homeReached = true
			break
		}
	}
	if !homeReached {
		m, _ = s.EntityByID(mob.ID)
		t.Fatalf("not home %+v state=%s", m.Pos, m.AI.State)
	}
}

func TestBossSpawn(t *testing.T) {
	s := NewSim()
	b := s.SpawnMonster("shard_ruins", Vec3{0, 1, 0}, ShardBoss)
	if b.Kind != KindBoss || b.MaxHP != 400 {
		t.Fatalf("%+v", b)
	}
}
