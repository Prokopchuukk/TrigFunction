FROM alpine:latest AS builder

RUN apk add --no-cache git build-base libstdc++ libc6-compat automake autoconf


WORKDIR /home/optima
COPY . .

RUN autoreconf --install
RUN ./configure
RUN make 

FROM alpine:latest

RUN apk add --no-cache libstdc++ libc6-compat

WORKDIR /home/optima

COPY --from=builder /home/optima/FuncClass .

ENTRYPOINT ["./FuncClass"]

