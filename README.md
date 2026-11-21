# Udayana Market

Aplikasi belanja harian Flutter dengan peran pembeli dan admin. Backend REST
Go menggunakan MySQL untuk penyimpanan dan Redis untuk cache katalog.

## Menjalankan backend

Pastikan MySQL (root tanpa kata sandi secara default) dan Redis aktif, lalu:

Salin `.env.example` menjadi `.env` **hanya jika file `.env` belum ada** di
folder `udayana-backend`, kemudian isi konfigurasi database, Redis, dan S3.
File `.env` lokal diabaikan Git; jangan commit kredensial.

```sh
cd ../udayana-backend
go mod tidy
go run ./cmd/api
```

Backend memerlukan Go 1.25 atau lebih baru.
`golang.org/x/crypto` menggunakan `v0.55.0` untuk memperbaiki advisory pada
versi sebelumnya.
Server membuat database `udayana`, tabel, dan data demo saat pertama dijalankan.
Konfigurasi S3 kompatibel dibaca dari `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `AWS_BUCKET`, `AWS_ENDPOINT`,
dan `AWS_USE_PATH_STYLE_ENDPOINT`. Foto disimpan di bucket, sedangkan aplikasi
mengambilnya melalui endpoint backend.
Buka `http://localhost:8080` untuk halaman status dan pintasan dokumentasi API.

| Peran | Email | Kata sandi |
| --- | --- | --- |
| Pembeli | `buyer@udayana.local` | `buyer123` |
| Admin | `admin@udayana.local` | `admin123` |

Pembeli juga dapat mendaftar langsung dari aplikasi. Ganti `JWT_SECRET` dan
kredensial S3 sebelum penggunaan selain pengembangan lokal.

## Menjalankan Flutter

```sh
flutter pub get
flutter run
```

Alamat default API adalah `http://10.0.2.2:8080/api/v1` untuk Android emulator.
Untuk perangkat iOS atau perangkat fisik, arahkan ke alamat IP host:

```sh
flutter run --dart-define=API_BASE_URL=http://HOST_LAN:8080/api/v1
```

Android mengompilasi kalkulasi total keranjang dari C++ menjadi
`libudayana_core.so` melalui CMake/NDK. iOS memakai implementasi Dart yang
setara. Build Android release mengaktifkan R8 dan resource shrinking.

## Fitur

- Pengunjung: katalog dapat dilihat tanpa login, termasuk detail produk.
- Katalog memakai pencarian dan filter server-side, pagination 20 produk per
  halaman (maksimal 100), serta cache Redis per respons/filter selama 5 menit.
  Cache katalog diperbarui setelah produk berubah atau checkout sukses.
  Endpoint `GET /api/v1/products` menerima `page`, `page_size`, `search`,
  `category`, dan `need_type`; responsnya berisi `items`, `page`, `page_size`,
  `total`, dan `total_pages`. Endpoint admin menggunakan parameter yang sama.
- Pembeli: registrasi, kategori daily need/essentials, pencarian, keranjang,
  beli sekarang, beli lagi, checkout COD, dan riwayat pesanan.
- Checkout mengunci stok di dalam transaksi, mengambil kunci produk dengan
  urutan konsisten, dan mengurangi stok secara kondisional agar pesanan
  bersamaan tidak menjual stok melebihi jumlah tersedia.
- Admin: unggah/ganti foto JPEG, PNG, atau WebP (maks. 10 MB) ke S3 saat
  membuat atau mengedit katalog.
- Admin: CRUD produk, pengelolaan status pesanan dan data pelanggan, serta
  laporan penjualan bulanan/tahunan, kategori terlaris, dan jenis kebutuhan.
- Beranda pembeli dirender dari konfigurasi server-driven di `/api/v1/ui/home`.
- Flutter dipisahkan ke entity, model, mapper, datasource, repository,
  use case, event/state, dan view; backend memisahkan controller, request,
  service, repository, dan domain.
