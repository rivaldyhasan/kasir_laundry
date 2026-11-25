// Model data sesuai Lampiran C (Kamus Data) proposal MPPL Send Shoes Care.
// Tambahan di luar kamus data: Cabang.kode (untuk nomor pesanan) dan
// Pesanan.riwayat (riwayat status, sesuai Tabel 2 butir "Komplain 1x24 jam").

enum Role { owner, kasir }

enum StatusPesanan { diterima, diproses, selesai, diambil }

enum StatusBayar { belum, lunas }

enum Kecepatan { deep, fast }

enum JenisLayanan { utama, tambahan }

enum MetodeBayar { tunai, qris }

enum JenisPesan { diterima, selesai }

enum StatusAntarJemput { menungguJemput, dijemput, diantar }

extension RoleX on Role {
  String get label => this == Role.owner ? 'Owner' : 'Kasir';
}

extension StatusPesananX on StatusPesanan {
  String get label => switch (this) {
        StatusPesanan.diterima => 'Diterima',
        StatusPesanan.diproses => 'Diproses',
        StatusPesanan.selesai => 'Selesai',
        StatusPesanan.diambil => 'Diambil',
      };
}

extension KecepatanX on Kecepatan {
  String get label => this == Kecepatan.deep ? 'Deep Clean' : 'Fast Clean';
  String get durasi => this == Kecepatan.deep ? '2–3 hari' : '3 jam–1 hari';
}

extension MetodeBayarX on MetodeBayar {
  String get label => this == MetodeBayar.tunai ? 'Tunai' : 'QRIS';
}

extension StatusAntarJemputX on StatusAntarJemput {
  String get label => switch (this) {
        StatusAntarJemput.menungguJemput => 'Menunggu jemput',
        StatusAntarJemput.dijemput => 'Dijemput',
        StatusAntarJemput.diantar => 'Diantar',
      };
}

DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

class Cabang {
  int id;
  String kode;
  String nama;
  String alamat;
  String noWhatsapp;
  Cabang({
    required this.id,
    required this.kode,
    required this.nama,
    this.alamat = '',
    this.noWhatsapp = '',
  });
  factory Cabang.fromJson(Map<String, dynamic> j) => Cabang(
        id: j['id'],
        kode: j['kode'],
        nama: j['nama'],
        alamat: j['alamat'] ?? '',
        noWhatsapp: j['noWhatsapp'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'kode': kode,
        'nama': nama,
        'alamat': alamat,
        'noWhatsapp': noWhatsapp,
      };
}

class Pengguna {
  int id;
  int idCabang;
  String nama;
  String username;
  String passwordHash;
  Role role;
  Pengguna({
    required this.id,
    required this.idCabang,
    required this.nama,
    required this.username,
    required this.passwordHash,
    required this.role,
  });
  factory Pengguna.fromJson(Map<String, dynamic> j) => Pengguna(
        id: j['id'],
        idCabang: j['idCabang'],
        nama: j['nama'],
        username: j['username'],
        passwordHash: j['passwordHash'],
        role: Role.values.byName(j['role']),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'idCabang': idCabang,
        'nama': nama,
        'username': username,
        'passwordHash': passwordHash,
        'role': role.name,
      };
}

class Pelanggan {
  int id;
  String nama;
  String noWhatsapp;
  bool statusMember;
  Pelanggan({
    required this.id,
    required this.nama,
    required this.noWhatsapp,
    this.statusMember = false,
  });
  factory Pelanggan.fromJson(Map<String, dynamic> j) => Pelanggan(
        id: j['id'],
        nama: j['nama'],
        noWhatsapp: j['noWhatsapp'],
        statusMember: j['statusMember'] ?? false,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'noWhatsapp': noWhatsapp,
        'statusMember': statusMember,
      };
}

class Layanan {
  int id;
  String nama;
  JenisLayanan jenis;
  String? tipeBahan; // null untuk layanan tambahan
  Kecepatan? kecepatan; // null untuk layanan tambahan
  int harga;
  Layanan({
    required this.id,
    required this.nama,
    required this.jenis,
    this.tipeBahan,
    this.kecepatan,
    required this.harga,
  });
  String get namaLengkap =>
      jenis == JenisLayanan.utama ? '$nama – $tipeBahan' : nama;
  factory Layanan.fromJson(Map<String, dynamic> j) => Layanan(
        id: j['id'],
        nama: j['nama'],
        jenis: JenisLayanan.values.byName(j['jenis']),
        tipeBahan: j['tipeBahan'],
        kecepatan: j['kecepatan'] == null
            ? null
            : Kecepatan.values.byName(j['kecepatan']),
        harga: j['harga'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'jenis': jenis.name,
        'tipeBahan': tipeBahan,
        'kecepatan': kecepatan?.name,
        'harga': harga,
      };
}

class RiwayatStatus {
  StatusPesanan status;
  DateTime waktu;
  RiwayatStatus(this.status, this.waktu);
  factory RiwayatStatus.fromJson(Map<String, dynamic> j) => RiwayatStatus(
        StatusPesanan.values.byName(j['status']),
        DateTime.parse(j['waktu']),
      );
  Map<String, dynamic> toJson() =>
      {'status': status.name, 'waktu': waktu.toIso8601String()};
}

class Pesanan {
  int id;
  int idCabang;
  int idPengguna;
  int idPelanggan;
  String noPesanan;
  DateTime tanggalMasuk;
  DateTime estimasiSelesai;
  StatusPesanan status;
  int totalBiaya;
  StatusBayar statusBayar;
  List<RiwayatStatus> riwayat;
  Pesanan({
    required this.id,
    required this.idCabang,
    required this.idPengguna,
    required this.idPelanggan,
    required this.noPesanan,
    required this.tanggalMasuk,
    required this.estimasiSelesai,
    required this.status,
    required this.totalBiaya,
    required this.statusBayar,
    required this.riwayat,
  });
  DateTime? waktuStatus(StatusPesanan s) {
    for (final r in riwayat) {
      if (r.status == s) return r.waktu;
    }
    return null;
  }

