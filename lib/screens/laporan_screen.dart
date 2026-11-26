import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_store.dart';
import '../utils/format.dart';
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
        lastDate: DateTime.now().add(const Duration(days: 1)));
    if (d != null) setState(() => _acuan = d);
  }

  Future<void> _ekspor(Laporan l) async {
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: _s.laporanCsv(l)));
      if (!mounted) return;
      snack(context, 'CSV disalin ke clipboard. Tempel ke Excel/Notepad lalu simpan.');
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
        final dir = await getDownloadsDirectory() ??
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
      await SharePlus.instance.share(ShareParams(
          files: [XFile(f.path, mimeType: 'text/csv', name: nama)],
          fileNameOverrides: [nama],
          subject: nama));
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: l.pesanan.isEmpty ? null : () => _ekspor(l),
            icon: const Icon(Icons.table_view),
            label: const Text('Ekspor Excel'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              SegmentedButton<Periode>(
                segments: const [
                  ButtonSegment(value: Periode.harian, label: Text('Harian')),
                  ButtonSegment(value: Periode.mingguan, label: Text('Mingguan')),
                  ButtonSegment(value: Periode.bulanan, label: Text('Bulanan')),
                ],
                selected: {_periode},
                onSelectionChanged: (v) => setState(() => _periode = v.first),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pilihTanggal,
                      icon: const Icon(Icons.event),
                      label: Text(_labelRentang),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int?>(
                    value: _cabang,
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Semua cabang')),
                      ..._s.cabang.map((c) => DropdownMenuItem<int?>(
                          value: c.id, child: Text(c.nama))),
                    ],
                    onChanged: (v) => setState(() => _cabang = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _Kartu('Jumlah order', '${l.pesanan.length}')),
                  Expanded(child: _Kartu('Order lunas', '${l.jumlahLunas}')),
                ],
              ),
              _Kartu('Pendapatan (pembayaran masuk)', rupiah(l.pendapatan)),
              if (_cabang == null) ...[
                const Judul('Per cabang'),
                Card(
                  child: Column(
                    children: [
                      for (final c in _s.cabang)
                        ListTile(
                          dense: true,
                          title: Text(c.nama),
                          subtitle: Text('${l.orderPerCabang[c.id] ?? 0} order'),
                          trailing: Text(rupiah(l.pendapatanPerCabang[c.id] ?? 0),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ],
              const Judul('Daftar order pada periode'),
              if (l.pesanan.isEmpty) const Text('Tidak ada order pada periode ini.'),
              for (final p in l.pesanan)
                Card(
                  child: ListTile(
                    dense: true,
                    title: Text(
                        '${p.noPesanan} • ${_s.pelangganById(p.idPelanggan)?.nama ?? '-'}'),
                    subtitle: Text(
                        '${_s.cabangById(p.idCabang)?.nama ?? '-'} • ${tglJam(p.tanggalMasuk)}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(rupiah(p.totalBiaya)),
                        StatusChip(p.status),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Kartu extends StatelessWidget {
  final String label;
  final String nilai;
  const _Kartu(this.label, this.nilai);
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(nilai,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
}
