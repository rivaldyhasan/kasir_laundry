import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/wa_sheet.dart';
import '../utils/widgets.dart';
import 'order_detail_screen.dart';

/// Layanan Antar-Jemput / UC-14, UC-15: daftar tugas kurir per status.
class AntarJemputScreen extends StatefulWidget {
  const AntarJemputScreen({super.key});
  @override
  State<AntarJemputScreen> createState() => _AntarJemputScreenState();
}

class _AntarJemputScreenState extends State<AntarJemputScreen> {
  final _s = AppStore.instance;
  StatusAntarJemput _tab = StatusAntarJemput.menungguJemput;

  List<AntarJemput> _daftar(StatusAntarJemput st) {
    final ids = _s.idCabangTerlihat;
    final hasil = _s.antarJemput.where((a) {
      final p = _s.pesananById(a.idPesanan);
      return a.status == st && p != null && ids.contains(p.idCabang);
    }).toList()
      ..sort((a, b) => a.jadwalJemput.compareTo(b.jadwalJemput));
    return hasil;
  }

  void _maju(AntarJemput a) {
    final err = _s.majuStatusAntarJemput(a.idPesanan);
    if (err != null) snack(context, err);
  }

  static String _namaTab(StatusAntarJemput s) => switch (s) {
        StatusAntarJemput.menungguJemput => 'Tunggu',
        StatusAntarJemput.dijemput => 'Dijemput',
        StatusAntarJemput.diantar => 'Diantar',
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final daftar = _daftar(_tab);
        return Scaffold(
          appBar: AppBar(title: const Text('Antar-Jemput')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        for (final st in StatusAntarJemput.values)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: st == StatusAntarJemput.diantar ? 0 : 8),
                              child: Pil(
                                '${_namaTab(st)} (${_daftar(st).length})',
                                lebar: true,
                                aktif: _tab == st,
                                onTap: () => setState(() => _tab = st),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: daftar.isEmpty
                        ? const Center(
                            child: Text('Belum ada tugas di tahap ini',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: daftar.length,
                            itemBuilder: (_, i) => _kartu(daftar[i]),
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

  Widget _kartu(AntarJemput a) {
    final p = _s.pesananById(a.idPesanan)!;
    final pel = _s.pelangganById(p.idPelanggan);
    final siapAntar = a.status == StatusAntarJemput.dijemput &&
        p.status.index >= StatusPesanan.selesai.index;
    return Panel(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(idPesanan: p.id))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pel?.nama ?? '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                            '${p.noPesanan}  |  ${_s.cabangById(p.idCabang)?.nama ?? '-'}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (siapAntar)
                    const LabelChip('Siap diantar', Colors.green)
                  else
                    LabelChip(a.status.label, Colors.indigo),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: kAbu, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(a.alamat,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 6),
                      Text('Jemput ${tglJam(a.jadwalJemput)}',
                          style: const TextStyle(fontSize: 12.5)),
                    ],
                  ),
                  if (a.jadwalAntar != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 6),
                        Text('Diantar ${tglJam(a.jadwalAntar!)}',
                            style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
                'Status order: ${p.status.label}  |  biaya ${rupiah(a.biaya)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (a.status != StatusAntarJemput.diantar) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: kHitam,
                        side: const BorderSide(color: kGaris),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => tampilkanSheetWa(context, p),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44)),
                      onPressed: () => _maju(a),
                      child: Text(
                          a.status == StatusAntarJemput.menungguJemput
                              ? 'Tandai dijemput  →'
                              : 'Tandai diantar  →'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
