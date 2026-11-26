package router

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
)

func TestHealthRoutes(t *testing.T) {
	ok := func(context.Context) error { return nil }
	down := func(context.Context) error { return errors.New("dependency unavailable") }
	tests := []struct {
		name, path string
		db, redis  func(context.Context) error
		status     int
		body       map[string]string
	}{
		{"liveness with dependencies down", "/health", down, down, 200, map[string]string{"status": "ok", "service": "billflow-api"}},
		{"ready", "/ready", ok, ok, 200, map[string]string{"status": "ready"}},
		{"postgres down", "/ready", down, ok, 503, map[string]string{"status": "unavailable"}},
		{"redis down", "/ready", ok, down, 503, map[string]string{"status": "unavailable"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			app := New(tt.db, tt.redis)
			res, err := app.Test(httptest.NewRequest(http.MethodGet, tt.path, nil))
			if err != nil {
				t.Fatal(err)
			}
			defer res.Body.Close()
			var body map[string]string
			if err := json.NewDecoder(res.Body).Decode(&body); err != nil {
				t.Fatal(err)
			}
			if res.StatusCode != tt.status || !reflect.DeepEqual(body, tt.body) {
				t.Fatalf("got HTTP %d %v, want HTTP %d %v", res.StatusCode, body, tt.status, tt.body)
			}
		})
	}
}
