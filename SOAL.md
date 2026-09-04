# CTF Recon - corplab.local

Target: **PT Nusantara Data Kreasi** (`corplab.local`), lab lokal.

Ada **10 flag** tersebar di 3 fase recon. Semua berformat:

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

**Hint:** `curl` atau View Page Source ke halaman utama, cari komentar HTML.

`FLAG-PASSIVE-1: NUSA{____________________}`

### Flag 2
Ada satu file "standar" yang biasa dipasang situs untuk memberi tahu
peneliti keamanan ke mana harus melapor kalau menemukan masalah. File
ini punya lokasi baku yang sama di hampir semua situs, dan formatnya
memperbolehkan baris komentar bebas.

**Hint:** `/.well-known/security.txt`.

`FLAG-PASSIVE-2: NUSA{____________________}`

---

## Fase 2 - Active Recon (nmap, dirsearch/fuzzing, protokol lain)

### Flag 3
Tim ops sempat menyinggung ada satu layanan internal yang "seharusnya
cuma bisa diakses lewat VPN kantor, tapi kelupaan waktu deploy sehingga
ke-expose ke publik". Layanan ini tidak muncul di navigasi situs mana
pun - satu-satunya cara menemukannya adalah memeriksa semua pintu masuk
yang benar-benar dimiliki server ini, bukan cuma yang "kelihatan".

**Hint:** `nmap -p-` (scan semua 65535 port, jangan cuma default).

`FLAG-ACTIVE-NMAP: NUSA{____________________}`

### Flag 4 (paling berbobot - butuh dua langkah berurutan)
Ada folder tersembunyi yang sering ketinggalan ter-deploy ke production
kalau developer tidak hati-hati - isinya bukan konten situs, tapi
"riwayat kerja" dari situs itu sendiri. Kalau folder itu benar-benar
ke-expose, kamu tidak cuma bisa lihat kondisi situs sekarang, tapi juga
SEMUA versi sebelumnya - termasuk sesuatu yang pernah ada, lalu buru-buru
"dihapus" oleh developernya. Pertanyaannya: dihapus dari mana, dan
apakah itu benar-benar hilang?

**Hint:** fuzzing ke `/.git/`, dump dengan tool semacam git-dumper,
lalu `git log --all` + `git show <hash>:<path>`.

`FLAG-ACTIVE-GIT: NUSA{____________________}`

### Flag 5
Selain situs web, perusahaan ini rupanya masih menjalankan satu jalur
transfer file lama peninggalan sebelum migrasi ke cloud storage - katanya
sih "cuma dipakai buat share dokumen ringan ke rekanan". Coba cek apakah
jalur itu bisa diakses tanpa kredensial apa pun.

**Hint:** `ftp` atau `curl ftp://` dengan user `anonymous`.

`FLAG-ACTIVE-FTP: NUSA{____________________}`

### Flag 6
Bukan semua halaman situs ini ditautkan dari navigasi. Ada satu path
yang terasa seperti "pintu belakang" - namanya sengaja tidak lazim biar
tidak gampang ditebak manusia, tapi kalau kamu coba banyak kemungkinan
nama sekaligus (bukan satu-satu manual), cepat atau lambat bakal kena.

**Hint:** dirsearch/gobuster/ffuf dengan wordlist umum ke situs utama.

`FLAG-ACTIVE-FUZZ: NUSA{____________________}`

### Flag 7
Situs ini juga punya arsip cadangan yang bisa diunduh siapa saja kalau
tahu nama filenya. Setelah diunduh, buka isinya - bukan cuma nama
filenya yang perlu diperhatikan, tapi juga apa yang tertulis di dalam.

**Hint:** unduh file zip yang ditemukan, `unzip`, baca isi filenya.

`FLAG-ACTIVE-ZIP: NUSA{____________________}`

### Flag 8
Ada satu file di situs (`changelog.txt`) yang menyebut sebuah endpoint
API dipakai untuk "health check monitoring" dan seharusnya "jangan
expose publik". Coba akses endpoint itu langsung dan perhatikan
respons JSON-nya baik-baik - bukan cuma field `status`.

**Hint:** baca `/changelog.txt` untuk nama endpoint-nya, lalu akses
langsung.

`FLAG-ACTIVE-API: NUSA{____________________}`

---

## Fase 3 - Technology Footprint

### Flag 9
Server tidak cuma mengirim HTML yang kamu lihat di browser - ada bagian
respons lain yang jarang diperiksa orang kalau cuma buka halamannya
biasa. Coba lihat apa saja yang sebenarnya dikirim server bersamaan
dengan halaman utama.

**Hint:** `curl -I` (atau DevTools tab Network > Headers) ke halaman
utama.

`FLAG-TECH-HEADER: NUSA{____________________}`

### Flag 10
Wappalyzer (atau tool sejenis) akan bilang situs ini pakai sebuah
library JavaScript versi lama. Tools itu cuma mendeteksi DARI MANA
library-nya berasal - dia tidak menyuruhmu benar-benar membaca isi
filenya. Coba buka file library itu sendiri.

**Hint:** `curl` langsung ke file `.js` yang terdeteksi (lihat src-nya
di HTML), baca isinya.

`FLAG-TECH-JSLIB: NUSA{____________________}`

---

## Ronde Bonus (opsional, tanpa flag)

Tidak semua temuan berupa flag - beberapa cuma perlu diobservasi:

- Sebutkan semua port terbuka yang kamu temukan (di luar yang sudah
  dipakai untuk Flag 3).
- Sebutkan versi library JS/CSS lain (selain Flag 10) yang terdeteksi
  Wappalyzer di situs utama.
- Bandingkan header `X-Powered-By` di situs utama dengan subdomain-
  subdomain lain yang kamu temukan lewat sertifikat TLS. Ada berapa
  versi berbeda yang kamu temukan, dan apa artinya?
- Dari nama-nama staf yang kamu kumpulkan di fase passive recon, mana
  yang menurutmu paling berguna untuk skenario social engineering?

---

## Rekap Jawaban

| #  | Flag | Fase             | Ditemukan lewat |
|----|------|------------------|------------------|
| 1  |      | Passive          |                  |
| 2  |      | Passive          |                  |
| 3  |      | Active (nmap)    |                  |
| 4  |      | Active (git)     |                  |
| 5  |      | Active (FTP)     |                  |
| 6  |      | Active (fuzzing) |                  |
| 7  |      | Active (zip)     |                  |
| 8  |      | Active (API)     |                  |
| 9  |      | Tech footprint   |                  |
| 10 |      | Tech footprint   |                  |

Pindahkan tabel ini ke `LAPORAN_TEMPLATE.md` sebagai bukti pengerjaan,
lengkap dengan command yang dipakai untuk tiap flag.
