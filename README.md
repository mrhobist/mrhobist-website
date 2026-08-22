# MrHobist.Website

`mrhobist.com` icin statik tanitim sitesi. Derleme adimi, bagimlilik ve build araci
**yoktur** — dosyalar oldugu gibi sunulur. JavaScript de yoktur: sayfalar JS kapali bir
tarayicida da eksiksiz okunur. Bu bir tercih degil gerekliliktir — Play Console ve Google
OAuth dogrulamasi gizlilik URL'sini JS calistirmadan okur.

---

## Icerik

```
MrHobist.Website/
├── index.html              Ana sayfa: Hedef · Plan · Gelecek (uygulamalar)
├── hakkinda/index.html     Hakkinda + Gizlilik Politikasi  ← Play Console'a verilecek URL
├── 404.html                Bulunamadi sayfasi (GitHub Pages otomatik kullanir)
├── assets/
│   ├── css/site.css        Tek stylesheet
│   └── img/                Uygulama ekran goruntuleri
├── favicon.svg
├── CNAME                   mrhobist.com  (GitHub Pages ozel alan adi)
├── robots.txt
├── sitemap.xml
├── .nojekyll               Jekyll islemesini kapatir
└── scripts/
    ├── drive-sync.ps1      Google Drive arsivi (rclone)
    ├── gitpush.ps1         Sandbox'ta calisan push yardimcisi
    └── githooks/post-commit
```

Site iki sayfadan olusur. Uygulama basina ayri gizlilik sayfasi **yoktur**; tum
uygulamalarin veri islemesi `hakkinda/` sayfasindaki tek politikada toplanmistir.

---

## Yerel onizleme

`file://` ile acmayin — baglantilar kok goreli (`/assets/...`) oldugu icin calismaz.
Klasorun icinde kucuk bir sunucu baslatin:

```bash
python -m http.server 5500
```

Sonra <http://localhost:5500> adresini acin.

---

## Yayinlama — GitHub Pages

Depo: <https://github.com/mrhobist/mrhobist-website>

### 1. Pages'i acin

GitHub'da depo -> **Settings -> Pages**:

- **Source:** `Deploy from a branch`
- **Branch:** `main` / `/ (root)` -> **Save**

> GitHub Pages ucretsiz planda **yalnizca public depolarda** calisir. Bu depo sadece
> tanitim sitesini icerir; uygulamalarin kaynak kodu burada degildir. Deponun private
> kalmasi gerekiyorsa Cloudflare Pages private depoyu ucretsiz destekler.

### 2. Ozel alan adi

Ayni sayfada **Custom domain** alanina `mrhobist.com` yazip **Save**. (Depodaki `CNAME`
dosyasi zaten bunu iceriyor.)

### 3. Turhost DNS

Alan adi Turhost/Natro'da kayitli. Hosting paketi OLMADAN DNS yonetmek icin iki asamali
bir is var; ikincisi atlanirsa birincisi hicbir sey yapmaz.

**3a. DNS bolgesini duzenle** — Panel -> **Gelismis Domain Yonetimi** -> **Domain DNS
Kayitlari**. DNS hizmeti aktifleştirilince Turhost hazir bir sablon olusturur
(`A -> 185.15.40.85`, `mail`/`www`/`ftp` CNAME'leri, kendine bakan bir `MX`). Sablonu
asagidaki hale getirin:

| Tip | Isim | Deger |
|---|---|---|
| A | `mrhobist.com.` | `185.199.108.153` |
| A | `mrhobist.com.` | `185.199.109.153` |
| A | `mrhobist.com.` | `185.199.110.153` |
| A | `mrhobist.com.` | `185.199.111.153` |
| CNAME | `www.mrhobist.com.` | `mrhobist.github.io` |
| NS | `mrhobist.com.` | `dns1.turhost.com` (dokunma) |
| NS | `mrhobist.com.` | `dns2.turhost.com` (dokunma) |

Silinecekler: `MX mrhobist.com. -> mrhobist.com`, `CNAME mail`, `CNAME ftp`. Bunlar sablonun
varsayilanlaridir; apex artik GitHub'a baktigi icin islevsizdir ve MX postayi GitHub
sunucularina yonlendirmeye calisir.

**3b. Nameserver delegasyonunu degistir** — Panel -> alan adi -> **Isim Sunuculari**.
`ns1/ns2.natrohost.com` yerine `dns1.turhost.com` ve `dns2.turhost.com` yazin. Bolge
icindeki NS kayitlari bunu YAPMAZ; delegasyon kayit (registrar) seviyesinde ayarlanir.

> ### Posta notu
> Alan adinin **hic MX kaydi yok** — `@mrhobist.com` adresli calisan bir posta kutusu
> mevcut degil. Sitede ve gizlilik metninde iletisim adresi `mrhobist@gmail.com`; bu adres
> alan adi DNS'inden bagimsiz oldugu icin bu gecis onu etkilemez.
>
> Ileride `bilgi@mrhobist.com` gibi bir adres isterseniz gercek bir posta sunucusuna bakan
> `MX` kaydini bu bolgeye eklersiniz. Web sitesi GitHub'da, posta baska yerde olabilir;
> ikisi birbirinden bagimsizdir.

### 4. HTTPS

DNS yayildiktan sonra (genelde 10 dk - 2 saat) **Settings -> Pages** sayfasinda
**Enforce HTTPS** kutusunu isaretleyin.

### 5. Guncelleme

```bash
git add -A && git commit -m "mesaj" && git push
```

Pages birkac saniye icinde yeni surumu yayinlar.

---

## Google Drive yedegi

Her commit'ten sonra projenin kaynak arsivi Drive'a yuklenir:
`MrHobist/Website/Proje/Website-<tarih>-<sha>.zip`

Diger MrHobist projelerindeki (Deskify, PrayerTimes) duzenin aynisi: `rclone` + bir
`post-commit` hook'u. Yapilandirma yoksa script sessizce cikar ve commit'i asla bozmaz.

Kurulum (bir kez):

```bash
git config core.hooksPath scripts/githooks
```

Ortam degiskeni (bu makinede zaten `gdrive` remote'u tanimli):

```bash
powershell -c "[Environment]::SetEnvironmentVariable('WEBSITE_DRIVE_REMOTE','gdrive','User')"
```

Elle tetiklemek icin:

```bash
powershell -ExecutionPolicy Bypass -File scripts/drive-sync.ps1
```

---

## Play Console notu

Play Console -> **Uygulama icerigi -> Gizlilik politikasi** alanina su adresi girin:

```
https://mrhobist.com/hakkinda/
```

Ayni URL, Google Drive (`drive.appdata`) kapsami icin yapilacak **OAuth dogrulamasinda**
da istenir.

---

## Yayindan once yapilacaklar

- [ ] Gizlilik metnindeki **"Gelistirici: MrHobist"** ifadesinin Play Console'daki
      gelistirici adiyla **birebir ayni** oldugundan emin olun.
- [ ] Uygulamalar Play'e ciktikca `index.html` icindeki `app-meta` satirlarini guncelleyin
      ve magaza baglantisini ekleyin.
- [ ] Yayina girdikten sonra `sitemap.xml` adresini
      [Google Search Console](https://search.google.com/search-console)'a ekleyin.
