FROM nginx:1.25-alpine

RUN apk add --no-cache openssl && \
    mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
      -keyout /etc/nginx/certs/corplab.key \
      -out /etc/nginx/certs/corplab.crt \
      -subj "/C=ID/ST=DKI Jakarta/L=Jakarta/O=PT Nusantara Data Kreasi/CN=corplab.local" \
      -addext "subjectAltName=DNS:corplab.local,DNS:www.corplab.local,DNS:admin.corplab.local,DNS:dev.corplab.local,DNS:staging.corplab.local,DNS:api.corplab.local,DNS:git.corplab.local,DNS:backup.corplab.local,DNS:mail.corplab.local"

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d/ /etc/nginx/conf.d/
COPY html/ /usr/share/nginx/html/
COPY vhosts/ /usr/share/nginx/vhosts/

# Materi lab "exposed .git directory": disimpan sebagai tarball (bukan nested
# git repo) supaya tidak jadi gitlink/submodule kosong saat repo utama di-clone.
COPY git-demo.git.tar.gz /tmp/git-demo.git.tar.gz
RUN tar -xzf /tmp/git-demo.git.tar.gz -C /usr/share/nginx/html/ && \
    rm /tmp/git-demo.git.tar.gz

EXPOSE 80 443 8080
