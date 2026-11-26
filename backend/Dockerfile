FROM golang:1.26-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY cmd ./cmd
COPY internal ./internal
RUN CGO_ENABLED=0 go build -trimpath -o /billflow-api ./cmd/api

FROM alpine:3.23
RUN apk add --no-cache ca-certificates && adduser -D -H appuser
USER appuser
COPY --from=build /billflow-api /billflow-api
EXPOSE 8080
ENTRYPOINT ["/billflow-api"]
