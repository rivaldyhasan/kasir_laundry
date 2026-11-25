import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
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

/// B.5–B.7 Form Order Baru (UC-03 Input Order, UC-14 Antar Jemput).
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});
  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _s = AppStore.instance;
  final _formKey = GlobalKey<FormState>();

  // pelanggan
  bool _pelangganBaru = false;
  Pelanggan? _pelanggan;
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
  }

  @override
  void dispose() {
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
  int get _total => _sepatu.fold<int>(0, (a, x) => a + _subtotal(x)) + _biayaAntarJemput;
  DateTime get _estimasi => _estimasiManual ?? _s.hitungEstimasi(_drafts());

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

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    // pelanggan
    int idPelanggan;
    if (_pelangganBaru) {
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

    // sepatu
    for (var i = 0; i < _sepatu.length; i++) {
      final x = _sepatu[i];
      if (x.bahan == null || x.kecepatan == null) {
        snack(context, 'Sepatu ${i + 1}: pilih jenis bahan dan paket layanan.');
        return;
      }
      if (kFotoWajib && x.foto == null) {
        snack(context, 'Sepatu ${i + 1}: foto kondisi sebelum dicuci wajib diisi.');
        return;
      }
    }

    if (_pelangganBaru) {
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
      aj: _aj ? AntarJemputDraft(_alamat.text.trim(), _jemput, _biayaAntarJemput) : null,
    );
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(idPesanan: p.id)));
  }

  // ------------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Order')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12)),
                    Text(rupiah(_total),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _simpan,
                icon: const Icon(Icons.save),
                label: const Text('Simpan Order'),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (_s.isOwner) ...[
              const Judul('Cabang'),
              DropdownButtonFormField<int>(
                initialValue: _idCabang,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _s.cabang
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama)))
                    .toList(),
                onChanged: (v) => setState(() => _idCabang = v ?? _idCabang),
              ),
            ],
            const Judul('Pelanggan'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pelanggan baru'),
              value: _pelangganBaru,
              onChanged: (v) => setState(() => _pelangganBaru = v),
            ),
            if (_pelangganBaru) ...[
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nama pelanggan', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _wa,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp',
                    hintText: '08123456789',
                    border: OutlineInputBorder()),
                validator: (v) => (v == null || !waValid(v))
                    ? 'Nomor WhatsApp tidak valid'
                    : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Member (garansi kerusakan)'),
                value: _member,
                onChanged: (v) => setState(() => _member = v ?? false),
              ),
            ] else
              Autocomplete<Pelanggan>(
                displayStringForOption: (p) => '${p.nama} (${p.noWhatsapp})',
                optionsBuilder: (t) {
                  final q = t.text.trim().toLowerCase();
                  if (q.isEmpty) return _s.pelanggan;
                  return _s.pelanggan.where((p) =>
                      p.nama.toLowerCase().contains(q) ||
                      p.noWhatsapp.contains(q));
                },
                onSelected: (p) => setState(() => _pelanggan = p),
                fieldViewBuilder: (context, ctrl, focus, _) => TextField(
                  controller: ctrl,
                  focusNode: focus,
                  onChanged: (_) {
                    if (_pelanggan != null) setState(() => _pelanggan = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Cari pelanggan (nama / nomor WA)',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    helperText: _pelanggan == null
                        ? 'Ketik lalu pilih dari daftar'
                        : 'Dipilih: ${_pelanggan!.nama}'
                            '${_pelanggan!.statusMember ? ' (member)' : ''}',
                  ),
                ),
              ),
            const Judul('Sepatu dan layanan'),
            for (var i = 0; i < _sepatu.length; i++) _kartuSepatu(i),
            OutlinedButton.icon(
              onPressed: () => setState(() => _sepatu.add(_ShoeForm())),
              icon: const Icon(Icons.add),
              label: const Text('Tambah sepatu'),
            ),
            const Judul('Estimasi selesai'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(tgl(_estimasi)),
              subtitle: Text(_estimasiManual == null
                  ? 'Otomatis (Deep Clean 3 hari, Fast Clean 1 hari)'
                  : 'Diatur manual'),
              trailing: TextButton(
                  onPressed: _pilihEstimasi, child: const Text('Ubah')),
            ),
            const Judul('Antar-jemput'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pelanggan meminta antar-jemput'),
              value: _aj,
              onChanged: (v) => setState(() => _aj = v),
            ),
            if (_aj) ...[
              TextFormField(
                controller: _alamat,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Alamat jemput / antar',
                    border: OutlineInputBorder()),
                validator: (v) => (_aj && (v == null || v.trim().isEmpty))
                    ? 'Alamat wajib diisi'
                    : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text('Jadwal jemput: ${tglJam(_jemput)}'),
                trailing: TextButton(
                    onPressed: _pilihJemput, child: const Text('Ubah')),
              ),
              TextFormField(
                controller: _biayaAj,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'Biaya antar-jemput (Rp)',
                    helperText: 'Tarif belum ditetapkan di proposal, isi sesuai kesepakatan',
                    border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _kartuSepatu(int i) {
    final x = _sepatu[i];
    final kecepatanList =
        x.bahan == null ? <Kecepatan>[] : _s.kecepatanTersedia(x.bahan!);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Sepatu ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                if (_sepatu.length > 1)
                  IconButton(
                    tooltip: 'Hapus sepatu',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() {
                      _sepatu.removeAt(i).dispose();
                    }),
                  ),
              ],
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('bahan-$i-${_sepatu.length}'),
              initialValue: x.bahan,
              decoration: const InputDecoration(
                  labelText: 'Jenis bahan', border: OutlineInputBorder()),
              items: _s.daftarBahan
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() {
                x.bahan = v;
                x.kecepatan = null; // paket harus dipilih ulang
              }),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Kecepatan>(
              key: ValueKey('paket-$i-${x.bahan}-${_sepatu.length}'),
              initialValue: x.kecepatan,
              decoration: const InputDecoration(
                  labelText: 'Paket layanan', border: OutlineInputBorder()),
              items: kecepatanList.map((k) {
                final h = _s.layananUtama(x.bahan, k)?.harga ?? 0;
                return DropdownMenuItem(
                    value: k,
                    child: Text('${k.label} (${k.durasi}) • ${rupiah(h)}'));
              }).toList(),
              onChanged: x.bahan == null
                  ? null
                  : (v) => setState(() => x.kecepatan = v),
            ),
            const SizedBox(height: 10),
            const Text('Layanan tambahan', style: TextStyle(fontSize: 12)),
            Wrap(
              spacing: 6,
              children: _s.layananTambahan.map((l) {
                final pilih = x.tambahanDipilih.contains(l.id);
                return FilterChip(
                  label: Text(l.nama),
                  selected: pilih,
                  onSelected: (v) => setState(() {
                    if (v) {
                      x.tambahanDipilih.add(l.id);
                      x.hargaTambahan[l.id] =
                          TextEditingController(text: '${l.harga}');
                    } else {
                      x.tambahanDipilih.remove(l.id);
                      x.hargaTambahan.remove(l.id)?.dispose();
                    }
                  }),
                );
              }).toList(),
            ),
            for (final id in x.tambahanDipilih)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: x.hargaTambahan[id],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                      labelText: 'Harga ${_s.layananById(id)?.nama ?? ''} (Rp)',
                      isDense: true,
                      border: const OutlineInputBorder()),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: x.merek,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Merek sepatu', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: x.catatan,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Catatan kondisi (noda, lem rapuh, dll.)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FotoKotak(x.foto, ukuran: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ambilFoto(x),
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(x.foto == null
                        ? 'Foto kondisi sebelum dicuci'
                        : 'Ganti foto'),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Subtotal: ${rupiah(_subtotal(x))}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
