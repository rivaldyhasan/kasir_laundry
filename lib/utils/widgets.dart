import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/models.dart';

Color warnaStatus(StatusPesanan s) => switch (s) {
      StatusPesanan.diterima => Colors.blueGrey,
      StatusPesanan.diproses => Colors.orange,
      StatusPesanan.selesai => Colors.green,
      StatusPesanan.diambil => Colors.grey,
    };

class LabelChip extends StatelessWidget {
  final String teks;
  final Color warna;
  const LabelChip(this.teks, this.warna, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(teks,
            style: TextStyle(
                color: warna, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class StatusChip extends StatelessWidget {
  final StatusPesanan status;
  const StatusChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) =>
      LabelChip(status.label, warnaStatus(status));
}

class BayarChip extends StatelessWidget {
  final StatusBayar status;
  const BayarChip(this.status, {super.key});
  @override
  Widget build(BuildContext context) => status == StatusBayar.lunas
      ? const LabelChip('Lunas', Colors.green)
      : const LabelChip('Belum lunas', Colors.red);
}

class Judul extends StatelessWidget {
  final String teks;
  const Judul(this.teks, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(teks,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}

class FotoKotak extends StatelessWidget {
  final String? path;
  final double ukuran;
  const FotoKotak(this.path, {super.key, this.ukuran = 64});
  @override
  Widget build(BuildContext context) {
    final kosong = Container(
      width: ukuran,
      height: ukuran,
      color: Colors.black12,
      child: const Icon(Icons.image_not_supported_outlined),
    );
    if (path == null) return ClipRRect(borderRadius: BorderRadius.circular(8), child: kosong);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: gambarDariPath(path!,
          width: ukuran,
          height: ukuran,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => kosong),
    );
  }
}

void snack(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan)));
}

/// Tampilkan gambar dari path. Di web, path dari image_picker berupa URL
/// blob sehingga memakai Image.network; di Android/Windows memakai berkas.
Widget gambarDariPath(
  String path, {
  double? width,
  double? height,
  BoxFit? fit,
  ImageErrorWidgetBuilder? errorBuilder,
}) =>
    kIsWeb
        ? Image.network(path,
            width: width, height: height, fit: fit, errorBuilder: errorBuilder)
        : Image.file(File(path),
            width: width, height: height, fit: fit, errorBuilder: errorBuilder);
