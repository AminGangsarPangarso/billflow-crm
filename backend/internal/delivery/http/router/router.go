package router

import (
	"context"
	"time"

	"billflow/backend/internal/delivery/http/handler"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func New(postgresPing, redisPing func(context.Context) error) *fiber.App {
	app := fiber.New(fiber.Config{
		ReadTimeout:           5 * time.Second,
		WriteTimeout:          5 * time.Second,
		IdleTimeout:           30 * time.Second,
		DisableStartupMessage: true,
	})
	app.Use(recover.New())
	app.Get("/health", handler.Health)
	app.Get("/ready", handler.Readiness(postgresPing, redisPing))
	return app
}
