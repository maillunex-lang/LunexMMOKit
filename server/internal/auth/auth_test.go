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
	s.sessions[tok] = session{AccountID: 7, Expires: time.Now().Add(-time.Minute)}
	if _, err := s.AccountID(tok); err != ErrBadToken {
		t.Fatalf("expected ErrBadToken got %v", err)
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
