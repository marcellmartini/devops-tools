FROM golang:1.23.0-alpine3.20 AS build

WORKDIR /tmp/go-web

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build 

FROM scratch
COPY --from=build /tmp/go-web/go-web /app/go-web

EXPOSE 8080
CMD ["/app/go-web"]
