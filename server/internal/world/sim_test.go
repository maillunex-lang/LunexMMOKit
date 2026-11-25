package world

import (
	"testing"
	"time"
)

func TestTwoClientsSeeEachOther(t *testing.T) {
	s := NewSim()
	a, err := s.Join(1, "HeroA", "10001", "eternity_capital", Vec3{0, 1, 0})
	if err != nil {
		t.Fatal(err)
	}
	b, err := s.Join(2, "HeroB", "20001", "eternity_capital", Vec3{5, 1, 0})
	if err != nil {
		t.Fatal(err)
	}
	snapA, err := s.Snapshot(a.ID)
	if err != nil {
		t.Fatal(err)
	}
	snapB, err := s.Snapshot(b.ID)
	if err != nil {
		t.Fatal(err)
	}
	if !containsID(snapA, b.ID) {
		t.Fatalf("A snapshot missing B: %+v", snapA)
	}
	if !containsID(snapB, a.ID) {
		t.Fatalf("B snapshot missing A: %+v", snapB)
	}
}

func TestAOIHidesFarEntities(t *testing.T) {
	s := NewSim()
	s.AOIRadius = 20
	a, _ := s.Join(1, "A", "10001", "eternity_capital", Vec3{0, 1, 0})
	b, _ := s.Join(2, "B", "20001", "eternity_capital", Vec3{100, 1, 0})
	snap, _ := s.Snapshot(a.ID)
	if containsID(snap, b.ID) {
		t.Fatal("far entity should be outside AOI")
	}
	if !containsID(snap, a.ID) {
		t.Fatal("self missing")
	}
}

func TestTeleportCheatRejected(t *testing.T) {
	s := NewSim()
	a, _ := s.Join(1, "A", "10001", "eternity_capital", Vec3{0, 1, 0})
	res, err := s.Move(a.ID, Vec3{100, 1, 0}, 0, 0.1)
	if err != nil {
		t.Fatal(err)
	}
	if res.Accepted {
		t.Fatal("teleport should be rejected")
	}
	if res.Reason != "overspeed" {
		t.Fatalf("reason=%s", res.Reason)
	}
	if res.Pos.Dist(Vec3{0, 1, 0}) > 0.01 {
		t.Fatalf("pos moved on reject: %+v", res.Pos)
	}
	// Legal step
	res2, err := s.Move(a.ID, Vec3{0.4, 1, 0}, 0, 0.1)
	if err != nil || !res2.Accepted {
		t.Fatalf("legal move rejected: %+v %v", res2, err)
	}
}

func TestMoveSpeedBoundary(t *testing.T) {
	s := NewSim()
	s.MaxSpeed = 3.0
	s.TickSlack = 1.0
	a, _ := s.Join(1, "A", "10001", "eternity_capital", Vec3{0, 1, 0})
	// 0.35m in 0.1s at 3 m/s = ok
	res, _ := s.Move(a.ID, Vec3{0.3, 1, 0}, 0, 0.1)
	if !res.Accepted {
		t.Fatal(res)
	}
	// 1.0m in 0.1s at 3 m/s = overspeed
	res2, _ := s.Move(a.ID, Vec3{1.5, 1, 0}, 0, 0.1)
	if res2.Accepted {
		t.Fatal("should reject")
	}
}

func TestDifferentLocationsIsolated(t *testing.T) {
	s := NewSim()
	a, _ := s.Join(1, "A", "10001", "eternity_capital", Vec3{0, 1, 0})
	b, _ := s.Join(2, "B", "20001", "ashen_outskirts", Vec3{0, 1, 0})
	snap, _ := s.Snapshot(a.ID)
	if containsID(snap, b.ID) {
		t.Fatal("other location should not appear")
	}
}

func containsID(snap []SnapshotEntity, id int64) bool {
	for _, e := range snap {
		if e.ID == id {
			return true
		}
	}
	return false
}

func TestJoinRefresh(t *testing.T) {
	s := NewSim()
	s.Now = func() time.Time { return time.Unix(1000, 0) }
	a1, _ := s.Join(9, "A", "10001", "eternity_capital", Vec3{1, 1, 1})
	a2, _ := s.Join(9, "A2", "30001", "ashen_outskirts", Vec3{2, 1, 2})
	if a1.ID != a2.ID {
		t.Fatal("same account should keep entity id")
	}
	if a2.Location != "ashen_outskirts" || a2.ClassActorID != "30001" {
		t.Fatalf("%+v", a2)
	}
	if s.Count() != 1 {
		t.Fatalf("count=%d", s.Count())
	}
}
