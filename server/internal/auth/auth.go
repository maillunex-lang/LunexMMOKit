package auth

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"golang.org/x/crypto/bcrypt"
)

var (
	ErrInvalidCreds = errors.New("invalid credentials")
	ErrLoginTaken   = errors.New("login taken")
	ErrBadToken     = errors.New("invalid or expired token")
)

type Service struct {
	DB *sql.DB
	// sessions: token -> accountID, expiry (in-memory until redis; OK for scaffold)
	sessions map[string]session
}

type session struct {
	AccountID int64
	Expires   time.Time
}

func New(db *sql.DB) *Service {
	return &Service{DB: db, sessions: map[string]session{}}
}

func (s *Service) Register(ctx context.Context, login, password string) (int64, error) {
	if len(login) < 3 || len(password) < 6 {
		return 0, fmt.Errorf("login/password too short")
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return 0, err
	}
	var id int64
	err = s.DB.QueryRowContext(ctx,
		`INSERT INTO accounts(login, password_hash) VALUES($1,$2) RETURNING id`,
		login, string(hash),
	).Scan(&id)
	if err != nil {
		return 0, ErrLoginTaken
	}
	return id, nil
}

func (s *Service) Login(ctx context.Context, login, password string) (token string, accountID int64, err error) {
	var hash string
	err = s.DB.QueryRowContext(ctx, `SELECT id, password_hash FROM accounts WHERE login=$1`, login).Scan(&accountID, &hash)
	if err != nil {
		return "", 0, ErrInvalidCreds
	}
	if bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) != nil {
		return "", 0, ErrInvalidCreds
	}
	token, err = randomToken()
	if err != nil {
		return "", 0, err
	}
	s.sessions[token] = session{AccountID: accountID, Expires: time.Now().Add(24 * time.Hour)}
	return token, accountID, nil
}

func (s *Service) AccountID(token string) (int64, error) {
	sess, ok := s.sessions[token]
	if !ok || time.Now().After(sess.Expires) {
		return 0, ErrBadToken
	}
	return sess.AccountID, nil
}

func (s *Service) CreateCharacter(ctx context.Context, accountID int64, name, classActorID string) (int64, error) {
	var id int64
	err := s.DB.QueryRowContext(ctx, `
		INSERT INTO characters(account_id, name, class_actor_id)
		VALUES($1,$2,$3) RETURNING id`, accountID, name, classActorID).Scan(&id)
	return id, err
}

func (s *Service) ListCharacters(ctx context.Context, accountID int64) ([]map[string]any, error) {
	rows, err := s.DB.QueryContext(ctx, `
		SELECT id, name, class_actor_id, level, location_id
		FROM characters WHERE account_id=$1 ORDER BY id`, accountID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []map[string]any
	for rows.Next() {
		var id int64
		var name, classID, loc string
		var level int
		if err := rows.Scan(&id, &name, &classID, &level, &loc); err != nil {
			return nil, err
		}
		out = append(out, map[string]any{
			"id": id, "name": name, "class_actor_id": classID, "level": level, "location_id": loc,
		})
	}
	return out, rows.Err()
}

func randomToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
