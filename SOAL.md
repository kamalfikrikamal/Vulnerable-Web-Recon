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
Developer situs ini kadang menaruh "catatan pribadi" ke sesama tim
langsung di kode halaman, dan lupa membersihkannya sebelum rilis ke
production. Tanpa menyentuh apa pun secara aktif ke server, coba lihat
apa yang sebenarnya dikirim browser-mu setiap kali membuka halaman utama
- ada bagian yang tidak pernah tampil di layar.

`FLAG-PASSIVE: NUSA{____________________}`

---

## Fase 2 - Active Recon (nmap, dirsearch/fuzzing, protokol lain)

### Flag 2
Tim ops sempat menyinggung ada satu layanan internal yang "seharusnya
cuma bisa diakses lewat VPN kantor, tapi kelupaan waktu deploy sehingga
ke-expose ke publik". Layanan ini tidak muncul di navigasi situs, tidak
juga di catatan DNS mana pun - satu-satunya cara menemukannya adalah
memeriksa semua pintu masuk yang benar-benar dimiliki server ini, bukan
cuma yang "kelihatan".

`FLAG-ACTIVE-NMAP: NUSA{____________________}`

### Flag 3 (paling berbobot - butuh dua langkah berurutan)
Ada folder tersembunyi yang sering ketinggalan ter-deploy ke production
kalau developer tidak hati-hati - isinya bukan konten situs, tapi
"riwayat kerja" dari situs itu sendiri. Kalau folder itu benar-benar
ke-expose, kamu tidak cuma bisa lihat kondisi situs sekarang, tapi juga
SEMUA versi sebelumnya - termasuk sesuatu yang pernah ada, lalu buru-buru
"dihapus" oleh developernya. Pertanyaannya: dihapus dari mana, dan
apakah itu benar-benar hilang?

`FLAG-ACTIVE-GIT: NUSA{____________________}`

### Flag 4
Selain situs web, perusahaan ini rupanya masih menjalankan satu jalur
transfer file lama peninggalan sebelum migrasi ke cloud storage - katanya
sih "cuma dipakai buat share dokumen ringan ke rekanan". Coba cek apakah
jalur itu bisa diakses tanpa kredensial apa pun.

`FLAG-ACTIVE-FTP: NUSA{____________________}`

---

## Fase 3 - DNS Enumeration

### Flag 5
DNS server yang mengelola domain ini konon "belum sempat dirapikan
konfigurasinya". Ada satu teknik enumerasi DNS klasik yang - kalau
server-nya salah konfigurasi - bisa memberikan kamu SELURUH isi zone
sekaligus dalam satu permintaan, bukan ditanya satu-satu. Salah satu
baris di dalamnya bukan record biasa.

`FLAG-DNS-AXFR: NUSA{____________________}`

### Flag 6
Tidak semua nama yang kamu temukan di fase DNS itu "hidup" - beberapa
cuma nama terdaftar tanpa isi. Tapi ada satu yang jelas merupakan
environment staging: tempat rilis berikutnya diuji coba sebelum naik ke
production. Petakan namanya supaya browser/tools kamu tahu ke mana harus
menuju, lalu kunjungi langsung.

`FLAG-DNS-CHAIN: NUSA{____________________}`

---

## Fase 4 - Technology Footprint

### Flag 7
Salah satu environment yang kamu temukan di Fase 3 sedang berjalan
dengan "mode debug" menyala. Developer yang lupa mematikan mode debug
biasanya juga lupa bahwa mode itu suka membocorkan info ekstra - tapi
kali ini bukan di body halaman yang kamu lihat di browser, melainkan di
bagian respons yang jarang diperiksa orang kalau cuma buka halamannya
biasa.

`FLAG-TECH-HEADER: NUSA{____________________}`

---

## Ronde Bonus (opsional, tanpa flag)

Tidak semua temuan berupa flag - beberapa cuma perlu diobservasi:

- Sebutkan semua port terbuka yang kamu temukan (di luar yang sudah
  dipakai untuk Flag 2).
- Sebutkan versi library JS yang terdeteksi Wappalyzer di situs utama -
  apakah tergolong versi lama?
- Bandingkan header `X-Powered-By` di situs utama dengan subdomain-
  subdomain lain yang kamu temukan di Fase 3. Ada berapa versi berbeda
  yang kamu temukan, dan apa artinya?
- Dari semua subdomain yang muncul di hasil enumerasi DNS, berapa yang
  benar-benar punya halaman berbeda, dan berapa yang "dead end"?

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
