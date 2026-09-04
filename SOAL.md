# CTF Recon - corplab.local

Target: **PT Nusantara Data Kreasi** (`corplab.local`), lab lokal.

Ada **7 flag** tersebar di 4 fase recon. Semua berformat:

```
NUSA{...}
```

Tiap flag hanya bisa ditemukan dengan teknik yang benar untuk fase itu -
tidak ada yang bisa ditebak tanpa benar-benar melakukan tekniknya. Isi
kolom jawaban di bawah, lalu rekap semuanya + metodologi singkat di
`LAPORAN_TEMPLATE.md`.

Tidak semua yang kamu temukan selama recon adalah flag - beberapa hal
memang cuma "temuan biasa" yang tetap layak dicatat di laporan meski
tidak menghasilkan flag (misal: port yang terbuka tapi kosongan, nama
staf, versi software). Itu bagian dari latihan: belajar bedakan mana
yang signifikan.

---

## Fase 1 - Passive Recon

### Flag 1
**Teknik:** baca isi halaman tanpa scanning/fuzzing apa pun - cukup
`curl`/view-source situs utama.
**Petunjuk:** ada komentar HTML yang biasanya luput dibaca orang.

`FLAG-PASSIVE: NUSA{____________________}`

---

## Fase 2 - Active Recon (nmap, dirsearch/fuzzing, protokol lain)

### Flag 2
**Teknik:** port scan menyeluruh (`nmap -Pn -sV -p-`).
**Petunjuk:** ada satu port yang tidak ditautkan dari situs utama
maupun DNS. Cuma port scan yang bisa menemukannya.

`FLAG-ACTIVE-NMAP: NUSA{____________________}`

### Flag 3 (paling berbobot - 2 langkah)
**Teknik:** temukan direktori `.git` yang ter-expose (fuzzing/dirsearch),
lalu dump seluruh repository-nya (mis. `git-dumper`/`GitTools`/manual
lewat `curl` per object) dan periksa history commit-nya. Flag ada di
sebuah file yang **sudah dihapus** di commit terbaru, tapi masih ada di
versi commit sebelumnya.
**Petunjuk:** `git log --all`, cari commit yang menghapus sesuatu, lalu
`git show <hash>:<path>`.

`FLAG-ACTIVE-GIT: NUSA{____________________}`

### Flag 4
**Teknik:** login FTP secara anonymous, baca file-file yang tersedia.

`FLAG-ACTIVE-FTP: NUSA{____________________}`

---

## Fase 3 - DNS Enumeration

### Flag 5
**Teknik:** zone transfer (`dig axfr corplab.local @<dns-ip> -p <port>`).
Ada record TXT yang cuma muncul lewat AXFR, tidak lewat query biasa.

`FLAG-DNS-AXFR: NUSA{____________________}`

### Flag 6
**Teknik:** dari hasil enumerasi subdomain (zone transfer atau SAN
sertifikat TLS), pasang salah satu subdomain internal ke `/etc/hosts`
lalu akses lewat browser/curl. Flag ada di salah satu halaman subdomain
yang tidak ditautkan dari mana pun.

`FLAG-DNS-CHAIN: NUSA{____________________}`

---

## Fase 4 - Technology Footprint

### Flag 7
**Teknik:** periksa response header (bukan isi halaman) di salah satu
subdomain yang sudah kamu temukan di Fase 3. Wappalyzer tidak akan
menunjukkan ini langsung - perlu cek header manual (`curl -I` atau tab
Network di browser).

`FLAG-TECH-HEADER: NUSA{____________________}`

---

## Ronde Bonus (opsional, tanpa flag)

Tidak semua temuan berupa flag - beberapa cuma perlu diobservasi:

- Sebutkan port berapa saja yang terbuka menurut hasil nmap-mu (di luar
  yang sudah dipakai untuk Flag 2).
- Sebutkan versi library JS yang terdeteksi Wappalyzer di situs utama -
  apakah tergolong versi lama?
- Bandingkan header `X-Powered-By` antara `corplab.local`,
  `dev.corplab.local`, dan `staging.corplab.local`. Ada berapa versi
  berbeda yang kamu temukan?
- Dari 8 subdomain yang muncul di zone transfer, berapa yang benar-benar
  punya halaman berbeda, dan berapa yang "dead end"?

---

## Rekap Jawaban

| # | Flag | Fase | Ditemukan lewat |
|---|------|------|------------------|
| 1 | | Passive | |
| 2 | | Active (nmap) | |
| 3 | | Active (git) | |
| 4 | | Active (FTP) | |
| 5 | | DNS (AXFR) | |
| 6 | | DNS (chain) | |
| 7 | | Tech footprint | |

Pindahkan tabel ini ke `LAPORAN_TEMPLATE.md` sebagai bukti pengerjaan,
lengkap dengan command yang dipakai untuk tiap flag.
