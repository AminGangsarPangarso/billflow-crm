package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	Port        string
	DatabaseURL string
	RedisURL    string
}

func Load() (Config, error) {
	cfg := Config{
		Port:        strings.TrimSpace(os.Getenv("API_PORT")),
		DatabaseURL: strings.TrimSpace(os.Getenv("DATABASE_URL")),
		RedisURL:    strings.TrimSpace(os.Getenv("REDIS_URL")),
	}
	if cfg.Port == "" {
		cfg.Port = "8080"
	}
	port, err := strconv.ParseUint(cfg.Port, 10, 16)
	if err != nil || port == 0 {
		return Config{}, fmt.Errorf("API_PORT must be an integer from 1 to 65535")
	}
	if cfg.DatabaseURL == "" {
		return Config{}, fmt.Errorf("DATABASE_URL is required")
	}
	if cfg.RedisURL == "" {
		return Config{}, fmt.Errorf("REDIS_URL is required")
	}
	return cfg, nil
}
