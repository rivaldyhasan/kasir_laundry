import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

String rupiah(num v) => 'Rp${NumberFormat('#,##0', 'id_ID').format(v)}';
String tgl(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
String tglJam(DateTime d) => DateFormat('d MMM yyyy HH:mm', 'id_ID').format(d);

/// Ubah 08xx / 8xx / +62 8xx menjadi 628xx (format wa.me).
String normalisasiWa(String raw) {
  var n = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (n.startsWith('0')) {
    n = '62${n.substring(1)}';
  } else if (n.startsWith('8')) {
    n = '62$n';
  }
  return n;
}

bool waValid(String raw) {
  final n = normalisasiWa(raw);
  return n.startsWith('62') && n.length >= 10 && n.length <= 15;
}

/// Click-to-chat WhatsApp dengan pesan terisi (tanpa API berbayar,
/// sesuai mitigasi risiko no. 6 pada proposal).
Future<bool> bukaWhatsApp(String noWa, String pesan) async {
  final uri = Uri.parse(
      'https://wa.me/${normalisasiWa(noWa)}?text=${Uri.encodeComponent(pesan)}');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

String csvSel(Object? v) {
  final s = '${v ?? ''}';
  if (s.contains(';') || s.contains('"') || s.contains('\n')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}
