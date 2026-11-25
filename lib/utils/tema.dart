import 'package:flutter/material.dart';

const kHitam = Color(0xFF111111);
const kLatar = Color(0xFFF5F5F5);
const kGaris = Color(0xFFE6E6E6);
const kAbu = Color(0xFFF1F1F1);

/// Kartu putih bersudut bulat (pembungkus bagian layar).
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Panel(
      {super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGaris),
        ),
        child: child,
      );
}

/// Label kecil huruf besar abu-abu, dipakai sebagai judul bagian.
class LabelKecil extends StatelessWidget {
  final String teks;
  const LabelKecil(this.teks, {super.key});
  @override
  Widget build(BuildContext context) => Text(
        teks.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5),
      );
}

/// Kotak abu berisi label kecil dan nilai tebal.
class KotakInfo extends StatelessWidget {
  final String label;
  final String nilai;
  const KotakInfo(this.label, this.nilai, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kAbu,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 2),
            Text(nilai,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}

/// Baris label di kiri dan nilai di kanan.
class BarisKV extends StatelessWidget {
  final String k;
  final String v;
  final bool tebal;
  const BarisKV(this.k, this.v, {super.key, this.tebal = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(k,
                  style: TextStyle(
                      color: tebal ? null : Colors.grey,
                      fontWeight: tebal ? FontWeight.bold : FontWeight.normal)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontWeight: tebal ? FontWeight.bold : FontWeight.w600,
                      fontSize: tebal ? 16 : null)),
            ),
          ],
        ),
      );
}

/// Tombol pil hitam/putih untuk filter dan pilihan metode.
class Pil extends StatelessWidget {
  final String teks;
  final bool aktif;
  final VoidCallback? onTap;
  final IconData? ikon;
  const Pil(this.teks,
      {super.key, required this.aktif, this.onTap, this.ikon});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: aktif ? kHitam : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: aktif ? kHitam : kGaris),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ikon != null) ...[
                Icon(ikon, size: 16, color: aktif ? Colors.white : kHitam),
                const SizedBox(width: 6),
              ],
              Text(teks,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: aktif ? Colors.white : kHitam)),
            ],
          ),
        ),
      );
}
