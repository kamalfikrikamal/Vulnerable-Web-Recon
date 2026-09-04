# Lembar Soal - Recon Lab corplab.local

Target: **PT Nusantara Data Kreasi** (`corplab.local`), lab lokal.
Jawab tiap poin di bawah dengan bukti (command yang dipakai + hasilnya),
lalu rangkum di `LAPORAN_TEMPLATE.md`.

Beberapa nomor punya jawaban pasti (nama file, port, jumlah, dsb) - itu
sengaja, supaya kamu tahu kapan sudah "dapat" datanya dan bisa lanjut ke
soal berikutnya. Beberapa nomor lain sifatnya analisis/opini - jelaskan
alasannya, bukan cuma jawaban satu kata.

---

## Fase 1 - Passive Recon

Kerjakan tanpa fuzzing/scanning aktif - cukup baca apa yang publik.

1. Sebutkan minimal 2 nama staf beserta emailnya yang tercantum di situs
   (cek halaman "Tentang Kami" dan `/humans.txt`).
2. Menurut meta tag `generator`, CMS/platform apa dan versi berapa yang
   dipakai situs ini?
3. Buka `/robots.txt`. Ada berapa baris `Disallow`? Sebutkan satu path
   yang menurutmu paling mencurigakan untuk dicoba lebih lanjut, dan
   kenapa.
4. `/changelog.txt` menyinggung soal "kredensial" yang "jangan dicommit
   lagi". Menurutmu ini petunjuk awal untuk temuan di fase mana nanti?
5. Buka `/.well-known/security.txt`. Ke alamat mana laporan kerentanan
   seharusnya dikirim, dan kapan masa berlakunya?

## Fase 2 - Active Recon (nmap, dirsearch/fuzzing)

6. Jalankan port scan menyeluruh (`nmap -Pn -sV -p- <target>`). Isi
   tabel: port, service, versi, untuk SEMUA port yang terbuka.
7. Dari semua port itu, port mana yang **paling tidak wajar** ada di
   sebuah company-profile website biasa? Jelaskan alasannya.
8. Lakukan directory/file fuzzing ke situs utama (dirsearch/gobuster/
   ffuf). Sebutkan minimal 5 path yang berhasil ditemukan (status 200
   atau 403, bukan 404).
9. Ada satu folder dengan directory listing (autoindex) aktif. Folder
   apa itu, dan file apa yang ada di dalamnya?
10. Coba akses `/.git/HEAD`. Bisa diakses? Kalau ya, dump seluruh
    repository-nya (mis. dengan `git-dumper` atau tool sejenis).
    Berapa jumlah commit di history-nya?
11. Di antara commit-commit itu, ada satu yang **menambahkan** file
    berisi data yang terlihat sensitif, dan satu commit lain yang
    **menghapusnya** lagi. Temukan:
    a. Nama file yang dihapus
    b. Isi lengkap file tersebut (gunakan `git show <hash>:<path>`)
    c. Hash commit yang menghapusnya
12. Login FTP secara anonymous. Sebutkan nama file yang kamu temukan di
    sana dan ringkas isinya masing-masing satu kalimat.
13. Coba akses Redis tanpa kredensial apa pun (`redis-cli -h <target> -p
    <port> ping`). Berhasil? Apa risikonya kalau ini ditemukan di
    server produksi sungguhan?

## Fase 3 - DNS Enumeration

14. Coba zone transfer (`dig axfr corplab.local @<dns-ip> -p <port>`).
    Berhasil? Sebutkan SEMUA nama subdomain yang muncul di hasilnya.
15. Tambahkan subdomain-subdomain itu ke `/etc/hosts` (arahkan ke IP
    target), lalu akses satu per satu. Mana yang punya konten *berbeda*
    dari situs utama, dan mana yang cuma "dead end" (jatuh ke halaman
    default)?
16. Bandingkan daftar dari soal #14 dengan Subject Alternative Name di
    sertifikat TLS situs utama (`openssl s_client` + `openssl x509`).
    Apakah hasilnya konsisten?
17. Menurutmu, kenapa zone transfer yang berhasil itu jadi temuan yang
    layak dilaporkan? (jelaskan risikonya, bukan cuma "karena bocor")
18. Bonus: cek `dig CH TXT version.bind @<dns-ip> -p <port>`. Versi
    software DNS server-nya apa?

## Fase 4 - Technology Footprint

19. Jalankan Wappalyzer (atau `whatweb`) di situs utama. Library JS/CSS
    apa saja yang terdeteksi beserta versinya?
20. Apakah ada library yang versinya sudah lama/berpotensi usang?
    Sebutkan mana dan versi berapa.
21. Bandingkan header `X-Powered-By` antara situs utama (`corplab.local`),
    `dev.corplab.local`, dan `staging.corplab.local`. Apa perbedaannya,
    dan menurutmu apa artinya bagi tim yang mengelola situs ini?
22. Cookie apa yang di-set oleh server? Apakah namanya memberi petunjuk
    soal teknologi/CMS yang dipakai?
23. Header `Server` menunjukkan software web server apa beserta versinya?
    Apakah versi ini tergolong baru atau sudah cukup lama?

## Sintesis Akhir

24. Dari SEMUA temuan di atas (lintas fase), pilih **5 yang paling
    signifikan** menurut kamu dan urutkan dari yang paling penting.
    Jelaskan kenapa masing-masing masuk 5 besar.
25. Kalau kamu jadi konsultan keamanan untuk PT Nusantara Data Kreasi,
    apa **3 rekomendasi prioritas** yang akan kamu sampaikan ke mereka
    berdasarkan hasil recon ini saja (belum tahap eksploitasi)?

---

Selesai menjawab semua nomor di atas -> pindahkan ringkasannya ke
`LAPORAN_TEMPLATE.md` untuk diserahkan sebagai laporan resmi.
