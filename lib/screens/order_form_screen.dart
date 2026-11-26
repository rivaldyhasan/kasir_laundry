import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/widgets.dart';
import 'order_detail_screen.dart';

/// Foto kondisi sebelum dicuci wajib (KF-06). Ubah ke false bila ingin opsional.
const kFotoWajib = true;

class _ShoeForm {
  String? bahan;
  Kecepatan? kecepatan;
  final merek = TextEditingController();
  final catatan = TextEditingController();
  String? foto;
  final Set<int> tambahanDipilih = {};
  final Map<int, TextEditingController> hargaTambahan = {};

  void dispose() {
    merek.dispose();
    catatan.dispose();
    for (final c in hargaTambahan.values) {
      c.dispose();
    }
  }
}

/// S04 Order Baru (stepper): 1 Pelanggan, 2 Layanan, 3 Ringkasan.
/// UC-03 Input Order, UC-14 Antar Jemput.
class OrderFormScreen extends StatefulWidget {
  final Pelanggan? pelangganAwal;
  const OrderFormScreen({super.key, this.pelangganAwal});
  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _s = AppStore.instance;
  final _kunciPel = GlobalKey<FormState>();
  final _kunciAj = GlobalKey<FormState>();
  int _langkah = 0;

  // pelanggan
  bool _pelangganBaru = false;
  Pelanggan? _pelanggan;
  final _cari = TextEditingController();
  final _nama = TextEditingController();
  final _wa = TextEditingController();
  bool _member = false;

  late int _idCabang;
  final List<_ShoeForm> _sepatu = [_ShoeForm()];
  DateTime? _estimasiManual;

