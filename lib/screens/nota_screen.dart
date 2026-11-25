import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/widgets.dart';

/// S08 Nota Transaksi / UC-06 / KF-07: nota digital berisi nomor order,
/// cabang, status member, dan syarat dan ketentuan (Tabel 2).
class NotaScreen extends StatelessWidget {
  final int idPesanan;
  const NotaScreen({super.key, required this.idPesanan});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    final p = s.pesananById(idPesanan);
    if (p == null) {
      return const Scaffold(body: Center(child: Text('Order tidak ditemukan')));
    }
    final cabang = s.cabangById(p.idCabang);
    final pel = s.pelangganById(p.idPelanggan);
    final kasir = s.penggunaById(p.idPengguna);
    final aj = s.antarJemputOf(p.id);
    final lunas = p.statusBayar == StatusBayar.lunas;
    final bayar = s.pembayaranOf(p.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Nota Transaksi')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Panel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Transaksi tercatat',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text(lunas ? 'Siap cetak & kirim' : 'Belum lunas',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Image.asset('assets/images/logo.png',
                              width: 56,
                              height: 56,
                              errorBuilder: (_, _, _) => const Icon(
                                  Icons.local_laundry_service,
                                  size: 40)),
                          const SizedBox(height: 8),
                          const Text('SEND SHOES CARE',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17)),
                          const Text('Trusted Care, Every Pair',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: kAbu,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              'Cabang ${cabang?.nama ?? '-'}'
                              '${(cabang?.alamat ?? '').isEmpty ? '' : ' | ${cabang!.alamat}'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const LabelKecil('Nomor nota'),
                              const SizedBox(height: 2),
                              Text(p.noPesanan,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                        LabelChip(lunas ? 'LUNAS' : 'BELUM LUNAS',
                            lunas ? Colors.green : Colors.red),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BarisKV('Waktu transaksi', tglJam(p.tanggalMasuk)),
                    BarisKV('Estimasi selesai', tgl(p.estimasiSelesai)),
                    BarisKV('Petugas kasir', kasir?.nama ?? '-'),
                    BarisKV(
                        'Pelanggan',
                        '${pel?.nama ?? '-'}'
                            '${pel?.statusMember == true ? ' (member)' : ''}'),
                    const Divider(height: 24),
                    const LabelKecil('Item & layanan'),
                    const SizedBox(height: 6),
                    for (final d in s.detailOf(p.id))
                      Builder(builder: (_) {
                        final l = s.layananById(d.idLayanan);
                        final sub = [
                          if (l?.kecepatan != null) l!.kecepatan!.label,
                          if (d.merekSepatu.isNotEmpty) d.merekSepatu,
                        ].join(' | ');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l?.namaLengkap ?? 'Layanan',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    if (sub.isNotEmpty)
                                      Text(sub,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(rupiah(d.harga),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }),
                    if (aj != null) BarisKV('Antar-jemput', rupiah(aj.biaya)),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('TOTAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                        Text(rupiah(p.totalBiaya),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    BarisKV('Dibayar', rupiah(s.totalDibayar(p.id))),
                    if (!lunas) BarisKV('Sisa', rupiah(s.sisaTagihan(p))),
                    if (bayar.isNotEmpty)
                      BarisKV('Metode terakhir', bayar.last.metode.label),
                  ],
                ),
              ),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LabelKecil('Syarat & ketentuan'),
                    const SizedBox(height: 8),
                    for (var i = 0; i < syaratKetentuan.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${i + 1}. ${syaratKetentuan[i]}',
                            style: const TextStyle(
                                fontSize: 12, height: 1.35, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: () => SharePlus.instance.share(
                ShareParams(text: s.notaTeks(p), subject: 'Nota ${p.noPesanan}')),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Bagikan / cetak nota'),
          ),
        ),
      ),
    );
  }
}
