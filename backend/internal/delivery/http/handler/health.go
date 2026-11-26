package handler

import (
	"context"
	"time"

	"github.com/gofiber/fiber/v2"
)

func Health(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"status": "ok", "service": "billflow-api"})
}

func Readiness(postgresPing, redisPing func(context.Context) error) fiber.Handler {
	return func(c *fiber.Ctx) error {
		ctx, cancel := context.WithTimeout(c.UserContext(), 2*time.Second)
		defer cancel()

		if postgresPing(ctx) != nil || redisPing(ctx) != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{"status": "unavailable"})
		}
		return c.JSON(fiber.Map{"status": "ready"})
	}
}