  // antar jemput
  bool _aj = false;
  final _alamat = TextEditingController();
  final _biayaAj = TextEditingController();
  DateTime _jemput = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    _idCabang = _s.user!.idCabang;
    _pelanggan = widget.pelangganAwal;
  }

  @override
  void dispose() {
    _cari.dispose();
    _nama.dispose();
    _wa.dispose();
    _alamat.dispose();
    _biayaAj.dispose();
    for (final x in _sepatu) {
      x.dispose();
    }
    super.dispose();
  }

  // ----------------------------------------------------------- perhitungan
  List<ShoeDraft> _drafts() => _sepatu.map((x) {
        final d = ShoeDraft()
          ..bahan = x.bahan
          ..kecepatan = x.kecepatan
          ..merek = x.merek.text
          ..catatan = x.catatan.text
          ..foto = x.foto;
        for (final id in x.tambahanDipilih) {
          d.tambahan[id] = int.tryParse(x.hargaTambahan[id]?.text ?? '') ?? 0;
        }
        return d;
      }).toList();

  int _subtotal(_ShoeForm x) {
    var t = _s.layananUtama(x.bahan, x.kecepatan)?.harga ?? 0;
    for (final id in x.tambahanDipilih) {
      t += int.tryParse(x.hargaTambahan[id]?.text ?? '') ?? 0;
    }
    return t;
  }

  int get _biayaAntarJemput => _aj ? (int.tryParse(_biayaAj.text) ?? 0) : 0;
  int get _totalSepatu => _sepatu.fold<int>(0, (a, x) => a + _subtotal(x));
  int get _total => _totalSepatu + _biayaAntarJemput;
  DateTime get _estimasi => _estimasiManual ?? _s.hitungEstimasi(_drafts());

  String get _namaPelanggan =>
      _pelangganBaru ? _nama.text.trim() : (_pelanggan?.nama ?? '-');
  String get _waPelanggan =>
      _pelangganBaru ? _wa.text.trim() : (_pelanggan?.noWhatsapp ?? '-');
  bool get _adaMember =>
      _pelangganBaru ? _member : (_pelanggan?.statusMember ?? false);

  // ---------------------------------------------------------------- aksi
  Future<void> _ambilFoto(_ShoeForm x) async {
    final sumber = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Kamera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (sumber == null) return;
    try {
      final f = await ImagePicker()
          .pickImage(source: sumber, imageQuality: 70, maxWidth: 1280);
      if (f == null) return;
      final path = await _s.simpanFoto(f.path);
      if (!mounted) return;
      setState(() => x.foto = path);
    } catch (e) {
      if (!mounted) return;
      snack(context, 'Gagal mengambil foto: $e');
    }
  }

  Future<void> _pilihEstimasi() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _estimasi,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null) setState(() => _estimasiManual = d);
  }

  Future<void> _pilihJemput() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _jemput,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_jemput));
    if (t == null) return;
    setState(() => _jemput = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _toggleTambahan(_ShoeForm x, Layanan l, bool pilih) {
    setState(() {
      if (pilih) {
        x.tambahanDipilih.add(l.id);
        x.hargaTambahan[l.id] = TextEditingController(text: '${l.harga}');
      } else {
        x.tambahanDipilih.remove(l.id);
        x.hargaTambahan.remove(l.id)?.dispose();
      }
    });
  }

  void _kembali() {
    if (_langkah == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _langkah--);
    }
  }

  void _lanjut() {
    if (_langkah == 0) {
      if (_pelangganBaru) {
        if (!_kunciPel.currentState!.validate()) return;
        final ada = _s.cariPelangganByWa(_wa.text);
        if (ada != null) {
          snack(context,
              'Nomor sudah terdaftar atas nama ${ada.nama}. Pilih dari daftar pelanggan.');
          return;
        }
      } else if (_pelanggan == null) {
        snack(context, 'Pilih pelanggan terlebih dahulu.');
        return;
      }
    } else if (_langkah == 1) {
      for (var i = 0; i < _sepatu.length; i++) {
        final x = _sepatu[i];
        if (x.bahan == null || x.kecepatan == null) {
          snack(context, 'Sepatu ${i + 1}: pilih jenis bahan dan paket cuci.');
          return;
        }
        if (kFotoWajib && x.foto == null) {
          snack(context,
              'Sepatu ${i + 1}: foto kondisi sebelum dicuci wajib diisi.');
          return;
        }
      }
    }
    setState(() => _langkah++);
  }

  void _simpan() {
    if (_aj && !_kunciAj.currentState!.validate()) return;

    final int idPelanggan;
    if (_pelangganBaru) {
      final ada = _s.cariPelangganByWa(_wa.text);
      if (ada != null) {
        snack(context, 'Nomor sudah terdaftar atas nama ${ada.nama}.');
        return;
      }
      idPelanggan =
          _s.tambahPelanggan(_nama.text, _wa.text, member: _member).id;
    } else {
      idPelanggan = _pelanggan!.id;
    }

    final p = _s.buatPesanan(
      idPelanggan: idPelanggan,
      idCabang: _idCabang,
      sepatu: _drafts(),
      estimasi: _estimasi,
      aj: _aj
          ? AntarJemputDraft(_alamat.text.trim(), _jemput, _biayaAntarJemput)
          : null,
    );
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(idPesanan: p.id)));
  }

  // ------------------------------------------------------------------- UI
  InputDecoration _dekor(String hint, {IconData? ikon, String? prefix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: ikon == null ? null : Icon(ikon, size: 20),
        prefixText: prefix,
        filled: true,
        fillColor: kAbu,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final terakhir = _langkah == 2;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: _kembali),
        title: const Text('Order Baru'),
      ),
      body: Column(
        children: [
          _indikator(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (_langkah == 0) _langkahPelanggan(),
                    if (_langkah == 1) _langkahLayanan(),
                    if (_langkah == 2) _langkahRingkasan(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: kLatar,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_langkah >= 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Expanded(
                          child: Text('Total sementara',
                              style: TextStyle(color: Colors.grey))),
                      Text(rupiah(_total),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                ),
              Row(
                children: [
                  if (_langkah > 0) ...[
                    Expanded(
                      flex: 3,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          foregroundColor: kHitam,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: kGaris),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _kembali,
                        child: const Text('Kembali'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    flex: 7,
                    child: FilledButton(
                      onPressed: terakhir ? _simpan : _lanjut,
                      child: Text(terakhir ? 'Simpan Order' : 'Lanjut  →'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indikator() {
    const label = ['Pelanggan', 'Layanan', 'Ringkasan'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= _langkah ? kHitam : kGaris),
                        ),
                      ),
                      GestureDetector(
                        onTap: i < _langkah
                            ? () => setState(() => _langkah = i)
                            : null,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i <= _langkah ? kHitam : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: i <= _langkah ? kHitam : kGaris,
                                width: 1.5),
                          ),
                          child: i < _langkah
                              ? const Icon(Icons.check,
                                  size: 15, color: Colors.white)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: i <= _langkah
                                          ? Colors.white
                                          : Colors.grey)),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == 2
                              ? Colors.transparent
                              : (i < _langkah ? kHitam : kGaris),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${i + 1}. ${label[i]}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              i == _langkah ? FontWeight.w700 : FontWeight.w500,
                          color: i <= _langkah ? kHitam : Colors.grey)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------ langkah 1: pelanggan
  List<Pelanggan> _hasilCari() {
    final q = _cari.text.trim().toLowerCase();
    final hasil = _s.pelanggan
        .where((p) =>
            q.isEmpty ||
            p.nama.toLowerCase().contains(q) ||
            p.noWhatsapp.contains(q))
        .toList()
      ..sort((a, b) => a.nama.compareTo(b.nama));
    return hasil;
  }

  Widget _langkahPelanggan() {
    final hasil = _hasilCari();
    return Form(
      key: _kunciPel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_s.isOwner)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LabelKecil('Cabang'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _idCabang,
                    decoration: _dekor('Pilih cabang'),
                    items: _s.cabang
                        .map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.nama)))
                        .toList(),
                    onChanged: (v) => setState(() => _idCabang = v ?? _idCabang),
                  ),
                ],
              ),
            ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Pil('Pelanggan terdaftar',
                          lebar: true,
                          aktif: !_pelangganBaru,
                          onTap: () => setState(() => _pelangganBaru = false)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Pil('Pelanggan baru',
                          lebar: true,
                          aktif: _pelangganBaru,
                          onTap: () => setState(() => _pelangganBaru = true)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_pelangganBaru) ...[
                  const LabelKecil('Nama pelanggan'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nama,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dekor('Nama lengkap', ikon: Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const LabelKecil('Nomor WhatsApp'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _wa,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _dekor('08123456789', ikon: Icons.phone_outlined),
                    validator: (v) => (v == null || !waValid(v))
                        ? 'Nomor WhatsApp tidak valid'
                        : null,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Member (garansi kerusakan)'),
                    value: _member,
                    onChanged: (v) => setState(() => _member = v ?? false),
                  ),
                ] else ...[
                  TextField(
                    controller: _cari,
                    onChanged: (_) => setState(() {}),
                    decoration: _dekor('Cari nama atau nomor WhatsApp',
                        ikon: Icons.search),
                  ),
                  const SizedBox(height: 10),
                  if (hasil.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                          'Tidak ditemukan. Pilih "Pelanggan baru" untuk menambah.',
                          style: TextStyle(color: Colors.grey, fontSize: 12.5)),
                    ),
                  for (final p in hasil.take(6)) _tilePelanggan(p),
                  if (hasil.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                          '${hasil.length - 6} pelanggan lain, ketik untuk menyaring.',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tilePelanggan(Pelanggan p) {
    final dipilih = _pelanggan?.id == p.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _pelanggan = p),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: dipilih ? kAbu : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: dipilih ? kHitam : kGaris, width: dipilih ? 1.5 : 1),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: kAbu,
                child: Icon(Icons.person_outline, color: kHitam, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nama,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(p.noWhatsapp,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (p.statusMember) const LabelChip('Member', Colors.amber),
              if (dipilih)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.check_circle, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------- langkah 2: layanan
  Widget _langkahLayanan() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _sepatu.length; i++) _kartuSepatu(i),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              foregroundColor: kHitam,
              backgroundColor: Colors.white,
              side: const BorderSide(color: kGaris),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => setState(() => _sepatu.add(_ShoeForm())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah sepatu'),
          ),
        ],
      );

  Widget _kartuSepatu(int i) {
    final x = _sepatu[i];
    final kecepatanList =
        x.bahan == null ? <Kecepatan>[] : _s.kecepatanTersedia(x.bahan!);
    return Panel(
      key: ObjectKey(x),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Sepatu & layanan #${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              if (_sepatu.length > 1)
                IconButton(
                  tooltip: 'Hapus sepatu',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _sepatu.removeAt(i).dispose()),
                )
              else
                const LabelChip('Wajib diisi', Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 12),
          const LabelKecil('Pilih jenis bahan'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in _s.daftarBahan)
                Pil(b,
                    aktif: x.bahan == b,
                    onTap: () => setState(() {
                          if (x.bahan != b) {
                            x.bahan = b;
                            x.kecepatan = null; // paket harus dipilih ulang
                          }
                        })),
            ],
          ),
          const SizedBox(height: 14),
          const LabelKecil('Pilihan paket cuci'),
          const SizedBox(height: 8),
          if (x.bahan == null)
            const Text('Pilih jenis bahan dulu.',
                style: TextStyle(color: Colors.grey, fontSize: 12.5))
          else
            for (final k in kecepatanList) _kartuPaket(x, k),
          const SizedBox(height: 10),
          const LabelKecil('Layanan tambahan (opsional)'),
          const SizedBox(height: 4),
          for (final l in _s.layananTambahan)
            Row(
              children: [
                Checkbox(
                  value: x.tambahanDipilih.contains(l.id),
                  onChanged: (v) => _toggleTambahan(x, l, v ?? false),
                ),
                Expanded(
                  child: Text(l.nama, style: const TextStyle(fontSize: 13.5)),
                ),
                if (x.tambahanDipilih.contains(l.id))
                  SizedBox(
                    width: 112,
                    child: TextField(
                      controller: x.hargaTambahan[l.id],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: _dekor('0', prefix: 'Rp '),
                    ),
                  )
                else
                  Text('+${rupiah(l.harga)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
              ],
            ),
          const SizedBox(height: 10),
          const LabelKecil('Merek & seri sepatu'),
          const SizedBox(height: 6),
          TextField(
            controller: x.merek,
            textCapitalization: TextCapitalization.words,
            decoration: _dekor('Contoh: Nike Air Jordan 1 High'),
          ),
          const SizedBox(height: 12),
          const LabelKecil('Catatan kondisi khusus'),
          const SizedBox(height: 6),
          TextField(
            controller: x.catatan,
            maxLines: 2,
            decoration: _dekor('Noda, lem rapuh, goresan, dll.'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FotoKotak(x.foto, ukuran: 72),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    foregroundColor: kHitam,
                    side: const BorderSide(color: kGaris),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _ambilFoto(x),
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(x.foto == null
                      ? 'Foto awal masuk (wajib)'
                      : 'Ganti foto'),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Subtotal: ${rupiah(_subtotal(x))}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _kartuPaket(_ShoeForm x, Kecepatan k) {
    final dipilih = x.kecepatan == k;
    final harga = _s.layananUtama(x.bahan, k)?.harga ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => x.kecepatan = k),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dipilih ? kAbu : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: dipilih ? kHitam : kGaris, width: dipilih ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                  dipilih
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Estimasi ${k.durasi}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Text(rupiah(harga),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------ langkah 3: ringkasan
  Widget _langkahRingkasan() {
    final cabang = _s.cabangById(_idCabang);
    return Form(
      key: _kunciAj,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: LabelKecil('Pelanggan')),
                    TextButton(
                      onPressed: () => setState(() => _langkah = 0),
                      child: const Text('Ubah'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(_namaPelanggan,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    if (_adaMember) const LabelChip('Member', Colors.amber),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$_waPelanggan  |  ${cabang?.nama ?? '-'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: LabelKecil('Sepatu & layanan')),
                    TextButton(
                      onPressed: () => setState(() => _langkah = 1),
                      child: const Text('Ubah'),
                    ),
                  ],
                ),
                for (var i = 0; i < _sepatu.length; i++) _barisRingkas(i),
              ],
            ),
          ),
          Panel(
            child: Row(
              children: [
                const Icon(Icons.event_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LabelKecil('Estimasi selesai'),
                      Text(tgl(_estimasi),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          _estimasiManual == null
                              ? 'Otomatis (Deep Clean 3 hari, Fast Clean 1 hari)'
                              : 'Diatur manual',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 11.5)),
                    ],
                  ),
                ),
                TextButton(
                    onPressed: _pilihEstimasi, child: const Text('Ubah')),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Layanan antar-jemput',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Pelanggan meminta kurir jemput/antar'),
                  value: _aj,
                  onChanged: (v) => setState(() => _aj = v),
                ),
                if (_aj) ...[
                  const SizedBox(height: 6),
                  const LabelKecil('Alamat jemput / antar'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _alamat,
                    maxLines: 2,
                    decoration: _dekor('Alamat lengkap'),
                    validator: (v) => (_aj && (v == null || v.trim().isEmpty))
                        ? 'Alamat wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('Jemput: ${tglJam(_jemput)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                      TextButton(
                          onPressed: _pilihJemput, child: const Text('Ubah')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const LabelKecil('Biaya antar-jemput'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _biayaAj,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: _dekor('0', prefix: 'Rp '),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                        'Tarif belum ditetapkan di proposal, isi sesuai kesepakatan.',
                        style: TextStyle(color: Colors.grey, fontSize: 11.5)),
                  ),
                ],
              ],
            ),
          ),
          Panel(
            child: Column(
              children: [
                BarisKV('Layanan sepatu', rupiah(_totalSepatu)),
                if (_aj) BarisKV('Antar-jemput', rupiah(_biayaAntarJemput)),
                const Divider(height: 20),
                BarisKV('Total tagihan', rupiah(_total), tebal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barisRingkas(int i) {
    final x = _sepatu[i];
    final utama = _s.layananUtama(x.bahan, x.kecepatan);
    final tambahan = [
      for (final id in x.tambahanDipilih) _s.layananById(id)?.nama ?? '-'
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FotoKotak(x.foto, ukuran: 48),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    x.merek.text.trim().isEmpty
                        ? 'Sepatu ${i + 1}'
                        : x.merek.text.trim(),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                    [
                      if (utama != null) utama.namaLengkap,
                      if (x.kecepatan != null) x.kecepatan!.label,
                      ...tambahan,
                    ].join('  |  '),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(rupiah(_subtotal(x)),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
