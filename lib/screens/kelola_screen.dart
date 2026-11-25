import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/widgets.dart';

/// KF-02 (cabang dan pengguna), KF-04 (layanan dan harga), KF-11 (QRIS toko).
/// Hanya Owner. Sesuai B.13 Manajemen Pengguna dan Hak Akses.
class KelolaScreen extends StatelessWidget {
  const KelolaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kelola'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Layanan'),
              Tab(text: 'Cabang'),
              Tab(text: 'Pengguna'),
              Tab(text: 'Pengaturan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_TabLayanan(), _TabCabang(), _TabPengguna(), _TabPengaturan()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Layanan
class _TabLayanan extends StatelessWidget {
  const _TabLayanan();

  Future<void> _form(BuildContext context, [Layanan? l]) async {
    final s = AppStore.instance;
    var jenis = l?.jenis ?? JenisLayanan.utama;
    var kec = l?.kecepatan ?? Kecepatan.deep;
    final nama = TextEditingController(text: l?.nama ?? '');
    final bahan = TextEditingController(text: l?.tipeBahan ?? '');
    final harga = TextEditingController(text: l == null ? '' : '${l.harga}');
    final kunci = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(l == null ? 'Layanan baru' : 'Ubah layanan'),
          content: SingleChildScrollView(
            child: Form(
              key: kunci,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<JenisLayanan>(
                    initialValue: jenis,
                    decoration: const InputDecoration(labelText: 'Jenis'),
                    items: const [
                      DropdownMenuItem(
                          value: JenisLayanan.utama, child: Text('Utama')),
                      DropdownMenuItem(
                          value: JenisLayanan.tambahan, child: Text('Tambahan')),
                    ],
                    onChanged: (v) => setD(() => jenis = v ?? jenis),
                  ),
                  if (jenis == JenisLayanan.utama) ...[
                    TextFormField(
                      controller: bahan,
                      decoration: const InputDecoration(labelText: 'Jenis bahan'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    DropdownButtonFormField<Kecepatan>(
                      initialValue: kec,
                      decoration: const InputDecoration(labelText: 'Paket'),
                      items: Kecepatan.values
                          .map((k) =>
                              DropdownMenuItem(value: k, child: Text(k.label)))
                          .toList(),
                      onChanged: (v) => setD(() => kec = v ?? kec),
                    ),
                  ] else
                    TextFormField(
                      controller: nama,
                      decoration: const InputDecoration(labelText: 'Nama layanan'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                  TextFormField(
                    controller: harga,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Harga tidak valid' : null,
                  ),
                ],
              ),
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

    if (ok == true) {
      final h = int.parse(harga.text);
      final target = l ??
          Layanan(id: 0, nama: '', jenis: jenis, harga: h);
      target.jenis = jenis;
      target.harga = h;
      if (jenis == JenisLayanan.utama) {
        target.tipeBahan = bahan.text.trim();
        target.kecepatan = kec;
        target.nama = kec.label;
      } else {
        target.tipeBahan = null;
        target.kecepatan = null;
        target.nama = nama.text.trim();
      }
      s.simpanLayanan(target);
    }
    nama.dispose();
    bahan.dispose();
    harga.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final utama = s.layanan.where((e) => e.jenis == JenisLayanan.utama).toList();
        final tambahan = s.layananTambahan;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            FilledButton.icon(
                onPressed: () => _form(context),
                icon: const Icon(Icons.add),
                label: const Text('Tambah layanan')),
            const Judul('Layanan utama (harga per bahan dan paket)'),
            for (final l in utama)
              ListTile(
                dense: true,
                title: Text('${l.tipeBahan} • ${l.nama}'),
                trailing: Text(rupiah(l.harga),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _form(context, l),
              ),
            const Judul('Layanan tambahan'),
            for (final l in tambahan)
              ListTile(
                dense: true,
                title: Text(l.nama),
                trailing: Text(rupiah(l.harga),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _form(context, l),
              ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------------- Cabang
class _TabCabang extends StatelessWidget {
  const _TabCabang();

  Future<void> _form(BuildContext context, [Cabang? c]) async {
    final nama = TextEditingController(text: c?.nama ?? '');
    final kode = TextEditingController(text: c?.kode ?? '');
    final alamat = TextEditingController(text: c?.alamat ?? '');
    final wa = TextEditingController(text: c?.noWhatsapp ?? '');
    final kunci = GlobalKey<FormState>();
    final s = AppStore.instance;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c == null ? 'Cabang baru' : 'Ubah cabang'),
        content: SingleChildScrollView(
          child: Form(
            key: kunci,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nama,
                  decoration: const InputDecoration(labelText: 'Nama cabang'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: kode,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 4,
                  decoration: const InputDecoration(
                      labelText: 'Kode (untuk nomor order)'),
                  validator: (v) {
                    final x = (v ?? '').trim().toUpperCase();
                    if (x.length < 2) return 'Minimal 2 huruf';
                    final dobel = s.cabang.any((e) => e.kode == x && e.id != c?.id);
                    return dobel ? 'Kode sudah dipakai' : null;
                  },
                ),
                TextFormField(
                  controller: alamat,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                ),
                TextFormField(
                  controller: wa,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(labelText: 'Nomor WhatsApp cabang'),
                ),
              ],
            ),
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
    );

    if (ok == true) {
      final target = c ?? Cabang(id: 0, kode: '', nama: '');
      target.nama = nama.text.trim();
      target.kode = kode.text.trim().toUpperCase();
      target.alamat = alamat.text.trim();
      target.noWhatsapp = wa.text.trim();
      s.simpanCabang(target);
    }
    nama.dispose();
    kode.dispose();
    alamat.dispose();
    wa.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FilledButton.icon(
              onPressed: () => _form(context),
              icon: const Icon(Icons.add_business),
              label: const Text('Tambah cabang')),
          const SizedBox(height: 8),
          for (final c in s.cabang)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(c.kode)),
                title: Text(c.nama),
                subtitle: Text(c.alamat),
                onTap: () => _form(context, c),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Pengguna
class _TabPengguna extends StatelessWidget {
  const _TabPengguna();

  Future<void> _form(BuildContext context) async {
    final s = AppStore.instance;
    final nama = TextEditingController();
    final user = TextEditingController();
    final pass = TextEditingController();
    var cabang = s.cabang.first.id;
    var role = Role.kasir;
    final kunci = GlobalKey<FormState>();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Pengguna baru'),
          content: SingleChildScrollView(
            child: Form(
              key: kunci,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nama,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                  ),
                  TextFormField(
                    controller: user,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => (v == null || v.trim().length < 3)
                        ? 'Minimal 3 karakter'
                        : null,
                  ),
                  TextFormField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: cabang,
                    decoration: const InputDecoration(labelText: 'Cabang'),
                    items: s.cabang
                        .map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.nama)))
                        .toList(),
                    onChanged: (v) => setD(() => cabang = v ?? cabang),
                  ),
                  DropdownButtonFormField<Role>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Hak akses'),
                    items: Role.values
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) => setD(() => role = v ?? role),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
                onPressed: () {
                  if (!kunci.currentState!.validate()) return;
                  final err = s.tambahPengguna(
                      nama.text, user.text, pass.text, cabang, role);
                  if (err != null) {
                    setD(() => error = err);
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) snack(context, 'Pengguna ditambahkan.');
    nama.dispose();
    user.dispose();
    pass.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FilledButton.icon(
              onPressed: () => _form(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Tambah pengguna')),
          const SizedBox(height: 8),
          for (final p in s.pengguna)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                    child: Icon(p.role == Role.owner
                        ? Icons.admin_panel_settings
                        : Icons.point_of_sale)),
                title: Text(p.nama),
                subtitle: Text(
                    '@${p.username} • ${p.role.label} • ${s.cabangById(p.idCabang)?.nama ?? '-'}'),
                trailing: IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final yakin = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hapus pengguna?'),
                        content: Text('Akun ${p.username} akan dihapus.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal')),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Hapus')),
                        ],
                      ),
                    );
                    if (yakin != true) return;
                    final err = s.hapusPengguna(p.id);
                    if (err != null && context.mounted) snack(context, err);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ Pengaturan
class _TabPengaturan extends StatelessWidget {
  const _TabPengaturan();

  Future<void> _pilihQris(BuildContext context) async {
    final s = AppStore.instance;
    try {
      final f = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (f == null) return;
      s.setQris(await s.simpanFoto(f.path));
    } catch (e) {
      if (context.mounted) snack(context, 'Gagal memilih gambar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStore.instance;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Judul('QRIS toko (ditampilkan pada layar pembayaran)'),
          if (s.qrisPath != null)
            gambarDariPath(s.qrisPath!,
                height: 240,
                errorBuilder: (_, _, _) =>
                    const Text('Gambar tidak dapat dibuka.'))
          else
            const Text('Belum ada gambar QRIS.'),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.icon(
                  onPressed: () => _pilihQris(context),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(s.qrisPath == null ? 'Unggah QRIS' : 'Ganti QRIS')),
              const SizedBox(width: 8),
              if (s.qrisPath != null)
                TextButton(
                    onPressed: () => s.setQris(null), child: const Text('Hapus')),
            ],
          ),
          const Judul('Data uji coba'),
          OutlinedButton.icon(
            onPressed: () async {
              final yakin = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset semua data?'),
                  content: const Text(
                      'Semua order, pelanggan, dan pengaturan dikembalikan ke data awal. Anda akan keluar dari akun.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset')),
                  ],
                ),
              );
              if (yakin != true || !context.mounted) return;
              Navigator.popUntil(context, (r) => r.isFirst);
              await s.resetKeSeed();
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset ke data awal'),
          ),
        ],
      ),
    );
  }
}
