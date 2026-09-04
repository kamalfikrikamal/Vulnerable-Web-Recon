# Kunci Jawaban - Recon Lab corplab.local (Untuk Instruktur)

Jangan bagikan file ini ke peserta sebelum sesi selesai - simpan
kegembiraan "menemukan sendiri" untuk mereka.

## 1. Passive Recon

- `robots.txt` men-disclose path yang seharusnya tersembunyi:
  `/admin-x92/`, `/backup/`, `/panel-internal/`, `/api/internal/`,
  `/.git/`, `/config/` - sebagian ada (jadi konfirmasi), sebagian dead end.
- `humans.txt` membocorkan 3 nama staf + email (`andi.saputra`,
  `rima.wulandari`, `budi.hartono` @corplab.local) dan stack teknologi
  (NusaCMS 2.3.1, Bootstrap 3.3.7, jQuery 1.12.4).
- `changelog.txt` menyebut migrasi FTP dan pesan "jangan commit kredensial
  ke repo lagi" - foreshadowing temuan `.git` exposure.
- `.well-known/security.txt` - kontak keamanan, RFC 9116.
- Meta tag `generator` di semua halaman: `NusaCMS 2.3.1`.
- HTML comment di `index.html` menyebut ada masalah di changelog terkait
  kredensial FTP.

## 2. Active Recon

### Port scan (nmap -sV -p- terhadap host)

| Port default | Service | Catatan |
|---|---|---|
| 21 | vsftpd, anonymous login aktif | banner custom "Nusantara Data Kreasi internal FTP" |
| 22 | OpenSSH | password auth dimatikan (PASSWORD_ACCESS=false) - hanya untuk banner/version grab |
| 53 | BIND9 | allow-transfer any (lihat DNS enumeration) |
| 80/443 | nginx | situs utama + semua vhost (Host header) |
| 3306 | MariaDB 10.6 | tidak ada exploitasi yang diharapkan, cukup version fingerprint |
| 6379 | Redis | **tanpa autentikasi** - misconfig klasik, `redis-cli -h <ip> ping` langsung PONG |
| 8080 | nginx (panel internal) | **tidak ditautkan dari situs utama atau DNS mana pun** - hanya ditemukan lewat port scan. Berisi komentar TODO yang mengonfirmasi ini bukan disengaja (tiket OPS-998) |

(Catatan: pada environment instruktur, port host mungkin digeser - lihat
`docker-compose.yml` / README untuk mapping aktual.)

### Directory/file fuzzing (dirsearch/gobuster/ffuf terhadap :80)

Yang seharusnya ditemukan:
- `/admin-x92/` - login panel dummy (juga di-hint lewat robots.txt)
- `/backup/nusantara-backup-2024.zip` - autoindex aktif di `/backup/`
- `/api/v1/status` - JSON health-check endpoint, mengandung catatan
  "jangan expose publik (tiket OPS-1187)"
- `/.git/` - **exposed git repository** (lihat detail di bawah)
- `/changelog.txt`

### Exposed `.git` (bagian paling berbobot dari active recon)

`web/html/.git` sengaja tidak diblok nginx (lihat komentar di
`web/conf.d/main.conf`). Peserta yang jeli/berpengalaman akan mencoba
`/.git/HEAD`, `/.git/config`, lalu men-dump seluruh repo (mis. dengan
`git-dumper`/`GitTools`/`git clone` manual object-by-object - dumb HTTP
protocol via `git clone` langsung biasanya gagal di git versi baru, jadi
tool khusus seperti git-dumper diperlukan).

Riwayat commit (`git log --all` setelah repo di-dump):

1. `Initial release NusaCMS v2.0.0`
2. `WIP: migrasi FTP internal, simpan kredensial sementara (lupa masukin .gitignore)`
   -> menambahkan `config/db_credentials.txt.bak` berisi:
   ```
   DB_HOST=db-internal.corplab.local
   DB_NAME=nusacms_dev
   DB_USER=nusacms_dev_user
   DB_PASS=dev_Tr4in1ng_2024
   FTP_USER=nusacms_ftp
   FTP_PASS=Ftp_L4b_Only_2023
   ```
3. `Hapus file kredensial yang ke-commit tidak sengaja` -> file dihapus
   dari working tree TAPI masih ada di history.