  factory Pesanan.fromJson(Map<String, dynamic> j) => Pesanan(
        id: j['id'],
        idCabang: j['idCabang'],
        idPengguna: j['idPengguna'],
        idPelanggan: j['idPelanggan'],
        noPesanan: j['noPesanan'],
        tanggalMasuk: DateTime.parse(j['tanggalMasuk']),
        estimasiSelesai: DateTime.parse(j['estimasiSelesai']),
        status: StatusPesanan.values.byName(j['status']),
        totalBiaya: j['totalBiaya'],
        statusBayar: StatusBayar.values.byName(j['statusBayar']),
        riwayat: (j['riwayat'] as List)
            .map((e) => RiwayatStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'idCabang': idCabang,
        'idPengguna': idPengguna,
        'idPelanggan': idPelanggan,
        'noPesanan': noPesanan,
        'tanggalMasuk': tanggalMasuk.toIso8601String(),
        'estimasiSelesai': estimasiSelesai.toIso8601String(),
        'status': status.name,
        'totalBiaya': totalBiaya,
        'statusBayar': statusBayar.name,
        'riwayat': riwayat.map((e) => e.toJson()).toList(),
      };
}

class DetailPesanan {
  int id;
  int idPesanan;
  int idLayanan;
  String merekSepatu;
  String? fotoBefore;
  String catatan;
  int harga; // harga layanan saat order dibuat
  DetailPesanan({
    required this.id,
    required this.idPesanan,
    required this.idLayanan,
    this.merekSepatu = '',
    this.fotoBefore,
    this.catatan = '',
    required this.harga,
  });
  factory DetailPesanan.fromJson(Map<String, dynamic> j) => DetailPesanan(
        id: j['id'],
        idPesanan: j['idPesanan'],
        idLayanan: j['idLayanan'],
        merekSepatu: j['merekSepatu'] ?? '',
        fotoBefore: j['fotoBefore'],
        catatan: j['catatan'] ?? '',
        harga: j['harga'],
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'idPesanan': idPesanan,
        'idLayanan': idLayanan,
        'merekSepatu': merekSepatu,
        'fotoBefore': fotoBefore,
        'catatan': catatan,
        'harga': harga,
      };
}

class Pembayaran {
  int id;
  int idPesanan;
  MetodeBayar metode;
  int jumlah;
  DateTime waktuBayar;
  Pembayaran({
    required this.id,
    required this.idPesanan,
    required this.metode,
    required this.jumlah,
    required this.waktuBayar,
  });
  factory Pembayaran.fromJson(Map<String, dynamic> j) => Pembayaran(
        id: j['id'],
        idPesanan: j['idPesanan'],
        metode: MetodeBayar.values.byName(j['metode']),
        jumlah: j['jumlah'],
        waktuBayar: DateTime.parse(j['waktuBayar']),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'idPesanan': idPesanan,
        'metode': metode.name,
        'jumlah': jumlah,
        'waktuBayar': waktuBayar.toIso8601String(),
      };
}

class NotifikasiWa {
  int id;
  int idPesanan;
  JenisPesan jenisPesan;
  String isiPesan;
  DateTime waktuKirim;
  NotifikasiWa({
    required this.id,
    required this.idPesanan,
    required this.jenisPesan,
    required this.isiPesan,
    required this.waktuKirim,
  });
  factory NotifikasiWa.fromJson(Map<String, dynamic> j) => NotifikasiWa(
        id: j['id'],
        idPesanan: j['idPesanan'],
        jenisPesan: JenisPesan.values.byName(j['jenisPesan']),
        isiPesan: j['isiPesan'],
        waktuKirim: DateTime.parse(j['waktuKirim']),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'idPesanan': idPesanan,
        'jenisPesan': jenisPesan.name,
        'isiPesan': isiPesan,
        'waktuKirim': waktuKirim.toIso8601String(),
      };
}

class AntarJemput {
  int id;
  int idPesanan;
  String alamat;
  DateTime jadwalJemput;
  DateTime? jadwalAntar;
  int biaya;
  StatusAntarJemput status;
  AntarJemput({
    required this.id,
    required this.idPesanan,
    required this.alamat,
    required this.jadwalJemput,
    this.jadwalAntar,
    required this.biaya,
    required this.status,
  });
  factory AntarJemput.fromJson(Map<String, dynamic> j) => AntarJemput(
        id: j['id'],
        idPesanan: j['idPesanan'],
        alamat: j['alamat'],
        jadwalJemput: DateTime.parse(j['jadwalJemput']),
        jadwalAntar: _dt(j['jadwalAntar']),
        biaya: j['biaya'],
        status: StatusAntarJemput.values.byName(j['status']),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'idPesanan': idPesanan,
        'alamat': alamat,
        'jadwalJemput': jadwalJemput.toIso8601String(),
        'jadwalAntar': jadwalAntar?.toIso8601String(),
        'biaya': biaya,
        'status': status.name,
      };
}
