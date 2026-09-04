# Kunci Jawaban - Recon Lab corplab.local (Untuk Instruktur)

Jangan bagikan file ini ke peserta sebelum sesi selesai - simpan
kegembiraan "menemukan sendiri" untuk mereka.

## Kunci Flag (untuk grading cepat SOAL.md)

| # | Flag | Lokasi | Teknik yang wajib dipakai |
|---|------|--------|---------------------------|
| 1 | `NUSA{v13w_s0urc3_m4s1h_p3nt1ng}` | HTML comment di `index.html` | view-source / `curl` situs utama |
| 2 | `NUSA{s3curity_txt_j4r4ng_d1b4ca}` | Comment field di `.well-known/security.txt` | baca file security.txt |
| 3 | `NUSA{p0rt_t3rsembuny1_bukan_r4h4s1a}` | Halaman di port 8080/8090 (`panel-internal`) | port scan (nmap), tidak ada link ke sini dari mana pun |
| 4 | `NUSA{h1st0ry_g1t_t1d4k_p3rn4h_lup4}` | Isi `config/db_credentials.txt.bak` di commit ke-2 (sudah dihapus di commit ke-3) | dump `.git` + `git show <hash>:config/db_credentials.txt.bak` |
| 5 | `NUSA{4n0n_ftp_m4s1h_b0c0r}` | `CHANGELOG_internal.txt.bak` di FTP | FTP anonymous login |
| 6 | `NUSA{fuzz1ng_k3temu_p4th_ters3mbuny1}` | HTML comment di `/admin-x92/` | baca `/robots.txt` (baris `Disallow`) -> akses path yang disebut. **Bukan** wordlist fuzzing murni - `admin-x92` bukan kata umum, tidak ada di wordlist manapun |
| 7 | `NUSA{z1p_backup_juga_b0c0r_1nf0}` | Isi file di dalam `/backup/nusantara-backup-2024.zip` | temukan lewat fuzzing/autoindex, unduh, ekstrak, baca isinya |
| 8 | `NUSA{4p1_endp01nt_j4r4ng_d1t3bak}` | Field `debug_flag` di JSON `/api/v1/status` | baca petunjuk endpoint di `/changelog.txt`, lalu akses endpoint-nya |
| 9 | `NUSA{h34d3r_ngga_cuma_1s1_body}` | Header `X-Flag` di situs utama (`corplab.local`) | inspeksi response header (`curl -I`), bukan cuma isi body halaman |
| 10 | `NUSA{l1brary_l4m4_masih_d1b4ca}` | Comment di `assets/js/jquery-1.12.4.min.js` | Wappalyzer deteksi versi -> buka isi file library-nya langsung |

Kalau nanti flag/isi konten diubah lagi, ingat: mengubah file apa pun di
`web/html/` atau `web/vhosts/` butuh **rebuild image `web`**
(`docker compose up -d --build web`). Untuk isi commit demo git, pakai
`web/build-git-demo.sh` untuk regenerasi ulang (lihat komentar di script
itu). Mengubah `ftp/data/*` butuh rebuild image `ftp`.

## 1. Passive Recon

- `robots.txt` men-disclose path yang seharusnya tersembunyi:
  `/admin-x92/`, `/backup/`, `/panel-internal/`, `/api/internal/`,
  `/.git/`, `/config/` - sebagian ada (jadi konfirmasi), sebagian dead end.
- `humans.txt` membocorkan 3 nama staf + email (`andi.saputra`,
  `rima.wulandari`, `budi.hartono` @corplab.local) dan stack teknologi
  (NusaCMS 2.3.1, Bootstrap 3.3.7, jQuery 1.12.4).
- `changelog.txt` menyebut migrasi FTP dan pesan "jangan commit kredensial
  ke repo lagi" (foreshadowing temuan `.git` exposure), dan juga menyebut
  endpoint `/api/v1/status` (petunjuk untuk Flag 8).
- `.well-known/security.txt` - kontak keamanan, RFC 9116, berisi Flag 2.
- Meta tag `generator` di semua halaman: `NusaCMS 2.3.1`.
- HTML comment di `index.html` menyebut ada masalah di changelog terkait
  kredensial FTP, dan berisi Flag 1.

## 2. Active Recon

### Port scan (nmap -sV -p- terhadap host)

| Port default | Service | Catatan |
|---|---|---|
| 21 | vsftpd, anonymous login aktif | banner custom "Nusantara Data Kreasi internal FTP" |
| 22 | OpenSSH | password auth dimatikan (PASSWORD_ACCESS=false) - hanya untuk banner/version grab |
| 80/443 | nginx | situs utama + semua vhost (Host header) |
| 3306 | MariaDB 10.6 | tidak ada exploitasi yang diharapkan, cukup version fingerprint |
| 6379 | Redis | **tanpa autentikasi** - misconfig klasik, `redis-cli -h <ip> ping` langsung PONG |
| 8080 | nginx (panel internal) | **tidak ditautkan dari situs utama mana pun** - hanya ditemukan lewat port scan. Berisi komentar TODO yang mengonfirmasi ini bukan disengaja (tiket OPS-998), dan Flag 3 |

(Catatan: pada environment instruktur, port host mungkin digeser - lihat
`docker-compose.yml` / README untuk mapping aktual.)

### Directory/file fuzzing (dirsearch/gobuster/ffuf terhadap :80)

