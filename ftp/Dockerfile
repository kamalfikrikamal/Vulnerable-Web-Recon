FROM alpine:3.19

RUN apk add --no-cache vsftpd && \
    adduser -D -H ftp 2>/dev/null || true

COPY vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY data /srv/ftp

RUN mkdir -p /var/run/vsftpd/empty && \
    chown -R root:root /srv/ftp && \
    chmod -R a+rX /srv/ftp && \
    chmod 555 /srv/ftp

EXPOSE 21 21100-21110

CMD ["/usr/sbin/vsftpd", "/etc/vsftpd/vsftpd.conf"]
