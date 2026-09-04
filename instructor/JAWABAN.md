# Jawaban & Walkthrough - CTF Recon corplab.local

Pendamping `SOAL.md`. File ini berisi **command persis + flag** untuk
tiap nomor. Jangan bagikan ke peserta sebelum sesi selesai (boleh
dibagikan sesudahnya sebagai bahan belajar "cara yang dimaksud").

Port yang dipakai di bawah ini (`80/443/8090/21/6380/3306/2200`) BUKAN
sesuatu yang harus ditebak - itu cuma default port host dari
`docker-compose.yml` repo ini (beberapa digeser dari port standarnya,
mis. panel internal di 8090 bukan 8080, karena bentrok port di mesin
development). Di skenario nyata, peserta akan tahu port yang benar dari
**hasil nmap mereka sendiri** (Flag 3), bukan dari dokumen ini. Ganti
`<target>` dengan IP/host tempat lab dijalankan, dan sesuaikan tiap port
di bawah kalau instruktur mengubah mapping default di `docker-compose.yml`.

---

## Flag 1 - Passive Recon (HTML comment)

```bash
curl -s http://<target>/ | grep -i FLAG
```

atau buka `http://<target>/` di browser -> View Page Source -> `Ctrl+F`
cari "FLAG".

**Flag:** `NUSA{v13w_s0urc3_m4s1h_p3nt1ng}`

---

## Flag 2 - Passive Recon (security.txt)

```bash
curl -s http://<target>/.well-known/security.txt
```

**Flag:** `NUSA{s3curity_txt_j4r4ng_d1b4ca}`

---

## Flag 3 - Active Recon (nmap - port tersembunyi)

```bash
nmap -Pn -sV -p- <target>
```

Akan muncul port `8090` (host) / `8080` (internal container) yang
menjalankan nginx terpisah dari situs utama. Akses:

```bash
curl -s http://<target>:8090/ | grep -i FLAG
```

**Flag:** `NUSA{p0rt_t3rsembuny1_bukan_r4h4s1a}`

---

## Flag 4 - Active Recon (exposed `.git`)

1. Directory/file fuzzing ke situs utama akan menemukan `/.git/`
   (juga di-hint lewat `/robots.txt`):

   ```bash
   curl -s http://<target>/.git/HEAD
   # ref: refs/heads/main
   ```

