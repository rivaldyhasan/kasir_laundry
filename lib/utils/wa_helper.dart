import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import 'format.dart';
import 'widgets.dart';

/// Buka WhatsApp dengan pesan terisi untuk satu order, lalu catat riwayatnya.
Future<void> kirimWaOrder(
    BuildContext context, Pesanan p, JenisPesan jenis) async {
  final s = AppStore.instance;
  final pel = s.pelangganById(p.idPelanggan);
  if (pel == null || !waValid(pel.noWhatsapp)) {
    snack(context,
        'Nomor WhatsApp pelanggan tidak valid. Perbaiki data pelanggan dulu.');
    return;
  }
  final pesan = s.pesanWa(p, jenis);
  final ok = await bukaWhatsApp(pel.noWhatsapp, pesan);
  if (ok) {
    s.catatNotifikasi(p.id, jenis, pesan);
  } else if (context.mounted) {
    snack(context, 'WhatsApp tidak bisa dibuka');
  }
}