4. `Release v2.3.1 - ...` -> state akhir yang live di web.

Poin pembelajaran: menghapus file dari commit terbaru tidak menghapusnya
dari sejarah repo. Kredensial ini murni dummy, tidak valid untuk service
manapun di lab (disengaja - fokus lab adalah *menemukan*, bukan
*menggunakan*).

### FTP anonymous

`ftp://<ip>/` -> `readme.txt` (catatan umum) dan
`CHANGELOG_internal.txt.bak` (catatan internal ops yang menyebutkan
langsung beberapa misconfig yang jadi bagian lab ini - termasuk daftar
subdomain aktif dan konfirmasi zone transfer DNS belum dibatasi). Ini
bagus untuk didiskusikan: di dunia nyata, "internal notes" semacam ini
kadang malah mempermudah pentester karena defender curhat soal utang
teknis di tempat yang salah.

## 3. DNS Enumeration

`dig axfr corplab.local @<ip> -p <port>` (misconfig `allow-transfer any`
di `dns/named.conf`) mengembalikan seluruh zone sekaligus:

- `www`, `ns1`, `mail` - publik/wajar
- `admin`, `dev`, `staging`, `api`, `git`, `backup` - **tidak ditautkan di
  mana pun di situs utama**, hanya ditemukan lewat AXFR (atau SAN
  sertifikat TLS sebagai jalur alternatif)
- `vpn`, `monitor` - record ada, tapi tidak ada virtual host khusus untuk
  nama ini - request ke sana hanya jatuh ke situs default (dead end yang
  disengaja - poin pembelajaran: DNS record tidak selalu berarti ada
  aplikasi/permukaan serangan berbeda di baliknya)
- TXT record berisi SPF dan catatan internal yang secara eksplisit
  mengonfirmasi ini misconfig yang belum diperbaiki (tiket OPS-1187)

Setelah subdomain ditemukan dan dipetakan ke `/etc/hosts`, tiap vhost
punya isi berbeda (lihat bagian Technology Footprint) - terutama
`dev.corplab.local` yang membocorkan "environment variable" dummy
(DB credentials, API key format `sk_test_...`) di halaman debug statis.

## 4. Technology Footprint

- Server: `nginx/1.25.x` (version disclosure aktif, `server_tokens on`)
- Header custom: `X-Powered-By: NusaCMS/2.3.1` (production),
  `NusaCMS/2.4.0-dev` + `X-Debug-Mode: true` (dev.corplab.local),
  `NusaCMS/2.4.0-beta` (staging.corplab.local)
- Cookie custom: `NUSACMS_SESSION`
- Library JS/CSS yang harus terdeteksi Wappalyzer: jQuery 1.12.4 (lama -
  layak dicatat sebagai "outdated"), Bootstrap 3.3.7
- Meta generator: `NusaCMS 2.3.1` (production) vs `NusaCMS 2.4.0-dev` /
  `2.4.0-beta` di subdomain lain - **inkonsistensi versi antar
  environment** adalah temuan yang bagus untuk laporan (indikasi rilis
  berikutnya belum di-deploy ke production, dan staging/dev punya
  attack surface tambahan yang tidak ada di production).
- BIND version leak: `dig CH TXT version.bind @<ip> -p <port>` (tidak ada
  directive `version` yang menyembunyikannya).

## Ringkasan Temuan yang Layak Masuk Laporan (urutan signifikansi)

1. Redis tanpa autentikasi (port 6379/6380) - akses penuh ke data store.
2. Exposed `.git` directory dengan kredensial (dummy) di history commit.
3. Zone transfer DNS terbuka ke publik (`allow-transfer any`).
4. Panel internal ter-expose di port 8080/8090, tidak ditautkan dari mana pun.
5. Dev/staging environment membocorkan "kredensial" & versi lebih baru
   lewat halaman debug publik.
6. FTP anonymous read-only membocorkan internal notes.
7. `.git`/robots.txt/changelog/humans.txt sebagai sumber OSINT (nama staf,
   email, stack teknologi, riwayat versi).
8. Version disclosure di header Nginx, BIND, MariaDB, OpenSSH (semua by
   default, bukan hardening).
