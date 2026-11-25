import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/widgets.dart';

/// KF-03 Kelola data pelanggan (nama, nomor WhatsApp, status member).
class PelangganScreen extends StatefulWidget {
  const PelangganScreen({super.key});
  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  final _s = AppStore.instance;
  String _q = '';

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final daftar = _s.pelanggan
            .where((p) =>
                p.nama.toLowerCase().contains(q) || p.noWhatsapp.contains(q))
            .toList()
          ..sort((a, b) => a.nama.compareTo(b.nama));
        return Scaffold(
          appBar: AppBar(title: const Text('Data Pelanggan')),
          floatingActionButton: FloatingActionButton(
              onPressed: () => _form(), child: const Icon(Icons.person_add)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: const InputDecoration(
                      hintText: 'Cari nama / nomor WA',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder()),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: daftar.length,
                  itemBuilder: (_, i) {
                    final p = daftar[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(p.nama),
                      subtitle: Text(p.noWhatsapp),
                      trailing: p.statusMember
                          ? const LabelChip('Member', Colors.amber)
                          : null,
                      onTap: () => _form(p),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
