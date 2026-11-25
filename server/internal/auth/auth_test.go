package auth

import (
	"context"
	"testing"
	"time"

	"golang.org/x/crypto/bcrypt"
)

func TestTokenSession(t *testing.T) {
	s := New(nil)
	tok, err := randomToken()
	if err != nil {
		t.Fatal(err)
	}
	s.sessions[tok] = session{AccountID: 7, Expires: time.Now().Add(time.Minute)}
	id, err := s.AccountID(tok)
	if err != nil || id != 7 {
		t.Fatalf("got %d %v", id, err)
	}
	s.ExpireTokenForTest(tok)
	if _, err := s.AccountID(tok); err != ErrBadToken {
		t.Fatalf("expected ErrBadToken got %v", err)
	}
	tok2, err := randomToken()
	if err != nil {
		t.Fatal(err)
	}
	s.sessions[tok2] = session{AccountID: 8, Expires: time.Now().Add(time.Minute)}
	s.Logout(tok2)
	if _, err := s.AccountID(tok2); err != ErrBadToken {
		t.Fatalf("logout should invalidate, got %v", err)
	}
}

func TestBcryptRoundtrip(t *testing.T) {
	hash, err := bcrypt.GenerateFromPassword([]byte("secret12"), bcrypt.MinCost)
	if err != nil {
		t.Fatal(err)
	}
	if bcrypt.CompareHashAndPassword(hash, []byte("secret12")) != nil {
		t.Fatal("compare")
	}
	_ = context.Background()
}
