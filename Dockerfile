FROM docker.io/library/alpine:3.20.3

RUN adduser -D -u "1000" "runner"
RUN mkdir -p "/run/user/1000"
RUN chown "runner:runner" "/run/user/1000"

RUN mkdir -p "/opt/luadns"
COPY "updater/luadns_updater.sh" "/opt/luadns/luadns_updater.sh"
RUN chmod +x "/opt/luadns/luadns_updater.sh"

RUN echo "*/2 * * * * /opt/luadns/luadns_updater.sh" > "/etc/crontabs/runner"

RUN apk add --no-cache ca-certificates curl jq

CMD ["crond", "-f"]