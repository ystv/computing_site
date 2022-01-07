FROM golang:1.17.6-alpine3.15

LABEL site="computing"
LABEL stage="builder"

WORKDIR /src/

COPY go.mod ./
COPY go.sum ./
COPY . ./
RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go generate

COPY *.go ./

RUN apk update && apk add git

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o computing

EXPOSE 7075

CMD ["computing"]