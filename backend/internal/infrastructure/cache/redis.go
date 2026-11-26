package cache

import (
	"errors"

	"github.com/redis/go-redis/v9"
)

func Open(url string) (*redis.Client, error) {
	opts, err := redis.ParseURL(url)
	if err != nil {
		return nil, errors.New("invalid REDIS_URL")
	}
	opts.ContextTimeoutEnabled = true
	return redis.NewClient(opts), nil
}
