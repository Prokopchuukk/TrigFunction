FROM alpine:latest

WORKDIR /home/optima

COPY ./FuncClass .

RUN apk add libstdc++
RUN apk add libc6-compat

ENTRYPOINT ["./FuncClass"]
