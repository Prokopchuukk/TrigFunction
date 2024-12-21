FROM alpine
WORKDIR /home/optima
COPY ./FuncClass .

RUN apk add libstadc++
RUN apk add libc6-compat



ENTRYPOINT ["./FuncClass"]
