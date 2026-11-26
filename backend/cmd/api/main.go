package main

import (
	"context"
	"net"
	"os"
	"os/signal"
	"syscall"
	"time"

	"billflow/backend/internal/config"
	"billflow/backend/internal/delivery/http/router"
	"billflow/backend/internal/infrastructure/cache"
	"billflow/backend/internal/infrastructure/database"

	"github.com/gofiber/fiber/v2"
	"github.com/rs/zerolog"
)

func main() {
	logger := zerolog.New(os.Stderr).With().Timestamp().Logger()
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	if err := run(ctx, logger); err != nil {
		logger.Error().Err(err).Msg("API stopped")
		os.Exit(1)
	}
}

func run(ctx context.Context, logger zerolog.Logger) error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	db, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer db.Close()

	redis, err := cache.Open(cfg.RedisURL)
	if err != nil {
		return err
	}
	defer redis.Close()

	app := router.New(db.Ping, func(ctx context.Context) error {
		return redis.Ping(ctx).Err()
	})

	logger.Info().Str("port", cfg.Port).Msg("BillFlow API starting")
	serverErr := make(chan error, 1)
	started := make(chan struct{})
	app.Hooks().OnListen(func(_ fiber.ListenData) error {
		close(started)
		return nil
	})
	go func() {
		serverErr <- app.Listen(net.JoinHostPort("", cfg.Port))
	}()

	select {
	case err := <-serverErr:
		return err
	case <-ctx.Done():
		select {
		case err := <-serverErr:
			return err
		case <-started:
		}
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		return app.ShutdownWithContext(shutdownCtx)
	}
}
