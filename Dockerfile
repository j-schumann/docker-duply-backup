FROM alpine:3.17

# hardcoded TZ= Europe/Berlin
# py-pip is only for the fix below
RUN apk upgrade --update \
    && apk add -U \
      duply \
      lftp \
      mysql-client \
      pwgen \
      py-pip \
      tzdata \
    && cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

# Fix: "ImportError: No module named fasteners" on Alpine
RUN pip install fasteners

# set these in your compose-file or via parameters:
#ENV GPG_PASSPHRASE=changeme
#ENV BACKUP_TARGET=ftp://user:password@host.tld/path/to/backup

# no need to overwrite this, just mount a volume to this folder
ENV GNUPGHOME=/gpg

# no need to overwrite this, just mount a volume here with the files&folders to backup
ENV BACKUP_SOURCE=/backup
VOLUME /backup

# we don't add VOLUME entries for /etc/duply[/data] & /gpg as this would create the directories
# and we would have no way to check if they were mounted or not. Also the existence of /etc/duply/data
# would cause "duply data create" to fail
# VOLUME /etc/duply
# VOLUME /gpg

# prepare a default crontab, can be customized by mounting a modified file
COPY crontab /var/spool/cron/crontabs/root

# the entrypoint prepares the duply profile & gpg key and afterwards executes the CMD
COPY entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]

# -f = foreground, -l = loglevel
CMD ["/usr/sbin/crond", "-f", "-l", "7"]
