FROM golang:latest
RUN apt update && apt install -y jq iputils-ping
RUN go install github.com/Jigsaw-Code/outline-sdk/x/examples/fetch@latest

WORKDIR /app

ADD https://raw.githubusercontent.com/ed-asriyan/shadowsocks-connectivity-stats/master/1-collecting-data/test.sh test.sh
RUN chmod +x test.sh

ENV SS_CONF_URL=
CMD ./test.sh $SS_CONF_URL
