import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../utils/format.dart';
import '../utils/security.dart';
import 'seed_data.dart';

/// Draft satu sepatu pada form order (belum disimpan).
class ShoeDraft {
  String? bahan;
  Kecepatan? kecepatan;
  String merek = '';
  String catatan = '';
  String? foto;
  final Map<int, int> tambahan = {}; // idLayanan tambahan -> harga
}

class AntarJemputDraft {
  final String alamat;
  final DateTime jadwalJemput;
  final int biaya;
  AntarJemputDraft(this.alamat, this.jadwalJemput, this.biaya);
}

class Laporan {
  final List<Pesanan> pesanan;
  final int pendapatan;
  final int jumlahLunas;
  final Map<int, int> orderPerCabang;
  final Map<int, int> pendapatanPerCabang;
  Laporan(this.pesanan, this.pendapatan, this.jumlahLunas, this.orderPerCabang,
      this.pendapatanPerCabang);
}

const syaratKetentuan = <String>[
  'Sepatu dicek terlebih dahulu sebelum diproses.',
  'Toko tidak menjamin sepatu kembali 100% seperti baru (tergantung material).',
  'Komplain maksimal 1x24 jam setelah sepatu diterima.',
  'Sepatu yang tidak diambil lebih dari 30 hari bukan tanggung jawab toko.',
  'Noda lama di dalam material akan dikonfirmasi terlebih dahulu.',
  'Garansi kerusakan hingga Rp1.000.000 untuk member.',
  'Sepatu lama/rapuh berisiko perubahan pada lem; sepatu terkena lumpur '
      'berisiko stain, shadow, yellowing, atau perubahan warna.',
];

