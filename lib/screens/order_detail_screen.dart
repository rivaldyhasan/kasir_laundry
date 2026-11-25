import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/wa_sheet.dart';
import '../utils/widgets.dart';
import 'nota_screen.dart';
import 'payment_screen.dart';

/// S05 Detail Tiket / UC-04 Update Status / UC-07 WhatsApp /
/// UC-15 Update Status Antar Jemput.
class OrderDetailScreen extends StatefulWidget {
  final int idPesanan;
  const OrderDetailScreen({super.key, required this.idPesanan});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _s = AppStore.instance;

  StatusPesanan? _berikut(Pesanan p) {
    final i = p.status.index + 1;
    return i < StatusPesanan.values.length ? StatusPesanan.values[i] : null;
  }

  void _bukaNota() => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NotaScreen(idPesanan: widget.idPesanan)));

  Future<void> _bayar() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => PaymentScreen(idPesanan: widget.idPesanan)),
    );
    if (!mounted) return;
    if (ok == true) {
      snack(context, 'Pembayaran dicatat');
      final p = _s.pesananById(widget.idPesanan);
      if (p?.statusBayar == StatusBayar.lunas) _bukaNota();
    }
  }

  Future<void> _lanjutStatus(Pesanan p) async {
    final berikut = _berikut(p);
    if (berikut == null) return;

    // Activity diagram: belum lunas -> proses pembayaran dulu.
    if (berikut == StatusPesanan.diambil && p.statusBayar != StatusBayar.lunas) {
      final bayarDulu = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pembayaran belum lunas'),
          content: const Text(
              'Selesaikan pembayaran dulu sebelum sepatu diserahkan.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Bayar sekarang')),
          ],
        ),
      );
      if (bayarDulu == true && mounted) await _bayar();
      return;
    }

    final err = _s.ubahStatus(p.id, berikut);
    if (!mounted) return;
    if (err != null) {
      snack(context, err);
    } else if (berikut == StatusPesanan.selesai) {
      snack(context,
          'Status selesai. Kirim kabar ke pelanggan lewat tombol WhatsApp.');
    }
  }

  void _ajMaju() {
    final err = _s.majuStatusAntarJemput(widget.idPesanan);
    if (err != null) snack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final p = _s.pesananById(widget.idPesanan);
        if (p == null) {
          return const Scaffold(
              body: Center(child: Text('Order tidak ditemukan')));
        }
        final pel = _s.pelangganById(p.idPelanggan);
        final kasir = _s.penggunaById(p.idPengguna);
        final cabang = _s.cabangById(p.idCabang);
        final detail = _s.detailOf(p.id);
        final bayarList = _s.pembayaranOf(p.id);
        final notifList = _s.notifikasiOf(p.id);
        final aj = _s.antarJemputOf(p.id);
        final berikut = _berikut(p);
        final sisa = _s.sisaTagihan(p);
        final lunas = p.statusBayar == StatusBayar.lunas;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Tiket'),
            actions: [
              IconButton(
                tooltip: 'Nota',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: _bukaNota,
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Header tiket
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(child: LabelKecil('ID tiket workshop')),
                            LabelChip(cabang?.nama ?? '-', Colors.blueGrey),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(p.noPesanan,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 22)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                                child: KotakInfo(
                                    'Tanggal masuk', tglJam(p.tanggalMasuk))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: KotakInfo(
                                    'Petugas kasir', kasir?.nama ?? '-')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        KotakInfo(
                            'Estimasi selesai', tgl(p.estimasiSelesai)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${pel?.nama ?? '-'}'
                                '${pel?.statusMember == true ? ' (member)' : ''}'
                                '${pel == null ? '' : '  |  ${pel.noWhatsapp}'}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12.5),
                              ),
                            ),
                            BayarChip(p.statusBayar),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Progres pengerjaan
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Progres pengerjaan',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                            Text(
                                'Tahap ${p.status.index + 1} dari ${StatusPesanan.values.length}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Timeline(p),
                      ],
                    ),
                  ),

                  // --- Rincian layanan
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rincian layanan',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        if (detail.isEmpty)
                          const Text('Rincian belum tercatat (order contoh).',
                              style: TextStyle(color: Colors.grey)),
                        for (final d in detail)
                          Builder(builder: (_) {
                            final l = _s.layananById(d.idLayanan);
                            final utama = l?.jenis == JenisLayanan.utama;
                            final sub = [
                              if (d.merekSepatu.isNotEmpty) d.merekSepatu,
                              if (d.catatan.isNotEmpty) d.catatan,
                            ].join(' | ');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  utama
                                      ? FotoKotak(d.fotoBefore, ukuran: 52)
                                      : const SizedBox(width: 52),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            l == null
                                                ? 'Layanan #${d.idLayanan}'
                                                : '${l.namaLengkap}${l.kecepatan != null ? ' (${l.kecepatan!.label})' : ''}',
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
                        if (aj != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const SizedBox(
                                    width: 52,
                                    child: Icon(Icons.local_shipping_outlined)),
                                const SizedBox(width: 10),
                                const Expanded(
                                    child: Text('Antar-jemput',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600))),
                                Text(rupiah(aj.biaya),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- Antar-jemput
                  if (aj != null)
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Layanan antar-jemput',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ),
                              LabelChip(aj.status.label, Colors.indigo),
                            ],
                          ),
                          const SizedBox(height: 8),
                          BarisKV('Alamat', aj.alamat),
                          BarisKV('Jadwal jemput', tglJam(aj.jadwalJemput)),
                          BarisKV(
                              'Diantar',
                              aj.jadwalAntar == null
                                  ? '-'
                                  : tglJam(aj.jadwalAntar!)),
                          if (aj.status != StatusAntarJemput.diantar)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 44),
                                  foregroundColor: kHitam,
                                  side: const BorderSide(color: kGaris),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _ajMaju,
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: Text(
                                    aj.status ==
                                            StatusAntarJemput.menungguJemput
                                        ? 'Tandai sudah dijemput'
                                        : 'Tandai sudah diantar'),
                              ),
                            ),
                        ],
                      ),
                    ),

                  // --- Pembayaran
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pembayaran',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        BarisKV('Total', rupiah(p.totalBiaya), tebal: true),
                        BarisKV('Dibayar', rupiah(_s.totalDibayar(p.id))),
                        BarisKV('Sisa', rupiah(sisa)),
                        for (final b in bayarList)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                                '${tglJam(b.waktuBayar)}: ${rupiah(b.jumlah)} (${b.metode.label})',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ),
                        if (!lunas)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                foregroundColor: kHitam,
                                side: const BorderSide(color: kGaris),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _bayar,
                              icon:
                                  const Icon(Icons.payments_outlined, size: 18),
                              label: const Text('Catat pembayaran'),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- Riwayat WhatsApp
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Riwayat WhatsApp',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        if (notifList.isEmpty)
                          const Text('Belum ada pesan terkirim.',
                              style: TextStyle(color: Colors.grey)),
                        for (final n in notifList)
                          Text(
                              '${tglJam(n.waktuKirim)}  |  ${n.jenisPesan == JenisPesan.diterima ? 'Order diterima' : 'Order selesai'}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              color: kLatar,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: kHitam,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: kGaris),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => tampilkanSheetWa(context, p),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: berikut != null
                        ? FilledButton(
                            onPressed: () => _lanjutStatus(p),
                            child: Text('Ubah ke ${berikut.label}  →'),
                          )
                        : FilledButton(
                            onPressed: _bukaNota,
                            child: const Text('Lihat nota'),
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

/// Garis waktu 4 tahap status order.
class _Timeline extends StatelessWidget {
  final Pesanan p;
  const _Timeline(this.p);

  static const _ket = {
    StatusPesanan.diterima: 'Barang diinspeksi dan dicatat ke sistem kasir',
    StatusPesanan.diproses: 'Cuci dan treatment sedang dikerjakan',
    StatusPesanan.selesai: 'Pengecekan kualitas akhir dan packaging',
    StatusPesanan.diambil: 'Serah terima ke pelanggan, garansi komplain 1x24 jam',
  };

  @override
  Widget build(BuildContext context) {
    const semua = StatusPesanan.values;
    return Column(
      children: [
        for (final st in semua)
          Builder(builder: (_) {
            final selesaiSemua = p.status == StatusPesanan.diambil;
            final done = st.index < p.status.index ||
                (selesaiSemua && st == StatusPesanan.diambil);
            final aktif = st == p.status && !selesaiSemua;
            final terakhir = st == semua.last;
            final waktu = p.waktuStatus(st);
            final warnaTeks = (done || aktif) ? kHitam : Colors.grey;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: done ? kHitam : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: (done || aktif) ? kHitam : kGaris,
                                width: 2),
                          ),
                          child: done
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : aktif
                                  ? const Center(
                                      child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: kHitam))
                                  : null,
                        ),
                        if (!terakhir)
                          Expanded(
                            child: Container(
                                width: 2, color: done ? kHitam : kGaris),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: terakhir ? 0 : 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                    '${st.index + 1}. ${st.label}'
                                    '${aktif ? ' (aktif)' : ''}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: warnaTeks)),
                              ),
                              Text(waktu == null ? '-' : tglJam(waktu),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          Text(_ket[st] ?? '',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: (done || aktif)
                                      ? Colors.black54
                                      : Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