Yang seharusnya ditemukan:
- `/admin-x92/` - login panel dummy, berisi Flag 6. **Ditemukan lewat
  `/robots.txt`, bukan wordlist fuzzing** - namanya string buatan yang
  tidak ada di wordlist manapun (SecLists, dirb, raft-*, dll), jadi
  blind fuzzing murni tidak akan berhasil menemukannya secara realistis
- `/backup/nusantara-backup-2024.zip` - autoindex aktif di `/backup/`,
  isi arsipnya berisi Flag 7 (nama file umum, wajar ditemukan lewat
  fuzzing)
- `/api/v1/status` - JSON health-check endpoint, berisi Flag 8 di field
  `debug_flag` (petunjuk endpoint-nya ada di `/changelog.txt`)
- `/.git/` - **exposed git repository**, berisi Flag 4 (lihat detail
  di bawah)
- `/changelog.txt`

### Exposed `.git` (bagian paling berbobot dari active recon)

`web/html/.git` sengaja tidak diblok nginx (lihat komentar di
`web/conf.d/main.conf`). Peserta yang jeli/berpengalaman akan mencoba
`/.git/HEAD`, `/.git/config`, lalu men-dump seluruh repo (mis. dengan
`git-dumper`/`GitTools`/`git clone` manual object-by-object - dumb HTTP
protocol via `git clone` langsung biasanya gagal di git versi baru, jadi
tool khusus seperti git-dumper diperlukan).

Riwayat commit (`git log --all` setelah repo di-dump). Nama file yang
berubah di tiap commit (termasuk `config/db_credentials.txt.bak`)
didapat dari `git show --stat <hash>`, bukan ditebak - lihat
`instructor/JAWABAN.md` untuk command persisnya:

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

   # FLAG-ACTIVE-GIT: NUSA{h1st0ry_g1t_t1d4k_p3rn4h_lup4}
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
`CHANGELOG_internal.txt.bak` (catatan internal ops, berisi Flag 5, dan
menyebutkan daftar subdomain internal yang aktif). Ini bagus untuk
didiskusikan: di dunia nyata, "internal notes" semacam ini kadang malah
mempermudah pentester karena defender curhat soal utang teknis di
tempat yang salah.

### Subdomain via sertifikat TLS (bonus, tidak wajib untuk flag mana pun)

Zona `corplab.local` tidak punya DNS server khusus di lab ini - nama-nama
subdomain (`admin`, `dev`, `staging`, `api`, `git`, `backup`, `mail`)
cuma bisa ditemukan lewat **Subject Alternative Name di sertifikat TLS**
situs utama:

```bash
echo | openssl s_client -connect <ip>:443 -servername corplab.local 2>/dev/null | \
  openssl x509 -noout -text | grep -A2 "Subject Alternative Name"
```

Setelah dipetakan ke `/etc/hosts` (atau set Host header manual), tiap
vhost punya isi berbeda (lihat bagian Technology Footprint) - terutama
`dev.corplab.local` yang menjalankan "mode debug" dengan versi lebih
baru. Ini bagian dari Ronde Bonus di SOAL.md (perbandingan header antar
environment), bukan flag wajib.

## 3. Technology Footprint

- Server: `nginx/1.25.x` (version disclosure aktif, `server_tokens on`)
- Header `X-Flag` di situs utama berisi Flag 9 - murni dari inspeksi
  response header, tidak perlu subdomain apa pun.
- Header custom lain: `X-Powered-By: NusaCMS/2.3.1` (production),
  `NusaCMS/2.4.0-dev` + `X-Debug-Mode: true` (dev.corplab.local),
  `NusaCMS/2.4.0-beta` (staging.corplab.local) - bagian Ronde Bonus
- Cookie custom: `NUSACMS_SESSION`
- Library JS/CSS yang harus terdeteksi Wappalyzer: jQuery 1.12.4 (lama -
  layak dicatat sebagai "outdated", isi filenya berisi Flag 10),
  Bootstrap 3.3.7
- Meta generator: `NusaCMS 2.3.1` (production) vs `NusaCMS 2.4.0-dev` /
  `2.4.0-beta` di subdomain lain - **inkonsistensi versi antar
  environment** adalah temuan yang bagus untuk laporan (indikasi rilis
  berikutnya belum di-deploy ke production, dan staging/dev punya
  attack surface tambahan yang tidak ada di production).

## Ringkasan Temuan yang Layak Masuk Laporan (urutan signifikansi)

1. Redis tanpa autentikasi (port 6379/6380) - akses penuh ke data store.
2. Exposed `.git` directory dengan kredensial (dummy) di history commit.
3. Panel internal ter-expose di port 8080/8090, tidak ditautkan dari mana pun.
4. Dev/staging environment membocorkan versi lebih baru & header debug
   lewat halaman publik.
5. FTP anonymous read-only membocorkan internal notes.
6. Endpoint API health-check (`/api/v1/status`) ter-expose publik padahal
   catatan internal bilang seharusnya tidak.
7. Arsip backup bisa diunduh siapa saja lewat autoindex yang aktif.
8. `.git`/robots.txt/changelog/humans.txt/security.txt sebagai sumber
   OSINT (nama staf, email, stack teknologi, riwayat versi).
9. Version disclosure di header Nginx, MariaDB, OpenSSH (semua by
   default, bukan hardening).
