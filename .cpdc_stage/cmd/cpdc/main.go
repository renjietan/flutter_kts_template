package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"cpdc/internal/config"
	"cpdc/internal/net"
	"cpdc/internal/session"
)

func main() {
	iface := flag.String("interface", "", "optional business interface name")
	flag.Parse()

	cfg, err := config.LoadAndEnsure()
	if err != nil {
		fmt.Fprintf(os.Stderr, "config error: %v\n", err)
		os.Exit(1)
	}

	transport, err := net.NewTransport(*iface)
	if err != nil {
		fmt.Fprintf(os.Stderr, "network error: %v\n", err)
		os.Exit(1)
	}
	defer transport.Close()

	sess := session.New(cfg, transport)

	done := make(chan os.Signal, 1)
	signal.Notify(done, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-done
		log.Println("cpdc: shutting down")
		os.Exit(0)
	}()

	log.Printf("cpdc: listening on %s with devices=%v esn=%s", transport.ListenAddr(), cfg.DeviceTypes, cfg.ESN)
	if err := sess.Run(); err != nil {
		log.Fatalf("cpdc: %v", err)
	}
}