class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const _kDb = 'ssc_db_v1';

  List<Cabang> cabang = [];
  List<Pengguna> pengguna = [];
  List<Pelanggan> pelanggan = [];
  List<Layanan> layanan = [];
  List<Pesanan> pesanan = [];
  List<DetailPesanan> detail = [];
  List<Pembayaran> pembayaran = [];
  List<NotifikasiWa> notifikasi = [];
  List<AntarJemput> antarJemput = [];
  String? qrisPath;
  Pengguna? user;

  // ---------------------------------------------------------------- simpan
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDb);
    if (raw == null) {
      final s = buatSeed();
      cabang = s.cabang;
      pengguna = s.pengguna;
      pelanggan = s.pelanggan;
      layanan = s.layanan;
      pesanan = s.pesanan;
      detail = s.detail;
      pembayaran = s.pembayaran;
      notifikasi = s.notifikasi;
      antarJemput = [];
      await _save();
      return;
    }
    final m = jsonDecode(raw) as Map<String, dynamic>;
    List<T> baca<T>(String k, T Function(Map<String, dynamic>) f) =>
        (m[k] as List? ?? [])
            .map((e) => f(e as Map<String, dynamic>))
            .toList();
    cabang = baca('cabang', Cabang.fromJson);
    pengguna = baca('pengguna', Pengguna.fromJson);
    pelanggan = baca('pelanggan', Pelanggan.fromJson);
    layanan = baca('layanan', Layanan.fromJson);
    pesanan = baca('pesanan', Pesanan.fromJson);
    detail = baca('detail', DetailPesanan.fromJson);
    pembayaran = baca('pembayaran', Pembayaran.fromJson);
    notifikasi = baca('notifikasi', NotifikasiWa.fromJson);
    antarJemput = baca('antarJemput', AntarJemput.fromJson);
    qrisPath = m['qrisPath'] as String?;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> js<T>(
            List<T> l, Map<String, dynamic> Function(T) f) =>
        l.map(f).toList();
    await prefs.setString(
      _kDb,
      jsonEncode({
        'cabang': js<Cabang>(cabang, (e) => e.toJson()),
        'pengguna': js<Pengguna>(pengguna, (e) => e.toJson()),
        'pelanggan': js<Pelanggan>(pelanggan, (e) => e.toJson()),
        'layanan': js<Layanan>(layanan, (e) => e.toJson()),
        'pesanan': js<Pesanan>(pesanan, (e) => e.toJson()),
        'detail': js<DetailPesanan>(detail, (e) => e.toJson()),
        'pembayaran': js<Pembayaran>(pembayaran, (e) => e.toJson()),
        'notifikasi': js<NotifikasiWa>(notifikasi, (e) => e.toJson()),
        'antarJemput': js<AntarJemput>(antarJemput, (e) => e.toJson()),
        'qrisPath': qrisPath,
      }),
    );
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  /// Hapus semua data dan kembali ke data awal (untuk uji coba).
  Future<void> resetKeSeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDb);
    user = null;
    await load();
    notifyListeners();
  }

  int _nextId(Iterable<int> ids) => ids.isEmpty ? 1 : ids.reduce(_maks) + 1;
  static int _maks(int a, int b) => a > b ? a : b;

  // ------------------------------------------------------------ autentikasi
  bool login(String username, String password) {
    final h = hashPassword(password);
    for (final p in pengguna) {
      if (p.username == username.trim() && p.passwordHash == h) {
        user = p;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    user = null;
    notifyListeners();
  }

  bool get isOwner => user?.role == Role.owner;

  /// Owner melihat semua cabang; kasir hanya cabangnya (kebutuhan Keamanan).
  Set<int> get idCabangTerlihat => isOwner
      ? cabang.map((e) => e.id).toSet()
      : {if (user != null) user!.idCabang};

  // ---------------------------------------------------------------- lookup
  Cabang? cabangById(int id) => _cari(cabang, (e) => e.id == id);
  Pelanggan? pelangganById(int id) => _cari(pelanggan, (e) => e.id == id);
  Layanan? layananById(int id) => _cari(layanan, (e) => e.id == id);
  Pengguna? penggunaById(int id) => _cari(pengguna, (e) => e.id == id);
  Pesanan? pesananById(int id) => _cari(pesanan, (e) => e.id == id);

  T? _cari<T>(List<T> l, bool Function(T) f) {
    for (final e in l) {
      if (f(e)) return e;
    }
    return null;
  }

  List<DetailPesanan> detailOf(int idPesanan) =>
      detail.where((e) => e.idPesanan == idPesanan).toList();
  List<Pembayaran> pembayaranOf(int idPesanan) =>
      pembayaran.where((e) => e.idPesanan == idPesanan).toList();
  List<NotifikasiWa> notifikasiOf(int idPesanan) =>
      notifikasi.where((e) => e.idPesanan == idPesanan).toList();
  AntarJemput? antarJemputOf(int idPesanan) =>
      _cari(antarJemput, (e) => e.idPesanan == idPesanan);

  int totalDibayar(int idPesanan) =>
      pembayaranOf(idPesanan).fold(0, (a, b) => a + b.jumlah);
  int sisaTagihan(Pesanan p) {
    final s = p.totalBiaya - totalDibayar(p.id);
    return s < 0 ? 0 : s;
  }

  // ------------------------------------------------------------- layanan
  List<String> get daftarBahan {
    final out = <String>[];
    for (final l in layanan) {
      if (l.jenis == JenisLayanan.utama &&
          l.tipeBahan != null &&
          !out.contains(l.tipeBahan)) {
        out.add(l.tipeBahan!);
      }
    }
    return out;
  }

  List<Kecepatan> kecepatanTersedia(String bahan) => layanan
      .where((l) => l.jenis == JenisLayanan.utama && l.tipeBahan == bahan)
      .map((l) => l.kecepatan!)
      .toList();

  Layanan? layananUtama(String? bahan, Kecepatan? k) {
    if (bahan == null || k == null) return null;
    return _cari(
        layanan,
        (l) =>
            l.jenis == JenisLayanan.utama &&
            l.tipeBahan == bahan &&
            l.kecepatan == k);
  }

  List<Layanan> get layananTambahan =>
      layanan.where((l) => l.jenis == JenisLayanan.tambahan).toList();

  void simpanLayanan(Layanan l) {
    if (l.id == 0) {
      l.id = _nextId(layanan.map((e) => e.id));
      layanan.add(l);
    }
    _commit();
  }

  // ------------------------------------------------------------ pelanggan
  Pelanggan? cariPelangganByWa(String wa) =>
      _cari(pelanggan, (p) => normalisasiWa(p.noWhatsapp) == normalisasiWa(wa));

  Pelanggan tambahPelanggan(String nama, String wa, {bool member = false}) {
    final p = Pelanggan(
        id: _nextId(pelanggan.map((e) => e.id)),
        nama: nama.trim(),
        noWhatsapp: wa.trim(),
        statusMember: member);
    pelanggan.add(p);
    _commit();
    return p;
  }

  void simpanPelanggan() => _commit(); // dipanggil setelah objek diubah

  // ---------------------------------------------------------------- order
  DateTime hitungEstimasi(List<ShoeDraft> sepatu) {
    final adaDeep = sepatu.any((s) => s.kecepatan == Kecepatan.deep);
    return DateTime.now().add(Duration(days: adaDeep ? 3 : 1));
  }

  Pesanan buatPesanan({
    required int idPelanggan,
    required int idCabang,
    required List<ShoeDraft> sepatu,
    required DateTime estimasi,
    AntarJemputDraft? aj,
  }) {
    final now = DateTime.now();
    final idPesanan = _nextId(pesanan.map((e) => e.id));
    final urut = pesanan.where((p) => p.idCabang == idCabang).length + 1;
    final kode = cabangById(idCabang)?.kode ?? 'XXX';
    var idDetail = _nextId(detail.map((e) => e.id));
    var total = 0;
    final baru = <DetailPesanan>[];

    for (final s in sepatu) {
      final utama = layananUtama(s.bahan, s.kecepatan)!;
      baru.add(DetailPesanan(
          id: idDetail++,
          idPesanan: idPesanan,
          idLayanan: utama.id,
          merekSepatu: s.merek.trim(),
          fotoBefore: s.foto,
          catatan: s.catatan.trim(),
          harga: utama.harga));
      total += utama.harga;
      for (final e in s.tambahan.entries) {
        baru.add(DetailPesanan(
            id: idDetail++,
            idPesanan: idPesanan,
            idLayanan: e.key,
            merekSepatu: s.merek.trim(),
            fotoBefore: s.foto,
            catatan: s.catatan.trim(),
            harga: e.value));
        total += e.value;
      }
    }
    if (aj != null) {
      total += aj.biaya;
      antarJemput.add(AntarJemput(
          id: _nextId(antarJemput.map((e) => e.id)),
          idPesanan: idPesanan,
          alamat: aj.alamat,
          jadwalJemput: aj.jadwalJemput,
          biaya: aj.biaya,
          status: StatusAntarJemput.menungguJemput));
    }
    detail.addAll(baru);
    final p = Pesanan(
        id: idPesanan,
        idCabang: idCabang,
        idPengguna: user!.id,
        idPelanggan: idPelanggan,
        noPesanan: 'SSC-$kode-${urut.toString().padLeft(4, '0')}',
        tanggalMasuk: now,
        estimasiSelesai: estimasi,
        status: StatusPesanan.diterima,
        totalBiaya: total,
        statusBayar: StatusBayar.belum,
        riwayat: [RiwayatStatus(StatusPesanan.diterima, now)]);
    pesanan.add(p);
    _commit();
    return p;
  }

  /// Mengembalikan pesan kesalahan, atau null bila berhasil.
  String? ubahStatus(int idPesanan, StatusPesanan baru) {
    final p = pesananById(idPesanan);
    if (p == null) return 'Order tidak ditemukan.';
    if (baru.index != p.status.index + 1) {
      return 'Status harus diubah berurutan.';
    }
    if (baru == StatusPesanan.diambil && p.statusBayar != StatusBayar.lunas) {
      return 'Pembayaran belum lunas. Proses pembayaran terlebih dahulu.';
    }
    p.status = baru;
    p.riwayat.add(RiwayatStatus(baru, DateTime.now()));
    _commit();
    return null;
  }

  /// Pengingat Tabel 2: sepatu selesai tetapi belum diambil (hari).
  int? hariBelumDiambil(Pesanan p) {
    if (p.status != StatusPesanan.selesai) return null;
    final sejak = p.waktuStatus(StatusPesanan.selesai) ?? p.tanggalMasuk;
    return DateTime.now().difference(sejak).inDays;
  }

  List<Pesanan> daftarPesanan({int? idCabang, StatusPesanan? status, String query = ''}) {
    final ids = idCabangTerlihat;
    final q = query.trim().toLowerCase();
    final hasil = pesanan.where((p) {
      if (!ids.contains(p.idCabang)) return false;
      if (idCabang != null && p.idCabang != idCabang) return false;
      if (status != null && p.status != status) return false;
      if (q.isNotEmpty) {
        final pel = pelangganById(p.idPelanggan);
        final teks = '${p.noPesanan} ${pel?.nama ?? ''} ${pel?.noWhatsapp ?? ''}'
            .toLowerCase();
        if (!teks.contains(q)) return false;
      }
      return true;
    }).toList();
    hasil.sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));
    return hasil;
  }

  // ----------------------------------------------------------- pembayaran
  String? catatPembayaran(int idPesanan, MetodeBayar metode, int jumlah) {
    final p = pesananById(idPesanan);
    if (p == null) return 'Order tidak ditemukan.';
    final sisa = sisaTagihan(p);
    if (jumlah <= 0) return 'Jumlah pembayaran harus lebih dari 0.';
    if (jumlah > sisa) return 'Jumlah melebihi sisa tagihan (${rupiah(sisa)}).';
    pembayaran.add(Pembayaran(
        id: _nextId(pembayaran.map((e) => e.id)),
        idPesanan: idPesanan,
        metode: metode,
        jumlah: jumlah,
        waktuBayar: DateTime.now()));
    if (totalDibayar(idPesanan) >= p.totalBiaya) {
      p.statusBayar = StatusBayar.lunas;
    }
    _commit();
    return null;
  }

  // ------------------------------------------------------------- WhatsApp
  String pesanWa(Pesanan p, JenisPesan jenis) {
    final c = cabangById(p.idCabang);
    final pel = pelangganById(p.idPelanggan);
    final sapaan = 'Halo Kak ${pel?.nama ?? ''}, ini Send Shoes Care '
        'cabang ${c?.nama ?? ''}.';
    if (jenis == JenisPesan.diterima) {
      return '$sapaan\n'
          'Sepatu Kakak sudah kami terima dengan nomor order ${p.noPesanan}.\n'
          'Estimasi selesai: ${tgl(p.estimasiSelesai)}.\n'
          'Total biaya: ${rupiah(p.totalBiaya)}.\n'
          'Terima kasih sudah mempercayakan sepatunya kepada kami.';
    }
    final sisa = sisaTagihan(p);
    return '$sapaan\n'
        'Sepatu Kakak dengan nomor order ${p.noPesanan} sudah SELESAI dan '
        'siap diambil di cabang ${c?.nama ?? ''}.\n'
        '${sisa > 0 ? 'Sisa pembayaran: ${rupiah(sisa)}.' : 'Pembayaran sudah lunas.'}\n'
        'Mohon membawa nota saat pengambilan. Terima kasih.';
  }

  void catatNotifikasi(int idPesanan, JenisPesan jenis, String isi) {
    notifikasi.add(NotifikasiWa(
        id: _nextId(notifikasi.map((e) => e.id)),
        idPesanan: idPesanan,
        jenisPesan: jenis,
        isiPesan: isi,
        waktuKirim: DateTime.now()));
    _commit();
  }

  // ---------------------------------------------------------- antar jemput
  String? majuStatusAntarJemput(int idPesanan) {
    final aj = antarJemputOf(idPesanan);
    final p = pesananById(idPesanan);
    if (aj == null || p == null) return 'Data antar-jemput tidak ada.';
    if (aj.status == StatusAntarJemput.menungguJemput) {
      aj.status = StatusAntarJemput.dijemput;
    } else if (aj.status == StatusAntarJemput.dijemput) {
      if (p.status.index < StatusPesanan.selesai.index) {
        return 'Sepatu belum selesai dikerjakan, belum bisa diantar.';
      }
      aj.status = StatusAntarJemput.diantar;
      aj.jadwalAntar = DateTime.now();
    } else {
      return 'Antar-jemput sudah selesai.';
    }
    _commit();
    return null;
  }

  // -------------------------------------------------------------- laporan
  Laporan laporan(
      {required DateTime dari, required DateTime sampai, int? idCabang}) {
    final ids = idCabang != null ? {idCabang} : idCabangTerlihat;
    bool dalam(DateTime d) => !d.isBefore(dari) && d.isBefore(sampai);
    final daftar = pesanan
        .where((p) => ids.contains(p.idCabang) && dalam(p.tanggalMasuk))
        .toList()
      ..sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));
    final orderPer = <int, int>{};
    final uangPer = <int, int>{};
    for (final p in daftar) {
      orderPer[p.idCabang] = (orderPer[p.idCabang] ?? 0) + 1;
    }
    var uang = 0;
    for (final b in pembayaran) {
      final p = pesananById(b.idPesanan);
      if (p == null || !ids.contains(p.idCabang) || !dalam(b.waktuBayar)) {
        continue;
      }
      uang += b.jumlah;
      uangPer[p.idCabang] = (uangPer[p.idCabang] ?? 0) + b.jumlah;
    }
    final lunas = daftar.where((p) => p.statusBayar == StatusBayar.lunas).length;
    return Laporan(daftar, uang, lunas, orderPer, uangPer);
  }

  String laporanCsv(Laporan l) {
    final sb = StringBuffer('\uFEFF');
    sb.writeln([
      'No Pesanan',
      'Tanggal Masuk',
      'Cabang',
      'Pelanggan',
      'Status',
      'Status Bayar',
      'Total Biaya',
      'Dibayar'
    ].join(';'));
    for (final p in l.pesanan) {
      sb.writeln([
        p.noPesanan,
        tglJam(p.tanggalMasuk),
        cabangById(p.idCabang)?.nama,
        pelangganById(p.idPelanggan)?.nama,
        p.status.label,
        p.statusBayar == StatusBayar.lunas ? 'Lunas' : 'Belum',
        p.totalBiaya,
        totalDibayar(p.id),
      ].map(csvSel).join(';'));
    }
    sb.writeln(['', '', '', '', '', 'Pendapatan (pembayaran masuk)', l.pendapatan, '']
        .map(csvSel)
        .join(';'));
    return sb.toString();
  }

  // ----------------------------------------------------------------- nota
  String notaTeks(Pesanan p) {
    final c = cabangById(p.idCabang);
    final pel = pelangganById(p.idPelanggan);
    final kasir = penggunaById(p.idPengguna);
    final aj = antarJemputOf(p.id);
    final b = StringBuffer()
      ..writeln('SEND SHOES CARE')
      ..writeln('"Trusted Care, Every Pair"')
      ..writeln('Cabang ${c?.nama ?? '-'}')
      ..writeln(c?.alamat ?? '')
      ..writeln('--------------------------------')
      ..writeln('No Order : ${p.noPesanan}')
      ..writeln('Tanggal  : ${tglJam(p.tanggalMasuk)}')
      ..writeln('Estimasi : ${tgl(p.estimasiSelesai)}')
      ..writeln('Kasir    : ${kasir?.nama ?? '-'}')
      ..writeln('Pelanggan: ${pel?.nama ?? '-'}'
          '${pel?.statusMember == true ? ' (MEMBER)' : ''}')
      ..writeln('--------------------------------');
    for (final d in detailOf(p.id)) {
      final l = layananById(d.idLayanan);
      b.writeln('${l?.namaLengkap ?? '-'}'
          '${d.merekSepatu.isEmpty ? '' : ' [${d.merekSepatu}]'}');
      b.writeln('   ${rupiah(d.harga)}');
    }
    if (aj != null) b.writeln('Antar-jemput\n   ${rupiah(aj.biaya)}');
    b
      ..writeln('--------------------------------')
      ..writeln('TOTAL    : ${rupiah(p.totalBiaya)}')
      ..writeln('Dibayar  : ${rupiah(totalDibayar(p.id))}')
      ..writeln('Status   : ${p.statusBayar == StatusBayar.lunas ? 'LUNAS' : 'BELUM LUNAS'}')
      ..writeln('--------------------------------')
      ..writeln('Syarat dan Ketentuan:');
    for (var i = 0; i < syaratKetentuan.length; i++) {
      b.writeln('${i + 1}. ${syaratKetentuan[i]}');
    }
    return b.toString();
  }

  // --------------------------------------------------- kelola (owner)
  void simpanCabang(Cabang c) {
    if (c.id == 0) {
      c.id = _nextId(cabang.map((e) => e.id));
      cabang.add(c);
    }
    _commit();
  }

  String? tambahPengguna(String nama, String username, String password,
      int idCabang, Role role) {
    if (pengguna.any((p) => p.username == username.trim())) {
      return 'Username sudah dipakai.';
    }
    pengguna.add(Pengguna(
        id: _nextId(pengguna.map((e) => e.id)),
        idCabang: idCabang,
        nama: nama.trim(),
        username: username.trim(),
        passwordHash: hashPassword(password),
        role: role));
    _commit();
    return null;
  }

  String? hapusPengguna(int id) {
    final p = penggunaById(id);
    if (p == null) return null;
    if (p.id == user?.id) return 'Akun yang sedang dipakai tidak bisa dihapus.';
    if (p.role == Role.owner &&
        pengguna.where((e) => e.role == Role.owner).length <= 1) {
      return 'Minimal harus ada satu akun Owner.';
    }
    if (pesanan.any((o) => o.idPengguna == id)) {
      return 'Pengguna sudah mencatat order, tidak bisa dihapus.';
    }
    pengguna.remove(p);
    _commit();
    return null;
  }

  void setQris(String? path) {
    qrisPath = path;
    _commit();
  }

  // ---------------------------------------------------------------- foto
  Future<String> simpanFoto(String sumber) async {
    if (kIsWeb) return sumber; // web: URL blob, tidak ada folder dokumen
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/foto');
    if (!await folder.exists()) await folder.create(recursive: true);
    final tujuan =
        '${folder.path}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(sumber).copy(tujuan);
    return tujuan;
  }
}
