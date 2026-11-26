FROM golang:1.23-alpine AS build
WORKDIR /app
COPY go.mod ./
COPY cmd ./cmd
RUN CGO_ENABLED=0 go build -o /billflow-api ./cmd/api

FROM alpine:3.21
RUN adduser -D -H appuser
USER appuser
COPY --from=build /billflow-api /billflow-api
EXPOSE 8080
ENTRYPOINT ["/billflow-api"]
