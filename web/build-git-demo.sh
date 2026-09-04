#!/bin/bash
# Regenerasi web/git-demo.git.tar.gz - materi lab "exposed .git directory".
#
# Kenapa tidak disimpan sebagai nested git repo langsung di web/html/.git?
# Karena repo utama pernah meng-commit web/html sebagai gitlink kosong waktu
# .git itu ada di sana secara langsung (lihat commit "Fix: web/html
# ter-commit sebagai gitlink kosong"). Supaya tidak kejadian lagi, materi ini
# dibangun terpisah lalu dikemas jadi tarball yang diekstrak saat docker
# build (lihat web/Dockerfile).
#
# Pakai skrip ini kalau mau ubah isi/flag di dalam demo repo ini. Jalankan
# dari root proyek: ./web/build-git-demo.sh

set -euo pipefail
cd "$(dirname "$0")/html"

if [ -d .git ]; then
  echo "web/html/.git sudah ada - hapus dulu manual kalau mau regenerasi total." >&2
  exit 1
fi

git -c user.name="Andi Saputra" -c user.email="andi.saputra@corplab.local" init -q -b main

git -c user.name="Andi Saputra" -c user.email="andi.saputra@corplab.local" add index.html tentang.html kontak.html robots.txt sitemap.xml humans.txt .well-known assets
GIT_AUTHOR_DATE="2023-05-10T10:00:00" GIT_COMMITTER_DATE="2023-05-10T10:00:00" \
git -c user.name="Andi Saputra" -c user.email="andi.saputra@corplab.local" commit -q -m "Initial release NusaCMS v2.0.0"

mkdir -p config
cat > config/db_credentials.txt.bak <<'EOF'
# TEMP - konfigurasi lokal dev, JANGAN commit ke repo!
DB_HOST=db-internal.corplab.local
DB_NAME=nusacms_dev
DB_USER=nusacms_dev_user
DB_PASS=dev_Tr4in1ng_2024
FTP_USER=nusacms_ftp
FTP_PASS=Ftp_L4b_Only_2023

# FLAG-ACTIVE-GIT: NUSA{h1st0ry_g1t_t1d4k_p3rn4h_lup4}
EOF
git -c user.name="Rima Wulandari" -c user.email="rima.wulandari@corplab.local" add config/db_credentials.txt.bak
GIT_AUTHOR_DATE="2023-08-20T14:32:00" GIT_COMMITTER_DATE="2023-08-20T14:32:00" \
git -c user.name="Rima Wulandari" -c user.email="rima.wulandari@corplab.local" commit -q -m "WIP: migrasi FTP internal, simpan kredensial sementara (lupa masukin .gitignore)"

git -c user.name="Rima Wulandari" -c user.email="rima.wulandari@corplab.local" rm -q config/db_credentials.txt.bak
rmdir config 2>/dev/null || true
GIT_AUTHOR_DATE="2023-08-21T09:05:00" GIT_COMMITTER_DATE="2023-08-21T09:05:00" \
git -c user.name="Rima Wulandari" -c user.email="rima.wulandari@corplab.local" commit -q -m "Hapus file kredensial yang ke-commit tidak sengaja"

git -c user.name="Andi Saputra" -c user.email="andi.saputra@corplab.local" add changelog.txt admin-x92 backup panel-internal api
GIT_AUTHOR_DATE="2024-03-01T11:00:00" GIT_COMMITTER_DATE="2024-03-01T11:00:00" \
git -c user.name="Andi Saputra" -c user.email="andi.saputra@corplab.local" commit -q -m "Release v2.3.1 - patch form kontak, tambah health check endpoint"

cd ..
tar czf git-demo.git.tar.gz -C html .git
rm -rf html/.git

echo "Selesai: web/git-demo.git.tar.gz dibuat ulang, web/html/.git dibersihkan."
echo "Jangan lupa: docker compose up -d --build web"
