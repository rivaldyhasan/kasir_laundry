# Send Shoes Care Kasir

Aplikasi kasir untuk usaha laundry sepatu **Send Shoes Care** ("Trusted Care, Every Pair"), dibuat dengan Flutter. Mendukung beberapa cabang dengan dua peran pengguna: **kasir** dan **owner**.

## Fitur

- **Login** dengan peran kasir dan owner (kata sandi disimpan dalam bentuk hash).
- **Order baru**: pilih pelanggan, jenis bahan, paket cuci (Deep Clean / Fast Clean), layanan tambahan, foto kondisi awal sepatu, dan antar-jemput.
- **Status order** berurutan: Diterima, Diproses, Selesai, Diambil, dengan progres pengerjaan di Detail Tiket.
- **Notifikasi WhatsApp** (click-to-chat, tanpa API berbayar) dengan pratinjau pesan sebelum dikirim.
- **Pembayaran** tunai atau QRIS, mendukung uang diterima, kembalian, dan cicilan.
- **Nota digital** yang bisa dibagikan, lengkap dengan syarat dan ketentuan.
- **Pengingat** untuk sepatu selesai yang mendekati batas 30 hari belum diambil.
- **Antar-jemput** dengan pelacakan status jemput dan antar.
- **Pelanggan**: data pelanggan dan status member.
- **Owner**: laporan (ekspor CSV), kelola layanan, cabang, pengguna, dan gambar QRIS.

## Akun demo

| Peran | Username | Kata sandi |
|-------|----------|------------|
| Owner | `owner`  | `owner123` |
| Kasir | `kasir1` | `kasir123` |
| Kasir | `kasir2` | `kasir123` |

Akun ini hanya untuk percobaan. Ganti atau hapus sebelum dipakai di toko sungguhan.

## Menjalankan

Prasyarat: [Flutter](https://docs.flutter.dev/get-started/install) (stable) dan Android SDK bila ingin ke HP.

```bash
flutter pub get
flutter run -d chrome        # lihat tampilan di browser
flutter run -d <id_hp>       # jalankan di HP Android
```

Membuat ikon aplikasi dari logo:

```bash
dart run flutter_launcher_icons
```

Membuat APK untuk dipasang manual:

```bash
flutter build apk --release
```

Berkas hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`.

## Struktur proyek

```
lib/
  data/      penyimpanan data lokal dan data contoh
  models/    model data
  screens/   layar aplikasi (login, beranda, order, pembayaran, nota, dll.)
  utils/     tema, format, helper WhatsApp, widget bersama
assets/images/   logo aplikasi
test/            uji widget
```

## Catatan

- Data disimpan lokal di perangkat (`shared_preferences`), tanpa server.
- Pembayaran QRIS belum diverifikasi otomatis. Kasir memastikan dana masuk secara manual.
