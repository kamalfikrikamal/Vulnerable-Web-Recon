# Recon Lab - PT Nusantara Data Kreasi (corplab.local)

Lab web vulnerable **khusus untuk latihan reconnaissance** (bukan latihan
eksploitasi). Target adalah "perusahaan" fiktif *PT Nusantara Data Kreasi*
dengan domain fiktif `corplab.local`, dijalankan sebagai beberapa service
Docker sekaligus supaya nmap dan dirsearch/fuzzing menghasilkan temuan
yang nyata (bukan simulasi tulisan).

> Level peserta: intermediate pentester.
> Fokus: **hanya recon** - passive recon, active recon, technology
> footprinting. Beberapa temuan sengaja dibuat menarik untuk dilaporkan
> meskipun tidak semuanya berupa "kerentanan" klasik.

## Peringatan Penggunaan

- Jalankan **hanya di jaringan lokal/terisolasi** (laptop/VM sendiri). Jangan
  expose port-port ini ke internet publik.
- Semua kredensial, API key, dan "data sensitif" di dalam lab ini adalah
  **data dummy** untuk keperluan latihan - tidak terhubung ke sistem nyata
  apa pun.
- Aktivitas seperti port scanning dan directory fuzzing terhadap sistem
  pihak lain di luar lab ini butuh izin eksplisit. Gunakan lab ini sebagai
  tempat berlatih teknik yang sah.

## Arsitektur

| Service | Deskripsi | Port host default |
|---|---|---|
| `web` | Situs utama + beberapa virtual host + panel internal | 80, 443, 8090 |
| `ftp` | FTP anonymous (vsftpd) | 21, 21100-21110 |
| `redis` | Redis tanpa autentikasi | 6380 |
| `db` | MariaDB (hanya untuk deteksi service/versi) | 3306 |
| `ssh` | OpenSSH (hanya banner/version grab, login password dimatikan) | 2200 |

Nama-nama subdomain (`admin`, `dev`, `staging`, `api`, `git`, `backup`,
`mail`) tidak dijawab lewat DNS server khusus - satu-satunya cara
menemukannya adalah lewat **Subject Alternative Name di sertifikat TLS**
situs utama, lalu dipetakan manual ke `/etc/hosts` atau lewat Host header.

Beberapa port host digeser dari port standarnya (22->2200, 6379->6380,
8080->8090) karena bentrok dengan service lain yang sudah berjalan di
mesin ini. Kalau di mesin/VM peserta port-port itu kosong, silakan ubah
balik ke port standar di `docker-compose.yml` supaya hasil scan lebih
"otentik" (mis. port 22, 6379, 8080).

## Menjalankan Lab

```bash
docker compose up -d --build
docker compose ps
```

Semua service akan reachable di `127.0.0.1` (atau IP mesin/VM tempat lab
dijalankan). Untuk mengecek port yang mungkin bentrok sebelum start:

```bash
lsof -iTCP -sTCP:LISTEN -P | grep -E ':21|:22|:80|:443|:3306|:6379|:8080'
```

Reset total (hapus data container):

```bash
docker compose down -v
```

## Panduan 3 Fase Recon

Ini **bukan jawaban** - hanya arah dan contoh perintah. Untuk daftar tugas
konkret (10 flag CTF per fase), pakai **`SOAL.md`**. Detail temuan harus
digali sendiri oleh peserta dan ditulis di `LAPORAN_TEMPLATE.md`.

### 1. Passive Recon

Kumpulkan informasi tanpa "menyerang" target secara aktif - baca saja apa
yang tersedia publik di situs utama:

- Buka `http://127.0.0.1/` dan baca isi halaman, komentar HTML, footer.
- Cek file-file baku: `/robots.txt`, `/sitemap.xml`, `/humans.txt`,
  `/.well-known/security.txt`, `/changelog.txt`.
- Perhatikan response header (`curl -I http://127.0.0.1/`).
- Catat nama staf/email yang muncul di halaman "Tentang Kami" - latihan
  gaya OSINT (siapa yang mungkin jadi target social engineering / password
  spraying di dunia nyata).

### 2. Active Recon (nmap, dirsearch/fuzzing)

- Port scan menyeluruh:
  ```bash
  nmap -Pn -sV -p- 127.0.0.1
  ```
  Perhatikan port mana yang "wajar" untuk sebuah situs company profile, dan
  mana yang terasa tidak seharusnya publik.
- Directory/file fuzzing di situs utama (contoh dengan `dirsearch`,
  `gobuster`, atau `ffuf`), termasuk mencoba nama-nama yang dipetik dari
  `robots.txt`:
  ```bash
  dirsearch -u http://127.0.0.1/ -e html,txt,json,zip,bak
  ```
- Setelah menemukan port "tidak biasa" dari nmap, coba akses langsung lewat
  browser/curl - apakah ada halaman yang seharusnya tidak publik?
- Perhatikan folder yang autoindex-nya aktif, dan file arsip yang bisa
  diunduh lalu diperiksa isinya.
- Cek sertifikat TLS situs utama untuk daftar subdomain lain:
  ```bash
  echo | openssl s_client -connect 127.0.0.1:443 -servername corplab.local 2>/dev/null | openssl x509 -noout -text | grep -A2 "Subject Alternative Name"
  ```
  Petakan salah satu subdomain ke `/etc/hosts` (arahkan ke `127.0.0.1`)
  atau set Host header manual untuk menjelajahinya.

### 3. Technology Footprint

- Pasang ekstensi Wappalyzer di browser dan buka situs utama serta
  masing-masing subdomain yang ditemukan di fase 2.
- Bandingkan dengan analisis manual: response header (`X-Powered-By`,
  `Server`), meta tag `generator`, nama file JS/CSS, nama cookie.
- Perhatikan apakah versi komponen yang sama (misalnya framework internal)
  berbeda antara satu subdomain dengan subdomain lain - itu sering jadi
  petunjuk lingkungan mana yang "lebih baru"/belum dirilis ke production.
- Jangan cuma andalkan deteksi otomatis - buka juga isi file library JS/CSS
  yang terdeteksi, kadang ada info tambahan di dalamnya.

## Struktur Proyek

```
docker-compose.yml
web/            # nginx: situs utama, vhost, panel internal, sertifikat TLS
ftp/            # vsftpd anonymous
SOAL.md               # 10 flag CTF per fase - mulai dari sini
LAPORAN_TEMPLATE.md   # template laporan untuk peserta
instructor/ANSWER_KEY.md   # konteks & temuan lengkap (untuk instruktur)
instructor/JAWABAN.md      # walkthrough command per flag (untuk instruktur)
```
