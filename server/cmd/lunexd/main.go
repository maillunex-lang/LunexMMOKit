package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/maillunex-lang/LunexMMOKit/server/internal/auth"
	"github.com/maillunex-lang/LunexMMOKit/server/internal/db"
	"github.com/maillunex-lang/LunexMMOKit/server/internal/health"
	"github.com/maillunex-lang/LunexMMOKit/server/internal/world"
)

func main() {
	addr := flag.String("addr", envOr("LUNEX_LISTEN", "127.0.0.1:18080"), "listen address")
	flag.Parse()

	if dsn := os.Getenv("LUNEX_DATABASE_URL"); dsn != "" {
		d, err := db.Open(dsn)
		if err != nil {
			log.Fatalf("database: %v", err)
		}
		defer d.Close()
		health.DB = d
		log.Printf("database connected")
		svc := auth.New(d)
		ah := &auth.HTTP{Svc: svc}
		wh := &world.HTTP{Sim: world.NewSim(), Auth: svc}
		mux := http.NewServeMux()
		mux.HandleFunc("/health", health.Handle)
		mux.HandleFunc("/version", version)
		mux.HandleFunc("/v1/register", ah.Register)
		mux.HandleFunc("/v1/login", ah.Login)
		mux.HandleFunc("/v1/logout", ah.Logout)
		mux.HandleFunc("/v1/session", ah.Session)
		mux.HandleFunc("/v1/test/expire", ah.Expire)
		mux.HandleFunc("/v1/characters", ah.Characters)
		wh.Mount(mux)
		serve(*addr, mux)
		return
	}

	log.Printf("LUNEX_DATABASE_URL unset — health without DB (dev); world endpoints need auth+DB")
	mux := http.NewServeMux()
	mux.HandleFunc("/health", health.Handle)
	mux.HandleFunc("/version", version)
	serve(*addr, mux)
}

func version(w http.ResponseWriter, r *http.Request) {
	_ = json.NewEncoder(w).Encode(map[string]any{
		"name":             "lunexd",
		"product":          "Осколки вечности",
		"version":          "0.1.0-dev",
		"phase":            "BETA-001",
		"protocol_version": 1,
	})
}

func serve(addr string, mux http.Handler) {
	srv := &http.Server{Addr: addr, Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	go func() {
		log.Printf("lunexd listening on http://%s", addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = srv.Shutdown(ctx)
	fmt.Println("lunexd stopped")
}

func envOr(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
