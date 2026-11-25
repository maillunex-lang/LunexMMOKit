package world

import (
	"testing"
	"time"
)

func TestManualInputCancelsAuto(t *testing.T) {
	s := NewSim()
	hero, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	if err := s.SetAutoBattle(1, true); err != nil {
		t.Fatal(err)
	}
	h, _ := s.EntityByAccount(1)
	if !h.AutoBattle {
		t.Fatal("auto not set")
	}
	// Manual move cancels
	_, _ = s.Move(hero.ID, Vec3{0.2, 1, 0}, 0, 0.1)
	h, _ = s.EntityByAccount(1)
	if h.AutoBattle {
		t.Fatal("manual move should cancel auto")
	}
}

func TestAutoBattleAttacksNearest(t *testing.T) {
	s := NewSim()
	clock := time.Unix(7000, 0)
	s.Now = func() time.Time { return clock }
	hero, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	mob := s.SpawnMonster("eternity_capital", Vec3{2, 1, 0}, Shardling)
	_ = s.SetAutoBattle(1, true)
	hits := s.TickAutoBattle()
	if len(hits) != 1 || !hits[0].OK {
		t.Fatalf("auto hit %+v", hits)
	}
	m, _ := s.EntityByID(mob.ID)
	if m.HP >= m.MaxHP {
		t.Fatal("mob not damaged")
	}
	_ = hero
}

func TestCelestialServerValidated(t *testing.T) {
	s := NewSim()
	clock := time.Unix(8000, 0)
	s.Now = func() time.Time { return clock }
	hero, _ := s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	ok, reason, _ := s.ActivateCelestial(1)
	if ok || reason != "energy" {
		t.Fatalf("expected energy gate got ok=%v reason=%s", ok, reason)
	}
	s.mu.Lock()
	s.ents[hero.ID].CelestialEnergy = 60
	s.mu.Unlock()
	ok, reason, until := s.ActivateCelestial(1)
	if !ok || reason != "" || until.IsZero() {
		t.Fatalf("activate failed ok=%v reason=%s", ok, reason)
	}
	h, _ := s.EntityByAccount(1)
	if !h.Celestial || h.CelestialEnergy != 10 {
		t.Fatalf("%+v", h)
	}
	// Damage bonus while celestial
	mob := s.SpawnMonster("eternity_capital", Vec3{2, 1, 0}, Shardling)
	res, _ := s.Attack(AttackRequest{AttackerID: hero.ID, TargetID: mob.ID, SkillID: "basic"})
	if !res.CelestialBonus || res.Damage != 47 { // 35 * 1.35 = 47.25 → 47
		t.Fatalf("celestial dmg %+v", res)
	}
	// CD blocks re-activate
	s.mu.Lock()
	s.ents[hero.ID].CelestialEnergy = 100
	s.mu.Unlock()
	ok, reason, _ = s.ActivateCelestial(1)
	if ok || reason != "cooldown" {
		t.Fatalf("expected cd got ok=%v reason=%s", ok, reason)
	}
}

func TestCancelAutoAPI(t *testing.T) {
	s := NewSim()
	_, _ = s.Join(1, "Hero", "10001", "eternity_capital", Vec3{0, 1, 0})
	_ = s.SetAutoBattle(1, true)
	s.ManualInput(1)
	h, _ := s.EntityByAccount(1)
	if h.AutoBattle {
		t.Fatal("ManualInput should clear auto")
	}
}
