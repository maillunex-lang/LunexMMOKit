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

	"github.com/maillunex-lang/LunexMMOKit/server/internal/health"
)

func main() {
	addr := flag.String("addr", "127.0.0.1:18080", "listen address (loopback only by default)")
	flag.Parse()

	mux := http.NewServeMux()
	mux.HandleFunc("/health", health.Handle)
	mux.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{
			"name":    "lunexd",
			"product": "Осколки вечности",
			"version": "0.1.0-dev",
			"phase":   "BETA-001 scaffold",
		})
	})

	srv := &http.Server{
		Addr:              *addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	go func() {
		log.Printf("lunexd listening on http://%s (authoritative scaffold; not production)", *addr)
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
