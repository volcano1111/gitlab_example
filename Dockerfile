FROM alpine:latest
RUN apk update \
    && apk add --no-cache s3cmd postgresql-client gettext findutils tzdata tar
ENV TZ=Europe/Moscow
COPY s3cfg /root/s3cfg-temp
COPY pgbackup.sh /pgbackup.sh