import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/tema.dart';
import '../utils/widgets.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';

enum _Saring { semua, member, reguler }

/// KF-03 Kelola data pelanggan (nama, nomor WhatsApp, status member).
class PelangganScreen extends StatefulWidget {
  const PelangganScreen({super.key});
  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  final _s = AppStore.instance;
  String _q = '';
  _Saring _saring = _Saring.semua;
  final Set<int> _buka = {};

  Future<void> _form([Pelanggan? p]) async {
    final nama = TextEditingController(text: p?.nama ?? '');
    final wa = TextEditingController(text: p?.noWhatsapp ?? '');
    var member = p?.statusMember ?? false;
    final kunci = GlobalKey<FormState>();
    final simpan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(p == null ? 'Pelanggan baru' : 'Ubah pelanggan'),
          content: Form(
            key: kunci,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nama,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                TextFormField(
                  controller: wa,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor WhatsApp'),
                  validator: (v) {
                    if (v == null || !waValid(v)) return 'Nomor tidak valid';
                    final ada = _s.cariPelangganByWa(v);
                    if (ada != null && ada.id != p?.id) {
                      return 'Sudah dipakai ${ada.nama}';
                    }
                    return null;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Member'),
                  value: member,
                  onChanged: (v) => setD(() => member = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () {
                  if (kunci.currentState!.validate()) Navigator.pop(ctx, true);
                },
                child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (simpan == true) {
      if (p == null) {
        _s.tambahPelanggan(nama.text, wa.text, member: member);
      } else {
        p.nama = nama.text.trim();
        p.noWhatsapp = wa.text.trim();
        p.statusMember = member;
        _s.simpanPelanggan();
      }
    }
    nama.dispose();
    wa.dispose();
  }

  List<Pesanan> _riwayat(Pelanggan p) {
    final ids = _s.idCabangTerlihat;
    final l = _s.pesanan
        .where((o) => o.idPelanggan == p.id && ids.contains(o.idCabang))
        .toList()
      ..sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));
    return l;
  }

  static String _inisial(String nama) {
    final kata =
        nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (kata.isEmpty) return '?';
    if (kata.length == 1) return kata.first[0].toUpperCase();
    return (kata.first[0] + kata[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final semua = _s.pelanggan;
        final jumlahMember = semua.where((p) => p.statusMember).length;
        final daftar = semua.where((p) {
          if (_saring == _Saring.member && !p.statusMember) return false;
          if (_saring == _Saring.reguler && p.statusMember) return false;
          return p.nama.toLowerCase().contains(q) || p.noWhatsapp.contains(q);
        }).toList()
          ..sort((a, b) => a.nama.compareTo(b.nama));

        return Scaffold(
          appBar: AppBar(title: const Text('Pelanggan')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Total ${semua.length} pelanggan terdaftar',
                              style: const TextStyle(color: Colors.grey)),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40)),
                          onPressed: () => _form(),
                          icon: const Icon(Icons.person_add_alt, size: 18),
                          label: const Text('Tambah'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      onChanged: (v) => setState(() => _q = v),
                      decoration: InputDecoration(
                        hintText: 'Cari nama pelanggan atau nomor WhatsApp',
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
                          child: Pil('Semua ${semua.length}',
                              aktif: _saring == _Saring.semua,
                              onTap: () =>
                                  setState(() => _saring = _Saring.semua)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Pil('Member aktif $jumlahMember',
                              aktif: _saring == _Saring.member,
                              onTap: () =>
                                  setState(() => _saring = _Saring.member)),
                        ),
                        Pil('Reguler ${semua.length - jumlahMember}',
                            aktif: _saring == _Saring.reguler,
                            onTap: () =>
                                setState(() => _saring = _Saring.reguler)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: daftar.isEmpty
                        ? const Center(
                            child: Text('Pelanggan tidak ditemukan',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

  Widget _kartu(Pelanggan p) {
    final riwayat = _riwayat(p);
    final terbuka = _buka.contains(p.id);
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (!_buka.remove(p.id)) _buka.add(p.id);
            }),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kHitam,
                  child: Text(_inisial(p.nama),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(p.nama,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          if (p.statusMember) ...[
                            const SizedBox(width: 6),
                            const LabelChip('Member', Colors.amber),
                          ],
                        ],
                      ),
                      Text(p.noWhatsapp,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12.5)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Aktivitas',
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                    Text('${riwayat.length} pesanan',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ],
                ),
                Icon(terbuka ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey),
              ],
            ),
          ),
          if (terbuka) ...[
            const Divider(height: 22),
            const LabelKecil('Riwayat transaksi'),
            const SizedBox(height: 6),
            if (riwayat.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Belum ada transaksi.',
                    style: TextStyle(color: Colors.grey, fontSize: 12.5)),
              ),
            for (final o in riwayat.take(3))
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(idPesanan: o.id))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.noPesanan,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(tgl(o.tanggalMasuk),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11.5)),
                          ],
                        ),
                      ),
                      StatusChip(o.status),
                      const SizedBox(width: 8),
                      Text(rupiah(o.totalBiaya),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            if (riwayat.length > 3)
              Text('${riwayat.length - 3} transaksi lainnya di tab Pesanan.',
                  style: const TextStyle(color: Colors.grey, fontSize: 11.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: kHitam,
                      side: const BorderSide(color: kGaris),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _form(p),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Ubah data'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => OrderFormScreen(pelangganAwal: p))),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Order baru'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
