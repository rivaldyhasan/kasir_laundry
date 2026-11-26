import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/wa_helper.dart';
import '../utils/widgets.dart';
import 'antar_jemput_screen.dart';
import 'kelola_screen.dart';
import 'laporan_screen.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';
import 'pelanggan_screen.dart';

/// B.2 / B.3 Dashboard Kasir dan Owner. Tab: Beranda dan Pesanan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

void _bukaLayar(BuildContext context, Widget layar) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));

class _HomeScreenState extends State<HomeScreen> {
  final _s = AppStore.instance;
  int _tab = 0; // 0 = Beranda, 1 = Pesanan

  void _menuAkun() {
    final user = _s.user;
    if (user == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: kHitam,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(user.nama),
              subtitle: Text(
                _s.isOwner
                    ? 'Owner, semua cabang'
                    : 'Kasir, ${_s.cabangById(user.idCabang)?.nama ?? '-'}',
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Antar-Jemput'),
              onTap: () {
                Navigator.pop(ctx);
                _bukaLayar(context, const AntarJemputScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Pelanggan'),
              onTap: () {
                Navigator.pop(ctx);
                _bukaLayar(context, const PelangganScreen());
              },
            ),
            if (_s.isOwner) ...[
              ListTile(
                leading: const Icon(Icons.bar_chart),
                title: const Text('Laporan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _bukaLayar(context, const LaporanScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Kelola'),
                onTap: () {
                  Navigator.pop(ctx);
                  _bukaLayar(context, const KelolaScreen());
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar'),
              onTap: () {
                Navigator.pop(ctx);
                _s.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final user = _s.user;
        if (user == null) return const SizedBox.shrink();
        final cabang = _s.isOwner
            ? 'Semua cabang'
            : (_s.cabangById(user.idCabang)?.nama ?? '-');

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: Image.asset(
                          'assets/images/logo.png',
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.cleaning_services),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send Shoes Care',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Trusted Care, Every Pair | $cabang',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: _menuAkun,
                        borderRadius: BorderRadius.circular(20),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundColor: kHitam,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tab == 0 ? const _Beranda() : const _TabPesanan(),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _BarBawah(
            tab: _tab,
            onTab: (i) => setState(() => _tab = i),
            onOrderBaru: () => _bukaLayar(context, const OrderFormScreen()),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------- Beranda
String _waktu(DateTime d) {
  final sekarang = DateTime.now();
  final hariIni =
      d.year == sekarang.year &&
      d.month == sekarang.month &&
      d.day == sekarang.day;
  final jam = DateFormat('HH:mm').format(d);
  return hariIni ? 'Hari ini, $jam' : '${tgl(d)}, $jam';
}

String _ringkasLayanan(Pesanan p) {
  final s = AppStore.instance;
  final utama = s
      .detailOf(p.id)
      .map((d) => s.layananById(d.idLayanan))
      .whereType<Layanan>()
      .where((l) => l.jenis == JenisLayanan.utama)
      .toList();
  if (utama.isEmpty) return 'Rincian belum tercatat';
  final l = utama.first;
  final teks = '${l.tipeBahan ?? l.nama} (${l.kecepatan?.label ?? '-'})';
  return utama.length > 1 ? '$teks +${utama.length - 1} lainnya' : teks;
}

class _Beranda extends StatelessWidget {
  const _Beranda();

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final user = s.user!;
    final semua = s.daftarPesanan();

    int pasang(Pesanan p) {
      final n = s
          .detailOf(p.id)
          .where((d) => s.layananById(d.idLayanan)?.jenis == JenisLayanan.utama)
          .length;
      return n == 0 ? 1 : n;
    }

    int hitung(StatusPesanan st) =>
        semua.where((p) => p.status == st).fold(0, (a, p) => a + pasang(p));

    final perluDikabari = semua
        .where(
          (p) =>
              p.status == StatusPesanan.selesai &&
              !s
                  .notifikasiOf(p.id)
                  .any((n) => n.jenisPesan == JenisPesan.selesai),
        )
        .toList();
    final mendekati = semua.where((p) {
      final h = s.hariBelumDiambil(p);
      return h != null && h >= 25;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat bertugas, ${user.nama}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.isOwner
                          ? 'Owner | Semua cabang'
                          : s.cabangById(user.idCabang)?.nama ?? '-',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Stat(
                'Diterima',
                hitung(StatusPesanan.diterima),
                Icons.inbox_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                'Diproses',
                hitung(StatusPesanan.diproses),
                Icons.autorenew,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                'Selesai',
                hitung(StatusPesanan.selesai),
                Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: kHitam,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _bukaLayar(context, const OrderFormScreen()),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+ Order Baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Input sepatu & pelanggan baru',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        _Judul(
          'Perlu Dikabari',
          jumlah: perluDikabari.length,
          kanan: 'Belum ada chat WA',
        ),
        if (perluDikabari.isEmpty)
          const _Kosong('Semua order selesai sudah dikabari.'),
        for (final p in perluDikabari) _KartuKabari(p: p),
        _Judul(
          'Mendekati 30 Hari Belum Diambil',
          jumlah: mendekati.length,
          kanan: 'S&K Berlaku',
        ),
        if (mendekati.isEmpty)
          const _Kosong('Tidak ada order yang mendekati batas 30 hari.'),
        for (final p in mendekati) _KartuLama(p: p),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int jumlah;
  final IconData ikon;
  const _Stat(this.label, this.jumlah, this.ikon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kGaris),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            Icon(ikon, size: 16),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$jumlah',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'psg',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Judul extends StatelessWidget {
  final String teks;
  final int jumlah;
  final String kanan;
  const _Judul(this.teks, {required this.jumlah, required this.kanan});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Row(
      children: [
        Flexible(
          child: Text(
            teks,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: kAbu,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$jumlah',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        const Spacer(),
        Text(kanan, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );
}

class _Kosong extends StatelessWidget {
  final String teks;
  const _Kosong(this.teks);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(teks, style: const TextStyle(color: Colors.grey)),
  );
}

class _BarisLayanan extends StatelessWidget {
  final String kiri;
  final String kanan;
  const _BarisLayanan(this.kiri, this.kanan);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: kAbu,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.cleaning_services_outlined, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            kiri,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Text(kanan, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    ),
  );
}

class _KartuKabari extends StatelessWidget {
  final Pesanan p;
  const _KartuKabari({required this.p});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final pel = s.pelangganById(p.idPelanggan);
    final selesai = p.waktuStatus(StatusPesanan.selesai) ?? p.tanggalMasuk;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _bukaLayar(context, OrderDetailScreen(idPesanan: p.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pel?.nama ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '#${p.noPesanan}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const LabelChip('Selesai', kHitam),
                ],
              ),
              const SizedBox(height: 10),
              _BarisLayanan(_ringkasLayanan(p), _waktu(selesai)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => kirimWaOrder(context, p, JenisPesan.selesai),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Kirim WhatsApp'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuLama extends StatelessWidget {
  final Pesanan p;
  const _KartuLama({required this.p});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final pel = s.pelangganById(p.idPelanggan);
    final hari = s.hariBelumDiambil(p) ?? 0;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _bukaLayar(context, OrderDetailScreen(idPesanan: p.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pel?.nama ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '#${p.noPesanan}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              LabelChip('$hari hari', hari >= 30 ? Colors.red : Colors.orange),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- Pesanan
class _TabPesanan extends StatefulWidget {
  const _TabPesanan();
  @override
  State<_TabPesanan> createState() => _TabPesananState();
}

class _TabPesananState extends State<_TabPesanan> {
  final _s = AppStore.instance;
  final _cari = TextEditingController();
  StatusPesanan? _status;
  int? _cabang;

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daftar = _s.daftarPesanan(
      idCabang: _s.isOwner ? _cabang : null,
      status: _status,
      query: _cari.text,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _cari,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari nama pelanggan atau kode pesanan',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kGaris),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kGaris),
              ),
              suffixIcon: _cari.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(_cari.clear),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Pil('Semua',
                    aktif: _status == null,
                    onTap: () => setState(() => _status = null)),
              ),
              for (final st in StatusPesanan.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Pil(st.label,
                      aktif: _status == st,
                      onTap: () => setState(() => _status = st)),
                ),
              if (_s.isOwner)
                DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _cabang,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Semua cabang'),
                      ),
                      ..._s.cabang.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.nama),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _cabang = v),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: daftar.isEmpty
              ? const Center(
                  child: Text('Tidak ada order',
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: daftar.length,
                  itemBuilder: (context, i) => _KartuOrder(
                    p: daftar[i],
                    onTap: () => _bukaLayar(
                      context,
                      OrderDetailScreen(idPesanan: daftar[i].id),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _KartuOrder extends StatelessWidget {
  final Pesanan p;
  final VoidCallback onTap;
  const _KartuOrder({required this.p, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final pel = s.pelangganById(p.idPelanggan);
    final hari = s.hariBelumDiambil(p);
    final detail = s.detailOf(p.id);
    final utama = detail.where((d) =>
        s.layananById(d.idLayanan)?.jenis == JenisLayanan.utama);
    final pertama = utama.isEmpty ? null : utama.first;
    final layananPertama =
        pertama == null ? null : s.layananById(pertama.idLayanan);
    final jumlahPasang = utama.length;

    return Panel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pel?.nama ?? '-'}'
                      '${pel?.statusMember == true ? '  (member)' : ''}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  StatusChip(p.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${p.noPesanan}  |  ${s.cabangById(p.idCabang)?.nama ?? '-'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAbu,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    FotoKotak(pertama?.fotoBefore, ukuran: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pertama == null || pertama.merekSepatu.isEmpty
                                ? 'Rincian belum tercatat'
                                : pertama.merekSepatu,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            [
                              if (layananPertama != null)
                                layananPertama.namaLengkap,
                              if (jumlahPasang > 1)
                                '+${jumlahPasang - 1} pasang lain',
                            ].join('  |  '),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11.5),
                          ),
                          Text('Estimasi ${tgl(p.estimasiSelesai)}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Total tagihan  ',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    rupiah(p.totalBiaya),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const Spacer(),
                  BayarChip(p.statusBayar),
                  if (s.antarJemputOf(p.id) != null) ...[
                    const SizedBox(width: 6),
                    const LabelChip('Antar-jemput', Colors.indigo),
                  ],
                ],
              ),
              if (hari != null && hari >= 25)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Sudah $hari hari belum diambil (batas 30 hari)',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- Bottom bar
class _BarBawah extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTab;
  final VoidCallback onOrderBaru;
  const _BarBawah({
    required this.tab,
    required this.onTab,
    required this.onOrderBaru,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: kGaris)),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ItemBar('Beranda', Icons.home_outlined, tab == 0, () => onTab(0)),
            FilledButton.icon(
              onPressed: onOrderBaru,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Order Baru'),
            ),
            _ItemBar(
              'Pesanan',
              Icons.receipt_long_outlined,
              tab == 1,
              () => onTab(1),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ItemBar extends StatelessWidget {
  final String label;
  final IconData ikon;
  final bool aktif;
  final VoidCallback onTap;
  const _ItemBar(this.label, this.ikon, this.aktif, this.onTap);

  @override
  Widget build(BuildContext context) {
    final warna = aktif ? kHitam : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, color: warna),
            Text(
              label,
              style: TextStyle(
                color: warna,
                fontSize: 12,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
