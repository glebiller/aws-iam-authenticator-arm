FROM golang:1.16 AS builder

ENV GO111MODULE=on
ENV GOPATH ""

WORKDIR /workspace
COPY aws-iam-authenticator/go.mod aws-iam-authenticator/go.sum ./
RUN go mod download

# Copy the go source
COPY aws-iam-authenticator/cmd/aws-iam-authenticator/ cmd/aws-iam-authenticator/
COPY aws-iam-authenticator/pkg/ pkg/

# Build the operator
RUN GO111MODULE=on CGO_ENABLED=0 GOOS=linux GOARM=7 GOARCH=arm go build -o aws-iam-authenticator \
    -ldflags="-w -s" ./cmd/aws-iam-authenticator/

FROM alpine:3.7
RUN adduser -D -u 10000 aws-iam-authenticator
RUN apk add --update ca-certificates
COPY --from=builder /workspace/aws-iam-authenticator /
RUN chown aws-iam-authenticator /aws-iam-authenticator
USER aws-iam-authenticator
ENTRYPOINT ["/aws-iam-authenticator"]
