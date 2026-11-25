import '../models/models.dart';
import '../utils/security.dart';

/// Data awal sistem, diambil dari proposal:
/// - Cabang: lima lokasi pada Bab 2.1 (alamat yang belum lengkap dibiarkan apa adanya)
/// - Layanan & harga: Tabel 1
/// - Akun demo: owner / kasir1 / kasir2 (hapus atau ganti sebelum dipakai di toko)
class SeedResult {
  final List<Cabang> cabang;
  final List<Pengguna> pengguna;
  final List<Pelanggan> pelanggan;
  final List<Layanan> layanan;
  final List<Pesanan> pesanan;
  final List<DetailPesanan> detail;
  final List<Pembayaran> pembayaran;
  final List<NotifikasiWa> notifikasi;
  SeedResult(this.cabang, this.pengguna, this.pelanggan, this.layanan,
      this.pesanan, this.detail, this.pembayaran, this.notifikasi);
}

SeedResult buatSeed() {
  final cabang = <Cabang>[
    Cabang(
        id: 1,
        kode: 'PKY',
        nama: 'Pekayon',
        alamat:
            'Jl. Kemandoran No. 42, RT.004/RW.023, Pekayon Jaya, Bekasi Selatan, Kota Bekasi 17148'),
    Cabang(
        id: 2,
        kode: 'CPT',
        nama: 'Cipete',
        alamat:
            'Jl. H. Saidi III No. 4A, RT.10/RW.2, Cipete Selatan, Cilandak, Jakarta Selatan'),
    Cabang(
        id: 3,
        kode: 'KGD',
        nama: 'Kelapa Gading',
        alamat: 'Grand Emerald Apartment, Kelapa Gading, Jakarta Utara'),
    Cabang(
        id: 4,
        kode: 'KMG',
        nama: 'Kemanggisan',
        alamat: 'Palmerah, Jakarta Barat'),
    Cabang(
        id: 5,
        kode: 'CPU',
        nama: 'Cipete Utara',
        alamat: 'Cipete Utara / area Jakarta lainnya (alamat belum dirinci)'),
  ];

  final pengguna = <Pengguna>[
    Pengguna(
        id: 1,
        idCabang: 1,
        nama: 'Pemilik Send Shoes Care',
        username: 'owner',
        passwordHash: hashPassword('owner123'),
        role: Role.owner),
    Pengguna(
        id: 2,
        idCabang: 1,
        nama: 'Kasir Pekayon',
        username: 'kasir1',
        passwordHash: hashPassword('kasir123'),
        role: Role.kasir),
    Pengguna(
        id: 3,
        idCabang: 2,
        nama: 'Kasir Cipete',
        username: 'kasir2',
        passwordHash: hashPassword('kasir123'),
        role: Role.kasir),
  ];

  // Tabel 1: (bahan, harga Deep Clean, harga Fast Clean atau null)
  const bahan = <(String, int, int?)>[
    ('Canvas', 50000, 70000),
    ('Suede', 75000, 100000),
    ('Leather', 70000, 85000),
    ('Mesh Knit', 75000, null),
    ('Hiking Boots', 80000, null),
    ('Flat Shoes', 45000, 55000),
    ('Kids Shoes', 25000, 35000),
    ('Sandals / Slides', 25000, 30000),
  ];
  final layanan = <Layanan>[];
  var idL = 1;
  for (final b in bahan) {
    layanan.add(Layanan(
        id: idL++,
        nama: 'Deep Clean',
        jenis: JenisLayanan.utama,
        tipeBahan: b.$1,
        kecepatan: Kecepatan.deep,
        harga: b.$2));
    if (b.$3 != null) {
      layanan.add(Layanan(
          id: idL++,
          nama: 'Fast Clean',
          jenis: JenisLayanan.utama,
          tipeBahan: b.$1,
          kecepatan: Kecepatan.fast,
          harga: b.$3!));
    }
  }
  layanan.addAll([
    Layanan(
        id: idL++,
        nama: 'Un-yellowing',
        jenis: JenisLayanan.tambahan,
        harga: 100000),
    Layanan(
        id: idL++,
        nama: 'Repaint (mulai dari)',
        jenis: JenisLayanan.tambahan,
        harga: 80000),
    Layanan(
        id: idL++,
        nama: 'Stain Removal (mulai dari)',
        jenis: JenisLayanan.tambahan,
        harga: 35000),
  ]);
  int idDari(String bhn, Kecepatan k) => layanan
      .firstWhere((l) => l.tipeBahan == bhn && l.kecepatan == k)
      .id;

  final pelanggan = <Pelanggan>[
    Pelanggan(id: 1, nama: 'Budi Santoso', noWhatsapp: '081234567801'),
    Pelanggan(
        id: 2,
        nama: 'Siti Rahma',
        noWhatsapp: '081234567802',
        statusMember: true),
    Pelanggan(id: 3, nama: 'Andi Wijaya', noWhatsapp: '081234567803'),
  ];

  final now = DateTime.now();
  final pesanan = <Pesanan>[
    Pesanan(
        id: 1,
        idCabang: 1,
        idPengguna: 2,
        idPelanggan: 1,
        noPesanan: 'SSC-PKY-0001',
        tanggalMasuk: now.subtract(const Duration(days: 1)),
        estimasiSelesai: now.add(const Duration(days: 2)),
        status: StatusPesanan.diproses,
        totalBiaya: 50000,
        statusBayar: StatusBayar.belum,
        riwayat: [
          RiwayatStatus(
              StatusPesanan.diterima, now.subtract(const Duration(days: 1))),
          RiwayatStatus(StatusPesanan.diproses,
              now.subtract(const Duration(hours: 20))),
        ]),
    Pesanan(
        id: 2,
        idCabang: 1,
        idPengguna: 2,
        idPelanggan: 2,
        noPesanan: 'SSC-PKY-0002',
        tanggalMasuk: now.subtract(const Duration(days: 2)),
        estimasiSelesai: now.subtract(const Duration(days: 1)),
        status: StatusPesanan.selesai,
        totalBiaya: 100000,
        statusBayar: StatusBayar.lunas,
        riwayat: [
          RiwayatStatus(
              StatusPesanan.diterima, now.subtract(const Duration(days: 2))),
          RiwayatStatus(StatusPesanan.diproses,
              now.subtract(const Duration(days: 2))),
          RiwayatStatus(StatusPesanan.selesai,
              now.subtract(const Duration(hours: 5))),
        ]),
    Pesanan(
        id: 3,
        idCabang: 2,
        idPengguna: 3,
        idPelanggan: 3,
        noPesanan: 'SSC-CPT-0001',
        tanggalMasuk: now,
        estimasiSelesai: now.add(const Duration(days: 3)),
        status: StatusPesanan.diterima,
        totalBiaya: 70000,
        statusBayar: StatusBayar.belum,
        riwayat: [RiwayatStatus(StatusPesanan.diterima, now)]),
  ];
  final detail = <DetailPesanan>[
    DetailPesanan(
        id: 1,
        idPesanan: 1,
        idLayanan: idDari('Canvas', Kecepatan.deep),
        merekSepatu: 'Converse',
        catatan: 'Noda lumpur di sisi kanan',
        harga: 50000),
    DetailPesanan(
        id: 2,
        idPesanan: 2,
        idLayanan: idDari('Suede', Kecepatan.fast),
        merekSepatu: 'Vans',
        catatan: 'Lem sol agak rapuh',
        harga: 100000),
    DetailPesanan(
        id: 3,
        idPesanan: 3,
        idLayanan: idDari('Leather', Kecepatan.deep),
        merekSepatu: 'Dr. Martens',
        harga: 70000),
  ];
  final pembayaran = <Pembayaran>[
    Pembayaran(
        id: 1,
        idPesanan: 2,
        metode: MetodeBayar.qris,
        jumlah: 100000,
        waktuBayar: now.subtract(const Duration(days: 2))),
  ];
  return SeedResult(cabang, pengguna, pelanggan, layanan, pesanan, detail,
      pembayaran, <NotifikasiWa>[]);
}