2. `git clone` biasa ke URL `.git` itu **akan gagal** (dumb HTTP
   protocol sudah tidak didukung git modern). Pakai tool dump khusus,
   mis. [`git-dumper`](https://github.com/arthaud/git-dumper):

   ```bash
   pip install git-dumper
   git-dumper http://<target>/.git/ ./dumped
   cd dumped
   git log --all --oneline
   ```

   Hasilnya 4 commit, salah satunya menghapus sebuah file:

   ```
   <hash4>  Release v2.3.1 - patch form kontak, tambah health check endpoint
   <hash3>  Hapus file kredensial yang ke-commit tidak sengaja
   <hash2>  WIP: migrasi FTP internal, simpan kredensial sementara (lupa masukin .gitignore)
   <hash1>  Initial release NusaCMS v2.0.0
   ```

3. Lihat isi file itu SEBELUM dihapus (di commit `<hash2>`, parent dari
   commit yang menghapusnya):

   ```bash
   git show <hash2>:config/db_credentials.txt.bak
   ```

**Flag:** ada di baris terakhir file itu ->
`NUSA{h1st0ry_g1t_t1d4k_p3rn4h_lup4}`

*(Alternatif tanpa `git-dumper`: fetch manual tiap object lewat
`curl http://<target>/.git/objects/<2-char>/<38-char-sisanya>` lalu
`zlib`-decompress. Lebih ribet tapi membuktikan prinsip yang sama.)*

---

## Flag 5 - Active Recon (FTP anonymous)

```bash
curl -s ftp://<target>/ --user anonymous:anon
curl -s ftp://<target>/CHANGELOG_internal.txt.bak --user anonymous:anon
```

**Flag:** `NUSA{4n0n_ftp_m4s1h_b0c0r}`

---

## Flag 6 - Active Recon (directory fuzzing)

```bash
dirsearch -u http://<target>/ -e html,txt,json,zip,bak
# atau: gobuster dir -u http://<target>/ -w <wordlist>
# atau: ffuf -u http://<target>/FUZZ -w <wordlist>
```

Akan muncul `/admin-x92/` (juga di-hint lewat `/robots.txt`). Buka dan
lihat komentar di HTML-nya:

```bash
curl -s http://<target>/admin-x92/ | grep -i FLAG
```

**Flag:** `NUSA{fuzz1ng_k3temu_p4th_ters3mbuny1}`

---

## Flag 7 - Active Recon (backup zip)

```bash
curl -s http://<target>/backup/ # autoindex aktif, terlihat nama filenya
curl -sO http://<target>/backup/nusantara-backup-2024.zip
unzip -p nusantara-backup-2024.zip
```

**Flag:** ada di baris terakhir isi file di dalam zip ->
`NUSA{z1p_backup_juga_b0c0r_1nf0}`

---

## Flag 8 - Active Recon (API endpoint)

Petunjuk dari `/changelog.txt` menyebut endpoint health-check:

```bash
curl -s http://<target>/changelog.txt   # cari baris soal /api/v1/status
curl -s http://<target>/api/v1/status
```

**Flag:** ada di field `debug_flag` pada JSON respons ->
`NUSA{4p1_endp01nt_j4r4ng_d1t3bak}`

---

## Flag 9 - Technology Footprint (response header di subdomain)

1. Cek SAN di sertifikat TLS situs utama untuk daftar subdomain:

   ```bash
   echo | openssl s_client -connect <target>:443 -servername corplab.local 2>/dev/null | \
     openssl x509 -noout -text | grep -A2 "Subject Alternative Name"
   ```

2. Pilih subdomain yang namanya terasa seperti environment development,
   petakan ke `/etc/hosts` (atau langsung set Host header):

   ```bash
   echo "<target-ip> dev.corplab.local" | sudo tee -a /etc/hosts
   curl -sI http://dev.corplab.local/
   # atau tanpa ubah /etc/hosts:
   curl -sI -H "Host: dev.corplab.local" http://<target>/
   ```

3. Cari baris `X-Flag:` di response header (bukan body halamannya).

**Flag:** `NUSA{h34d3r_b0c0rk4n_l1ngkung4n}`

---

## Flag 10 - Technology Footprint (isi file library JS)

Wappalyzer akan mendeteksi jQuery versi lama dari nama file
`jquery-1.12.4.min.js`. Buka isi filenya langsung (bukan cuma andalkan
deteksi otomatis):

```bash
curl -s http://<target>/assets/js/jquery-1.12.4.min.js
```

**Flag:** `NUSA{l1brary_l4m4_masih_d1b4ca}`

---

## Rekap Cepat

| #  | Flag |
|----|------|
| 1  | `NUSA{v13w_s0urc3_m4s1h_p3nt1ng}` |
| 2  | `NUSA{s3curity_txt_j4r4ng_d1b4ca}` |
| 3  | `NUSA{p0rt_t3rsembuny1_bukan_r4h4s1a}` |
| 4  | `NUSA{h1st0ry_g1t_t1d4k_p3rn4h_lup4}` |
| 5  | `NUSA{4n0n_ftp_m4s1h_b0c0r}` |
| 6  | `NUSA{fuzz1ng_k3temu_p4th_ters3mbuny1}` |
| 7  | `NUSA{z1p_backup_juga_b0c0r_1nf0}` |
| 8  | `NUSA{4p1_endp01nt_j4r4ng_d1t3bak}` |
| 9  | `NUSA{h34d3r_b0c0rk4n_l1ngkung4n}` |
| 10 | `NUSA{l1brary_l4m4_masih_d1b4ca}` |

Untuk temuan non-flag (port tambahan, tech stack, OSINT staf, dsb) dan
diskusi risiko/rekomendasi lebih lengkap, lihat `instructor/ANSWER_KEY.md`.
