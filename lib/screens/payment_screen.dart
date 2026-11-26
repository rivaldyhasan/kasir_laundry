import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/widgets.dart';

/// S07 Pembayaran / UC-05 Proses Pembayaran / KF-10, KF-11.
/// Pop dengan nilai true bila pembayaran berhasil dicatat.
class PaymentScreen extends StatefulWidget {
  final int idPesanan;
  const PaymentScreen({super.key, required this.idPesanan});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _s = AppStore.instance;
  MetodeBayar _metode = MetodeBayar.tunai;
  late final TextEditingController _diterima;

  @override
  void initState() {
    super.initState();
    final p = _s.pesananById(widget.idPesanan)!;
    _diterima = TextEditingController(text: '${_s.sisaTagihan(p)}');
  }

  @override
  void dispose() {
    _diterima.dispose();
    super.dispose();
  }

  int get _nilai => int.tryParse(_diterima.text) ?? 0;

  List<int> _preset(int sisa) {
    int naik(int step) => ((sisa + step - 1) ~/ step) * step;
    final out = <int>{sisa, naik(50000), naik(100000), naik(50000) + 50000};
    return out.where((e) => e > 0).take(3).toList();
  }

  void _konfirmasi(int sisa) {
    // Uang diterima boleh lebih besar dari tagihan (ada kembalian);
    // yang dicatat hanya sebesar sisa tagihan.
    final dicatat = _nilai > sisa ? sisa : _nilai;
    final err = _s.catatPembayaran(widget.idPesanan, _metode, dicatat);
    if (err != null) {
      snack(context, err);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = _s.pesananById(widget.idPesanan)!;
    final pel = _s.pelangganById(p.idPelanggan);
    final cabang = _s.cabangById(p.idCabang);
    final sisa = _s.sisaTagihan(p);
    final kembali = _nilai - sisa;
    final bisa = sisa > 0 && _nilai > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.noPesanan,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        BayarChip(p.statusBayar),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        '${pel?.nama ?? '-'}'
                        '${pel == null ? '' : '  |  ${pel.noWhatsapp}'}',
                        style: const TextStyle(color: Colors.grey)),
                    Text(cabang?.nama ?? '-',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Panel(
                child: Column(
                  children: [
                    const Text('Sisa tagihan',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(rupiah(sisa),
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                        'Total ${rupiah(p.totalBiaya)}  |  dibayar ${rupiah(_s.totalDibayar(p.id))}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Pil('Tunai',
                        lebar: true,
                        ikon: Icons.payments_outlined,
                        aktif: _metode == MetodeBayar.tunai,
                        onTap: () =>
                            setState(() => _metode = MetodeBayar.tunai)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Pil('QRIS',
                        lebar: true,
                        ikon: Icons.qr_code_2,
                        aktif: _metode == MetodeBayar.qris,
                        onTap: () =>
                            setState(() => _metode = MetodeBayar.qris)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_metode == MetodeBayar.qris) _qris(),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Uang diterima',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const Text('Nominal rupiah',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _diterima,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixText: 'Rp  ',
                        filled: true,
                        fillColor: kAbu,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final v in _preset(sisa))
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(
                                    () => _diterima.text = '$v'),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _nilai == v ? kHitam : kAbu,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(v == sisa ? 'UANG PAS' : 'PRESET',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: _nilai == v
                                                  ? Colors.white70
                                                  : Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text(rupiah(v).replaceFirst('Rp', ''),
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _nilai == v
                                                  ? Colors.white
                                                  : kHitam)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LabelKecil('Kalkulasi otomatis'),
                    const SizedBox(height: 8),
                    BarisKV('Total tagihan', rupiah(sisa)),
                    BarisKV('Uang diterima', rupiah(_nilai)),
                    const Divider(height: 20),
                    if (kembali >= 0)
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Kembalian',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Text(rupiah(kembali),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 20)),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Masih kurang',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Text(rupiah(-kembali),
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20)),
                        ],
                      ),
                    if (kembali < 0 && _nilai > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                            'Dicatat sebagai cicilan. Order lunas setelah sisa dibayar.',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: bisa ? () => _konfirmasi(sisa) : null,
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Konfirmasi pembayaran diterima'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _metode == MetodeBayar.qris
                      ? 'Pastikan dana QRIS sudah masuk. QRIS belum diverifikasi otomatis.'
                      : 'Jika lunas, status otomatis menjadi Lunas dan nota ditampilkan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qris() {
    final path = _s.qrisPath;
    if (path == null) {
      return const Panel(
        child: Text(
            'QRIS toko belum diunggah. Owner dapat mengunggahnya di menu '
            'Kelola > Pengaturan.'),
      );
    }
    return Panel(
      child: gambarDariPath(path,
          height: 300,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Text('Gambar QRIS tidak dapat dibuka. Unggah ulang.')),
    );
  }
}
