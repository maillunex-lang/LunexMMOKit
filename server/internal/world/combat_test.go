package world

import (
	"testing"
	"time"
)

func TestAttackDeterministicIgnoresClientDamage(t *testing.T) {
	s := NewSim()
	clock := time.Unix(2000, 0)
	s.Now = func() time.Time { return clock }

	at, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	dummy := s.SpawnDummy("eternity_capital", Vec3{2, 1, 0}, 100)

	r1, err := s.Attack(AttackRequest{
		AttackerID: at.ID, TargetID: dummy.ID, SkillID: "basic", ClientDamage: 9999,
	})
	if err != nil || !r1.OK {
		t.Fatalf("%+v %v", r1, err)
	}
	if r1.Damage != 35 {
		t.Fatalf("damage=%d want 35", r1.Damage)
	}
	if !r1.ClientIgnored {
		t.Fatal("client damage should be flagged ignored")
	}
	if r1.TargetHP != 65 {
		t.Fatalf("hp=%d (client damage applied?)", r1.TargetHP)
	}

	// Same skill again after CD — advance clock
	clock = clock.Add(400 * time.Millisecond)
	r2, err := s.Attack(AttackRequest{
		AttackerID: at.ID, TargetID: dummy.ID, SkillID: "basic", ClientDamage: 1,
	})
	if err != nil || !r2.OK {
		t.Fatalf("%+v %v", r2, err)
	}
	if r2.TargetHP != 30 {
		t.Fatalf("hp=%d", r2.TargetHP)
	}
}

func TestAttackCooldownAndDeath(t *testing.T) {
	s := NewSim()
	clock := time.Unix(3000, 0)
	s.Now = func() time.Time { return clock }
	at, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	dummy := s.SpawnDummy("eternity_capital", Vec3{1, 1, 0}, 40)

	r, _ := s.Attack(AttackRequest{AttackerID: at.ID, TargetID: dummy.ID, SkillID: "basic"})
	if !r.OK || r.TargetHP != 5 {
		t.Fatalf("%+v", r)
	}
	// Immediate second hit → cooldown
	r2, err := s.Attack(AttackRequest{AttackerID: at.ID, TargetID: dummy.ID, SkillID: "basic"})
	if err != ErrOnCooldown || r2.OK {
		t.Fatalf("expected cooldown got %+v %v", r2, err)
	}
	clock = clock.Add(400 * time.Millisecond)
	r3, _ := s.Attack(AttackRequest{AttackerID: at.ID, TargetID: dummy.ID, SkillID: "basic"})
	if !r3.OK || r3.TargetAlive || r3.TargetHP != 0 {
		t.Fatalf("expected death %+v", r3)
	}
}

func TestAttackOutOfRange(t *testing.T) {
	s := NewSim()
	at, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	dummy := s.SpawnDummy("eternity_capital", Vec3{20, 1, 0}, 80)
	r, err := s.Attack(AttackRequest{AttackerID: at.ID, TargetID: dummy.ID, SkillID: "basic"})
	if err != ErrOutOfRange || r.OK {
		t.Fatalf("%+v %v", r, err)
	}
}

func TestAttackMPCost(t *testing.T) {
	s := NewSim()
	clock := time.Unix(4000, 0)
	s.Now = func() time.Time { return clock }
	at, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	// Drain MP via skill2 thrice
	dummy := s.SpawnDummy("eternity_capital", Vec3{2, 1, 0}, 500)
	for i := 0; i < 2; i++ {
		r, err := s.Attack(AttackRequest{AttackerID: at.ID, TargetID: dummy.ID, SkillID: "skill2"})
		if err != nil || !r.OK {
			t.Fatalf("i=%d %+v %v", i, r, err)
		}
		clock = clock.Add(11 * time.Second)
	}
	// MP was 100, skill2 costs 40 → after 2 casts MP=20; third fails
	r, err := s.Attack(AttackRequest{AttackerID: at.ID, TargetID: dummy.ID, SkillID: "skill2"})
	if err != ErrNoMP || r.OK {
		t.Fatalf("%+v %v", r, err)
	}
}
