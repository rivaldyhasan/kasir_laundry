import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/models.dart';
import 'format.dart';
import 'tema.dart';
import 'wa_helper.dart';
import 'widgets.dart';

/// S06 Kirim WhatsApp: pratinjau pesan sebelum WhatsApp dibuka.
Future<void> tampilkanSheetWa(BuildContext context, Pesanan p) {
  final s = AppStore.instance;
  final pel = s.pelangganById(p.idPelanggan);
  final cabang = s.cabangById(p.idCabang);
  final valid = pel != null && waValid(pel.noWhatsapp);
  final bisaSelesai = p.status.index >= StatusPesanan.selesai.index;
  var jenis = bisaSelesai ? JenisPesan.selesai : JenisPesan.diterima;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: kLatar,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final pesan = s.pesanWa(p, jenis);
        final riwayat = s.notifikasiOf(p.id);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.chat_bubble_outline, color: kHitam),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kirim WhatsApp',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('Kabari pelanggan lewat WhatsApp',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(pel?.nama ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                          StatusChip(p.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: KotakInfo(
                                'Nomor tujuan',
                                pel == null
                                    ? '-'
                                    : (valid
                                        ? '+${normalisasiWa(pel.noWhatsapp)}'
                                        : '${pel.noWhatsapp} (tidak valid)')),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: KotakInfo(
                                  'Lokasi outlet', cabang?.nama ?? '-')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ID Tiket: ${p.noPesanan}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Pil('Order diterima',
                        aktif: jenis == JenisPesan.diterima,
                        onTap: () =>
                            setS(() => jenis = JenisPesan.diterima)),
                    const SizedBox(width: 8),
                    Pil('Order selesai',
                        aktif: jenis == JenisPesan.selesai,
                        onTap: bisaSelesai
                            ? () => setS(() => jenis = JenisPesan.selesai)
                            : null),
                  ],
                ),
                const SizedBox(height: 12),
                const LabelKecil('Pratinjau pesan'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGaris),
                  ),
                  child: SelectableText(pesan,
                      style: const TextStyle(height: 1.4)),
                ),
                if (!valid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                        'Nomor WhatsApp pelanggan tidak valid. Perbaiki di menu Pelanggan.',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: valid
                      ? () {
                          Navigator.pop(ctx);
                          kirimWaOrder(context, p, jenis);
                        }
                      : null,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Buka WhatsApp'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: kHitam,
                    side: const BorderSide(color: kGaris),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal / kembali ke detail tiket'),
                ),
                if (riwayat.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Terkirim sebelumnya: '
                      '${riwayat.last.jenisPesan == JenisPesan.diterima ? 'Order diterima' : 'Order selesai'}'
                      ' | ${tglJam(riwayat.last.waktuKirim)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
