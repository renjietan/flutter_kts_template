package config

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"os"
	"path/filepath"
	"strings"
)

type Config struct {
	DeviceTypes    []string          `json:"deviceTypes"`
	ESN            string            `json:"esn"`
	TxbzName       string            `json:"txbzName"`
	TxbzHash       string            `json:"txbzHash"`
	NodeID         string            `json:"nodeId"`
	DeviceIDs      map[string]string `json:"deviceIds"`
	SupportedTypes []string          `json:"supportedTypes"`
}

var validTypes = map[string]bool{
	"Server":            true,
	"HF":                true,
	"MultiBandRadio":    true,
	"MultibandHandheld": true,
	"CCU":               true,
	"CCUAudio":          true,
	"IEC":               true,
	"SmallHandheld":     true,
}

func LoadAndEnsure() (*Config, error) {
	dir, err := os.Getwd()
	if err != nil {
		return nil, err
	}
	path := filepath.Join(dir, "cpdc_config.json")
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", path, err)
	}
	var cfg Config
	if err := json.Unmarshal(raw, &cfg); err != nil {
		return nil, fmt.Errorf("parse %s: %w", path, err)
	}
	if err := validate(&cfg); err != nil {
		return nil, err
	}
	if cfg.DeviceIDs == nil {
		cfg.DeviceIDs = map[string]string{}
	}
	for _, t := range cfg.DeviceTypes {
		if _, ok := cfg.DeviceIDs[t]; !ok {
			cfg.DeviceIDs[t] = ""
		}
	}
	if cfg.ESN == "" {
		esn, err := generateESN()
		if err != nil {
			return nil, err
		}
		cfg.ESN = esn
		if err := writeAtomic(path, &cfg); err != nil {
			return nil, fmt.Errorf("persist generated esn: %w", err)
		}
	}
	return &cfg, nil
}

func validate(cfg *Config) error {
	if len(cfg.DeviceTypes) == 0 {
		return errors.New("deviceTypes must not be empty")
	}
	seen := map[string]bool{}
	radioCount := 0
	hasServer := false
	hasIEC := false
	for _, t := range cfg.DeviceTypes {
		if !validTypes[t] {
			return fmt.Errorf("invalid deviceType %q", t)
		}
		if seen[t] {
			return fmt.Errorf("duplicate deviceType %q", t)
		}
		seen[t] = true
		switch t {
		case "Server":
			hasServer = true
		case "IEC":
			hasIEC = true
		case "MultiBandRadio", "MultibandHandheld", "HF", "SmallHandheld":
			radioCount++
		}
	}
	if hasServer && hasIEC {
		return errors.New("Server and IEC are mutually exclusive")
	}
	if radioCount > 1 {
		return errors.New("at most one radio device type is allowed")
	}
	if len(cfg.DeviceTypes) == 1 && cfg.DeviceTypes[0] == "CCUAudio" {
		return nil
	}
	for _, t := range cfg.DeviceTypes {
		if t == "CCUAudio" {
			return errors.New("CCUAudio must be configured alone")
		}
	}
	return nil
}

func generateESN() (string, error) {
	var n *big.Int
	for {
		v, err := rand.Int(rand.Reader, new(big.Int).Exp(big.NewInt(10), big.NewInt(39), nil))
		if err != nil {
			return "", err
		}
		if v.Sign() != 0 {
			n = v
			break
		}
	}
	s := n.String()
	if len(s) < 39 {
		s = strings.Repeat("0", 39-len(s)) + s
	}
	return s, nil
}

func writeAtomic(path string, cfg *Config) error {
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

