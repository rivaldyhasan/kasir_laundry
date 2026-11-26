import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_store.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/widgets.dart';

enum Periode { harian, mingguan, bulanan }

/// B.12 Laporan dan Analitik / UC-12 Lihat Laporan / UC-13 Ekspor Excel.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});
  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _s = AppStore.instance;
  Periode _periode = Periode.harian;
  DateTime _acuan = DateTime.now();
  int? _cabang;

  (DateTime, DateTime) get _rentang {
    final d = DateTime(_acuan.year, _acuan.month, _acuan.day);
    switch (_periode) {
      case Periode.harian:
        return (d, d.add(const Duration(days: 1)));
      case Periode.mingguan:
        final senin = d.subtract(Duration(days: d.weekday - 1));
        return (senin, senin.add(const Duration(days: 7)));
      case Periode.bulanan:
        return (DateTime(d.year, d.month), DateTime(d.year, d.month + 1));
    }
  }

  String get _labelRentang {
    final (a, b) = _rentang;
    final akhir = b.subtract(const Duration(days: 1));
    return _periode == Periode.harian ? tgl(a) : '${tgl(a)} – ${tgl(akhir)}';
  }

  Future<void> _pilihTanggal() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _acuan,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _acuan = d);
  }

  Future<void> _ekspor(Laporan l) async {
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: _s.laporanCsv(l)));
      if (!mounted) return;
      snack(
        context,
        'CSV disalin ke clipboard. Tempel ke Excel/Notepad lalu simpan.',
      );
      return;
    }
    try {
      final (a, _) = _rentang;
      final nama =
          'laporan_${_periode.name}_${a.year}${a.month.toString().padLeft(2, '0')}${a.day.toString().padLeft(2, '0')}.csv';
      final desktop =
          Platform.isWindows || Platform.isLinux || Platform.isMacOS;

      if (desktop) {
        // Di laptop: simpan ke folder Downloads lalu buka dengan Excel.
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final f = File('${dir.path}${Platform.pathSeparator}$nama');
        await f.writeAsString(_s.laporanCsv(l));
        if (!mounted) return;
        snack(context, 'Laporan disimpan di ${f.path}');
        await launchUrl(Uri.file(f.path));
        return;
      }

      // Di HP: bagikan sebagai berkas (WhatsApp, Drive, email, dll.).
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/$nama');
      await f.writeAsString(_s.laporanCsv(l));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(f.path, mimeType: 'text/csv', name: nama)],
          fileNameOverrides: [nama],
          subject: nama,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      snack(context, 'Gagal mengekspor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final (dari, sampai) = _rentang;
        final l = _s.laporan(dari: dari, sampai: sampai, idCabang: _cabang);
        return Scaffold(
          appBar: AppBar(title: const Text('Laporan')),
          bottomNavigationBar: SafeArea(
            child: Container(
              color: kLatar,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: l.pesanan.isEmpty ? null : () => _ekspor(l),
                icon: const Icon(Icons.table_view, size: 18),
                label: const Text('Ekspor Excel (CSV)'),
              ),
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Row(
                    children: [
                      for (final p in Periode.values)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: p == Periode.bulanan ? 0 : 8,
                            ),
                            child: Pil(
                              switch (p) {
                                Periode.harian => 'Harian',
                                Periode.mingguan => 'Mingguan',
                                Periode.bulanan => 'Bulanan',
                              },
                              lebar: true,
                              aktif: _periode == p,
                              onTap: () => setState(() => _periode = p),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pilihTanggal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kGaris),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_outlined, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _labelRentang,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kGaris),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: _cabang,
                            style: const TextStyle(
                              color: kHitam,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kHitam,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pendapatan (pembayaran masuk)',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rupiah(l.pendapatan),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Angka('Jumlah order', '${l.pesanan.length}'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Angka('Order lunas', '${l.jumlahLunas}'),
                      ),
                    ],
                  ),
                  if (_cabang == null) ...[
                    const SizedBox(height: 12),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Per cabang',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final c in _s.cabang)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.nama,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${l.orderPerCabang[c.id] ?? 0} order',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    rupiah(l.pendapatanPerCabang[c.id] ?? 0),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LabelKecil('Daftar order pada periode'),
                  ),
                  if (l.pesanan.isEmpty)
                    const Panel(
                      child: Text(
                        'Tidak ada order pada periode ini.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  for (final p in l.pesanan)
                    Panel(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _s.pelangganById(p.idPelanggan)?.nama ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  p.noPesanan,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_s.cabangById(p.idCabang)?.nama ?? '-'}  |  ${tglJam(p.tanggalMasuk)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                rupiah(p.totalBiaya),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StatusChip(p.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Angka extends StatelessWidget {
  final String label;
  final String nilai;
  const _Angka(this.label, this.nilai);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kGaris),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          nilai,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
