package main

import (
    "encoding/json"
    "log"
    "net/http"
    "os"
    "time"
)

func main() {
    port := os.Getenv("API_PORT")
    if port == "" { port = "8080" }

    mux := http.NewServeMux()
    mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        _ = json.NewEncoder(w).Encode(map[string]string{"status": "ok", "service": "billflow-api"})
    })

    server := &http.Server{
        Addr: ":" + port,
        Handler: mux,
        ReadHeaderTimeout: 5 * time.Second,
    }
    log.Printf("BillFlow API listening on :%s", port)
    log.Fatal(server.ListenAndServe())
}
